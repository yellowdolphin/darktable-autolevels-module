--[[
AutoLevels
Calls autolevels to add an "rgb curve" instance with a baseline color correction

AUTHOR
Marius Wanko (marius.wanko@outlook.de)

INSTALLATION
* copy this file in $CONFIGDIR/lua/ where CONFIGDIR is your darktable
  configuration directory
* add the following line in the file $CONFIGDIR/luarc
  require "autolevels"
* pip install autolevels
  (see https://github.com/yellowdolphin/darktable-autolevels-module for instructions)
* download ONNX curve model from 
  https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/v1.0.0/free_xcittiny_wa14.onnx
  or 
  https://retroshine.eu/download/free_xcittiny_wa14.onnx

USAGE
* open the AutoLevels module
* specify your downloaded .onnx file
* select images
* click "add AutoLevels curve"

LICENSE
GPLv3

]]

local dt = require "darktable"
local du = require "lib/dtutils"
local duf = require "lib/dtutils.file"
local dsys = require "lib/dtutils.system"
local gettext = dt.gettext

du.check_min_api_version("9.3.0", autolevels)

-- Module translations in subfolder locale
local path_separator = dt.configuration.running_os == 'windows' and '\\' or '/'
local module_path = debug.getinfo(1, 'S').source:sub(2):match('(.*[/\\])')
local locale_path = module_path .. 'locale' .. path_separator
gettext.bindtextdomain("autolevels", locale_path)

local function _(msgid)
    return gettext.dgettext("autolevels", msgid)
end

-- return data structure for script_manager

local script_data = {}

script_data.metadata = {
  name = "autolevels",
  purpose = _('automatic color correction using AutoLevels'),
  author = "Marius Wanko",
  help = "https://docs.darktable.org/lua/stable/lua.scripts.manual/scripts/contrib/autolevels"
}

local function destroy()
  dt.destroy_event("selection_watcher", "selection-changed")
  dt.destroy_event("save_model_path", "exit")
  dt.gui.libs["autolevels"].visible = false
end

local function restart()
  dt.gui.libs["autolevels"].visible = true
end

script_data.destroy = destroy
script_data.destroy_method = "hide"
script_data.restart = restart
script_data.show = restart

-- end of script_data


local widgets = {}
local lock_status_update = false
local path_separator = package.config:sub(1,1)

local function get_autolevels_outsuffix(filename, sidecar)
  -- Return the unique part of sidecar that deviates from filename
  -- Example: filename='foo.jpg', sidecar='/path/to/foo_01.jpg.xmp' -> '_01.jpg.xmp'
  local sidecar_filename = duf.get_filename(sidecar)
  local basename = duf.get_basename(filename)
  return '"' .. sidecar_filename:sub(#basename + 1, -1) .. '"'  -- remove basename from sidecar_filename
end

local function run_autolevels(path, outsuffix, fn, model)
  local cmd_str = "autolevels --model "..model.." --folder "..path.." --outfolder "..path
    .." --outsuffix "..outsuffix.." --export darktable "..dt.configuration.version.." -- "..fn
  -- dt.print_error("DEBUG cmd_str: "..cmd_str)
  dt.control.execute(cmd_str)
end

local function add_autolevels_curves()
  -- Add an rgbcurve from AutoLevels to each selected image
  
  local images = dt.gui.action_images
  local quoted_model = '"'..widgets.model_chooser_button.value..'"'
  local num_added_curves = 0
  local fallback_used = false
  for __, image in pairs(images) do
    local quoted_fn = '"'..image.filename..'"'
    local quoted_path = '"'..image.path..'"'
    local quoted_outsuffix = get_autolevels_outsuffix(image.filename, image.sidecar)
    run_autolevels(quoted_path, quoted_outsuffix, quoted_fn, quoted_model)

    -- Update the database from the written XMP file
    local success = false
    success, __ = pcall(function()
      image:apply_sidecar(image.sidecar)  -- requires darktable>=5.2, updates db.change_timestamp
    end)
    if not success then
      fallback_used = true  -- fallback for older DT versions
      image.delete(image)  -- needed to update thumbnail on import
      pcall(function() dt.database.import(image.path..path_separator..image.filename) end)  -- crashes dt if not found
    end
    num_added_curves = num_added_curves + 1
  end
  if not fallback_used then
    -- db.write_timestamp needs to be updated, which is compared with mtime on startup
    dt.print_log("writing xmp files...")
    local sele = dt.gui.selection(images)
    dt.gui.action("lib/copy_history/write sidecar files", "", "", 1.000)  -- 0.2 ms / xmp
    if #sele < #images then
      dt.print("Don't change selection during processing!")
      dt.print_log(#sele.."/"..#images.." images are still selected, trying again...")
      sele = dt.gui.selection(images)
      dt.gui.action("lib/copy_history/write sidecar files", "", "", 1.000)  -- 0.2 ms / xmp
    end
    dt.print_log("all xmp files updated")
  end

  lock_status_update = true  --prevent selection-changed hook from overwriting this:
  widgets.status.label = num_added_curves .. _(" curve(s) added")
end

local function save_model_path()
  dt.preferences.write("autolevels", "model_path", "string", widgets.model_chooser_button.value)
end


-- Assign translated messages to avoid segfault (field "1" can't be written for type ...)
local msg_filetype_error = _("ERROR: selected file is not an ONNX file")
local msg_missing_model = _("missing model path")
local msg_calling_autolevels = _("calling autolevels...")


-- Add GUI lib
-- Widget for model_path
widgets.model_path_label = dt.new_widget("section_label"){label = _("add model")}
widgets.model_chooser_button = dt.new_widget("file_chooser_button"){
  title = _("select model file"),
  tooltip = _("select your downloaded .onnx curve model file"),
  is_directory = false,
  changed_callback = function(_)
    local model_path = widgets.model_chooser_button.value
    if not model_path then
      return
    end
    if string.lower(duf.get_filetype(model_path)) ~= "onnx" then
      dt.print(msg_filetype_error)
      dt.print_error(model_path .. " is not an ONNX file")
      -- reset model_path to last valid string or nil
      widgets.model_chooser_button.value = dt.preferences.read("autolevels", "model_path", "string")
      return
    end
    save_model_path()
    update_selection_status()
  end
}
if dt.preferences.read("autolevels", "model_path", "string") then
  widgets.model_chooser_button.value = dt.preferences.read("autolevels", "model_path", "string")
end

-- Button "add AutoLevels curve"
widgets.add_curve_button = dt.new_widget("button"){
  label = _("add AutoLevels curve"),
  tooltip = _('add rgb curve "AutoLevels" to selected images'),
  clicked_callback = function(_)
    local model_path = widgets.model_chooser_button.value
    if not model_path or #model_path == 0 then
      widgets.status.label = msg_missing_model
    else
      widgets.status.label = msg_calling_autolevels
      add_autolevels_curves()
    end
  end
}

-- Button "help"
widgets.help_button = dt.new_widget("button"){
  label = _("help"),
  tooltip = _("open help page"),
  clicked_callback = function(_)
    local help_url = 'https://github.com/yellowdolphin/darktable-autolevels-module'
    if du.check_os({"windows"}) then
      help_url = 'start ' .. help_url
    end
    if dsys.launch_default_app(help_url) ~= 0 then
      widgets.status.label = _("could not open default web browser")
    end
  end
}

-- Status field
widgets.status = dt.new_widget("label"){label = "", halign = "start"}

local function update_selection_status()
  -- Updates status field with the number of selected images
  if lock_status_update then 
    lock_status_update = false
  else
    widgets.status.label = #dt.gui.action_images .. _(" image(s) selected")
  end
end

-- Initialize status field
if widgets.model_chooser_button.value and #widgets.model_chooser_button.value > 0 then
  update_selection_status()
else
  widgets.status.label = _("Specify model file & select images!")
end

-- Register event callbacks
dt.register_event("selection_watcher", "selection-changed", update_selection_status)
dt.register_event("save_model_path", "exit", save_model_path)

dt.register_lib(
  "autolevels",            -- module name (key for dt.gui.libs)
  "AutoLevels",            -- GUI name
  true,                    -- expandable
  false,                   -- resetable
  {[dt.gui.views.lighttable] = {"DT_UI_CONTAINER_PANEL_LEFT_CENTER", 100}},
  dt.new_widget("box"){
    orientation = "vertical",
    dt.new_widget("box"){
      orientation = "horizontal",
      dt.new_widget("label"){label = _("model"), halign = "start"},
      widgets.model_chooser_button,
    },
    widgets.status,
    dt.new_widget("box"){ 
      orientation = "horizontal",
      widgets.add_curve_button,
      widgets.help_button,
    },
  }
)

return script_data
