#!/bin/bash
# This script extracts strings, updates POT files, and syncs PO files

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TRANSLATIONS_DIR="$PROJECT_ROOT/translations"
CONFIG_DIR="$TRANSLATIONS_DIR/config"
POT_DIR="$TRANSLATIONS_DIR/pot"
PO_DIR="$TRANSLATIONS_DIR/po"
MO_DIR="$TRANSLATIONS_DIR/mo"
echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "PROJECT_ROOT: $PROJECT_ROOT"
echo "TRANSLATIONS_DIR: $TRANSLATIONS_DIR"
echo "CONFIG_DIR: $CONFIG_DIR"
echo "POT_DIR: $POT_DIR"
echo "PO_DIR: $PO_DIR"
echo "MO_DIR: $MO_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."

    local missing_deps=()

    if ! command -v xgettext &> /dev/null; then
        missing_deps+=("gettext")
    fi

    if ! command -v msgmerge &> /dev/null; then
        missing_deps+=("gettext")
    fi

    if ! command -v msgfmt &> /dev/null; then
        missing_deps+=("gettext")
    fi

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_error "Please install: sudo apt-get install gettext jq"
        exit 1
    fi

    log_success "All dependencies found"
}

# Create directory structure
create_directories() {
    log_info "Creating directory structure..."

    mkdir -p "$POT_DIR"
    mkdir -p "$PO_DIR"
    mkdir -p "$MO_DIR"

    # Read languages from config
    if [ -f "$CONFIG_DIR/languages.json" ]; then
        local languages=$(jq -r '.supported_languages[].code' "$CONFIG_DIR/languages.json")
        for language in $languages; do
            # only use the first two letters of the language code
            local lang=${language:0:2}
            mkdir -p "$PO_DIR/$lang"
            mkdir -p "$MO_DIR/$lang/LC_MESSAGES"
        done
    else
        log_warning "languages.json not found, creating default structure"
        for lang in es fr de; do
            mkdir -p "$PO_DIR/$lang"
            mkdir -p "$MO_DIR/$lang/LC_MESSAGES"
        done
    fi

    log_success "Directory structure created"
}

