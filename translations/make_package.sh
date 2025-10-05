#!/usr/bin/bash

set -e

if [ $# -ne 1 ]; then
   echo "Usage: $0 <release tag>"
   exit
fi

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TRANSLATIONS_DIR="$PROJECT_ROOT/translations"
CONFIG_DIR="$TRANSLATIONS_DIR/config"
POT_DIR="$TRANSLATIONS_DIR/pot"
PO_DIR="$TRANSLATIONS_DIR/po"
MO_DIR="$TRANSLATIONS_DIR/mo"
release_tag=$1

cd $PROJECT_ROOT
mkdir -p dist

# Copy Lua script with correct release tag
sed "/darktable-autolevels-module\\/releases\\/download/s|download/v.*/|download/$release_tag/|" autolevels.lua > dist/autolevels.lua

# Update existing README files with correct release tag (onnx url)
# READMEs remain in repo's translation folder because release url's are downloaded, not displayed.
for readme in README.md translations/README_*.md ; do
  if [ `grep -ce "releases/download/${release_tag}" $readme` -ne 1 ]; then
    echo "updated $readme with current release tag"
    sed -i "/darktable-autolevels-module\\/releases\\/download/s|download/v.*/|download/$release_tag/|" $readme
  fi
done

# Prepare locale folder with "translated" README.md file name
languages=`ls translations/po`

for lang in $languages; do
  pofile=translations/po/$lang/autolevels.po
  mofile=translations/mo/$lang/LC_MESSAGES/autolevels.mo
  if ! [ -f $pofile ]; then
    echo "$pofile not found"
    continue
  fi

  # Check "README.md" has been translated to "README_{lang}.md"
  if [ `grep -ce 'msgstr "README_'${lang}'.md"' $pofile` -ne 1 ]; then
    echo "[WARNING] 'README.md' string not properly translated in $pofile -- update it and run again!"
  fi

  # Check README_{lang}.md is there
  if ! [ -f translations/README_$lang.md ]; then
    echo "missing README_$lang.md"
  fi

  # Check and copy mo files
  if [ $pofile -nt $mofile ]; then
    echo "[WARNING] $mofile needs to be updated, run translations/update_translations.sh again!"
  fi
  mkdir -p dist/locale/$lang/LC_MESSAGES
  cp -p $mofile dist/locale/$lang/LC_MESSAGES/
done

cd dist
zip -r autolevels_v1.0.0rc.zip locale autolevels.lua