# Check that all locale are installed
check_locale() {
    log_info "Checking locale..."

    local missing_locale=()
    local languages=$(jq -r '.supported_languages[].code' "$CONFIG_DIR/languages.json")

    for language in $languages; do
        if ! locale -a | grep -q "^${language}\.utf8$"; then
            missing_locale+=(${language}.utf8)
        fi
    done

    if [ ${#missing_locale[@]} -ne 0 ]; then
        log_error "Missing locale: ${missing_locale[*]}"
        log_error "Please install: sudo vim /etc/locale.gen && sudo locale-gen"
        exit 1
    fi

    log_success "All locale found"
}

# Extract strings
extract_strings() {
    set -f  # disable globbing during array assignment
    local module=$1
    local source_dirs=($2)
    local file_patterns=($3)
    local keywords=($4)
    set +f  # enable globbing

    log_info "Extracting strings for module: $module"

    local pot_file="$POT_DIR/$module.pot"
    local xgettext_args=(
        "--output=$pot_file"
        "--from-code=UTF-8"
        "--package-name=$module"
        "--package-version=1.0"
    )

    # Add keywords
    for keyword in "${keywords[@]}"; do
        xgettext_args+=("--keyword=$keyword")
    done

    log_info "file_patterns: ${file_patterns[*]}"

    # Find all source files
    local source_files=()
    for source_dir in "${source_dirs[@]}"; do
        if [ -d "$PROJECT_ROOT/$source_dir" ]; then
            for pattern in "${file_patterns[@]}"; do
                for file in "$PROJECT_ROOT/$source_dir"/$pattern; do
                    [ -f "$file" ] && source_files+=("$file")
                done
            done
        else
            log_warning "Source directory not found: $PROJECT_ROOT/$source_dir"
        fi
    done

    if [ ${#source_files[@]} -eq 0 ]; then
        log_warning "No source files found for module $module"
        return
    else
        log_info "Found ${#source_files[@]} source files for module $module"
    fi

    log_info "Calling xgettext ${xgettext_args[*]} [source_files]..."

    # Extract strings
    xgettext "${xgettext_args[@]}" "${source_files[@]}"

    if [ -f "$pot_file" ]; then
        log_success "Extracted strings to $pot_file"
    else
        log_error "Failed to create $pot_file"
    fi
}

# Process all modules
process_modules() {
    log_info "Processing modules..."

    if [ ! -f "$CONFIG_DIR/modules.json" ]; then
        log_error "modules.json not found in $CONFIG_DIR"
        exit 1
    fi

    local modules=$(jq -r '.modules[] | @base64' "$CONFIG_DIR/modules.json")

    for module_data in $modules; do
        local module_info=$(echo "$module_data" | base64 --decode)
        local module=$(echo "$module_info" | jq -r '.name')
        local source_dirs=($(echo "$module_info" | jq -r '.source_dirs[]'))
        local file_patterns=()
        while IFS= read -r pattern; do
            file_patterns+=("$pattern")
        done < <(echo "$module_info" | jq -r '.file_patterns[]')
        local keywords=($(echo "$module_info" | jq -r '.keywords[]'))
        log_info "module: $module"
        log_info "source_dirs: ${source_dirs[*]}"
        log_info "file_patterns: ${file_patterns[*]}"

        extract_strings "$module" "${source_dirs[*]}" "${file_patterns[*]}" "${keywords[*]}"
    done
}

# Update PO files
update_po_files() {
    log_info "Updating PO files..."

    local updated_count=0

    if [ ! -f "$CONFIG_DIR/languages.json" ]; then
        log_error "languages.json not found"
        exit 1
    fi

    local languages=$(jq -r '.supported_languages[].code' "$CONFIG_DIR/languages.json")

    for pot_file in "$POT_DIR"/*.pot; do
        if [ ! -f "$pot_file" ]; then
            continue
        fi

        local module=$(basename "$pot_file" .pot)

        for language in $languages; do
            # only use the first two letters of the language code
            local lang=${language:0:2}
            local po_file="$PO_DIR/$lang/$module.po"

            if [ -f "$po_file" ]; then
                # Update existing PO file
                hash_before=$(sha256sum "$po_file" | awk '{print $1}')
                msgmerge -q --update --backup=off "$po_file" "$pot_file"
                hash_after=$(sha256sum "$po_file" | awk '{print $1}')
                if [ "$hash_before" != "$hash_after" ]; then
                    log_info "Updated $po_file"
                    ((updated_count=updated_count+1))
                fi
            else
                # Create new PO file
                log_info "Creating new $po_file"
                msginit --input="$pot_file" --output-file="$po_file" --locale="${language}.UTF-8" --no-translator
            fi
        done
    done

    log_success "$updated_count PO files updated"
}

# Compile MO files
compile_mo_files() {
    log_info "Compiling MO files..."

    local compiled_count=0

    for po_file in "$PO_DIR"/*/*.po; do
        if [ ! -f "$po_file" ]; then
            continue
        fi

        # Extract language and module from path
        local relative_path=${po_file#$PO_DIR/}
        local lang=$(dirname "$relative_path")
        local module=$(basename "$relative_path" .po)

        local mo_file="$MO_DIR/$lang/LC_MESSAGES/$module.mo"

        # Check if PO file is newer than MO file
        if [ "$po_file" -nt "$mo_file" ] || [ ! -f "$mo_file" ]; then
            log_info "Compiling $po_file → $mo_file"
            if msgfmt --output-file="$mo_file" "$po_file"; then
                ((compiled_count=compiled_count+1))
            else
                echo "msgfmt failed with status $?" >&2
                continue
            fi
        fi
    done

    log_success "Compiled $compiled_count MO files"
}

# Statistics
show_statistics() {
    log_info "Translation Statistics:"

    # Process each language directory
    for lang_dir in "$PO_DIR"/*/; do
        # Extract language from path
        local lang=$(basename "$lang_dir")

        # Process each PO file in the language directory
        for po_file in "$lang_dir"/*.po; do
            [ -f "$po_file" ] || continue

            # Extract module (filename without extension)
            local module=$(basename "$po_file" .po)
            local relative_path="$lang/$module.po"

            # Store with module as primary key for sorting
            printf "%s\t%s\n" "$module:$lang" "$relative_path"
        done
    done | sort | while IFS=$'\t' read -r key relative_path; do
        # Display statistics for each file
        local po_file="$PO_DIR/$relative_path"
        local stats=$(msgfmt --statistics -o /dev/null "$po_file" 2>&1 || true)
        echo "  $relative_path: $stats"
    done
}

# Main function
main() {
    log_info "Starting translation update process..."

    check_dependencies
    create_directories
    check_locale
    process_modules
    update_po_files
    compile_mo_files
    show_statistics

    log_success "Translation update completed!"
    log_info "Run complete_translations.py to auto-translate missing strings"
}

# Handle command line arguments
case "${1:-}" in
    --extract-only)
        check_dependencies
        create_directories
        process_modules
        ;;
    --compile-only)
        check_dependencies
        compile_mo_files
        ;;
    --stats)
        show_statistics
        ;;
    --help)
        echo "Usage: $0 [--extract-only|--compile-only|--stats|--help]"
        echo ""
        echo "Options:"
        echo "  --extract-only  Only extract strings and create POT files"
        echo "  --compile-only  Only compile existing PO files to MO files"
        echo "  --stats         Show translation statistics"
        echo "  --help          Show this help message"
        echo ""
        echo "Default: Run full translation update process"
        ;;
    *)
        main
        ;;
esac
