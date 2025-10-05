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
local ds = require "lib/dtutils.string"
local gettext = dt.gettext

du.check_min_api_version("9.3.0", autolevels)

local apply_sidecar_works = false
-- does not update write_timestamp in DB => check_xmp_on_startup fails as xmp's mtime is newer now
-- incorrectly handles tags with spaces (strips anything after the space), like import()


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


local function get_autolevels_outsuffix(filename, sidecar)
  -- Return the unique part of sidecar that deviates from filename
  -- Example: filename='foo.jpg', sidecar='/path/to/foo_01.jpg.xmp' -> '_01.jpg.xmp'
  local sidecar_filename = duf.get_filename(sidecar)
  local basename = duf.get_basename(filename)
  return ds.sanitize(sidecar_filename:sub(#basename + 1, -1))  -- remove basename from sidecar_filename
end


local function run_autolevels(path, outsuffix, fn, model)
  local cmd_str = "autolevels --model "..model.." --folder "..path.." --outfolder "..path
    .." --outsuffix "..outsuffix.." --export darktable "..dt.configuration.version.." -- "..fn
  -- dt.print_log("DEBUG cmd_str: "..cmd_str)
  dt.control.execute(cmd_str)
end


local function get_batch_size()
  return math.tointeger(widgets.batch_size_slider.value)
end


local function save_batch_size()
  dt.preferences.write("autolevels", "batch_size", "integer", get_batch_size())
end


local function flatten_batches(batches, selection)
  -- Return a subset of batches encompassing selection
  -- selection: set-like table of batch keys
  local images = {}
  for key, __ in pairs(selection) do
    if not batches[key] then
      dt.print_log("KeyError: batch " .. key .. " not found")
      goto continue
    end
    for __, image in pairs(batches[key]) do
      table.insert(images, image)
    end
    ::continue::
  end
  return images
end


local function add_autolevels_curves()
  -- Add an rgbcurve from AutoLevels to each selected image
  
  local images = dt.gui.selection()
  local selected_images = dt.gui.selection()
  local processed_images = {}
  local quoted_model = ds.sanitize(widgets.model_chooser_button.value)

  -- Form a batch for each unique (path, duplicate) pair (path, outsuffix)
  local batch_size = get_batch_size()
  local batches = {}
  local selected_batches = {}
  local processed_batches = {}


  local function append_image(quoted_path, quoted_outsuffix, image, batch_size)
    -- check image format
    if image.is_raw then
      dt.print("Image " .. image.filename .. " has a RAW format, currently not supported, skipping")
      return
    end

    -- create key with unique (path, outsuffix) pair and batch_id
    local batch_id = 1
    local key = quoted_path .. "|" .. quoted_outsuffix .. "|" .. string.format("%06d", batch_id)

    -- find next available batch (batches contain max batch_size images)
    batches[key] = batches[key] or {}
    while #batches[key] >= batch_size do
      batch_id = batch_id + 1
      key = quoted_path .. "|" .. quoted_outsuffix .. "|" .. string.format("%06d", batch_id)
      batches[key] = batches[key] or {}
    end

    -- append image to batch
    table.insert(batches[key], image)
    selected_batches[key] = true  -- set-like table of batch keys
    dt.print_log("appended image " .. image.id .. " to batch " .. key)
  end


  local function get_path_outsuffix(key)
    path_outsuffix_id = du.split(key, '|')
    return path_outsuffix_id[1], path_outsuffix_id[2]
  end


  for __, image in pairs(images) do  -- __ are same as in ipairs, different from image.id
    local quoted_outsuffix = get_autolevels_outsuffix(image.filename, image.sidecar)
    local quoted_path = ds.sanitize(image.path)
    append_image(quoted_path, quoted_outsuffix, image, batch_size)
  end

  sorted_batch_keys = {}
  for key in pairs(selected_batches) do
    table.insert(sorted_batch_keys, key)
  end
  table.sort(sorted_batch_keys)

  local num_added_curves = 0
  local fallback_used = false
  for __, key in pairs(sorted_batch_keys) do
    local batch_images = batches[key]
    dt.print_log("processing batch " .. key)
    -- no table packing/unpacking!
    local quoted_path, quoted_outsuffix = get_path_outsuffix(key)

    local quoted_parts = {}
    for __, image in pairs(batch_images) do
      table.insert(quoted_parts, ds.sanitize(image.filename))
    end
    local quoted_fns = table.concat(quoted_parts, ' ')
  
    -- run autolevels with all images of the batch
    if widgets.stop_button.visible == false then
      break
    end
    run_autolevels(quoted_path, quoted_outsuffix, quoted_fns, quoted_model)

    -- Update the database from the modified XMP files
    for __, image in pairs(batch_images) do
      local success = false
      local result = nil
      if apply_sidecar_works then
        success, result = pcall(function()
          image:apply_sidecar(image.sidecar)  -- requires darktable>=5.2, updates db.change_timestamp
        end)
      end
      if not success then
        fallback_used = true  -- fallback until apply_sidecar is fully fixed
        image.delete(image)  -- needed to update thumbnail on import
        pcall(function() dt.database.import(image.path..path_separator..image.filename) end)  -- crashes dt if not found
      end
      num_added_curves = num_added_curves + 1
      table.insert(processed_images, image)
    end
    selected_batches[key] = nil
  end

  if not fallback_used then
    -- db.write_timestamp needs to be updated, which is compared with mtime on startup
    -- Here it is done by gui.action, but this is brittle, may cause race conditions, see below.
    --dt.print_log("writing xmp files for " .. #processed_images .. " images...")
    local sele = dt.gui.selection(processed_images)
    dt.gui.action("lib/copy_history/write sidecar files", "", "", 1.000)  -- 0.2 ms / xmp
    --dt.gui.action("lib/copy_history/write sidecar files", "")  -- worse
    if #sele < #processed_images then
      -- selection can change due to user interaction
      dt.print("Don't change selection during processing!")
      dt.print_log(#sele.."/"..#processed_images.." images are still selected, trying again...")
      sele = dt.gui.selection(processed_images)
      dt.gui.action("lib/copy_history/write sidecar files", "", "", 1.000)  -- 0.2 ms / xmp
    end
    --dt.print_log("all xmp files updated")
  end

  -- Select any unprocessed images
  dt.control.sleep(400)  -- 380+ ms OK, 360 ms causes race condition:
  selected_images = flatten_batches(batches, selected_batches)
  dt.gui.selection(selected_images)  -- BUG: prevents dt.gui.action("lib/copy_history/write sidecar files", "", "", 1.000)
  -- #selected_images is irrelevant, {} gives the same, docs say empty table selects nothing
  -- gui.action always returns nil, not a status string as docs say
  dt.print_log(#processed_images .. "/" .. #images .. " images processed, " .. #selected_images .. " remain selected")

  lock_status_update = true  --prevent selection-changed hook from overwriting this:
  widgets.status.label = num_added_curves .. _(" curve(s) added")
  widgets.stop_button.visible = false
  widgets.add_curve_button.visible = true
end


local function save_model_path()
  dt.preferences.write("autolevels", "model_path", "string", widgets.model_chooser_button.value)
end


-- Assign translated messages to avoid segfault (field "1" can't be written for type ...)
local msg_filetype_error = _("ERROR: selected file is not an ONNX file")
local msg_missing_model = _("missing model path")
local msg_autolevels_not_found = _("autolevels executable not found")
local msg_autolevels_not_found_long = _("autolevels executable not found, make sure it is installed")
local msg_calling_autolevels = _("calling autolevels...")
local msg_stopping = _("stopping...")


-- Add GUI lib elements

-- Widget for model_path
widgets.model_path_label = dt.new_widget("label"){label = _("model"), halign = "start"}
widgets.model_chooser_button = dt.new_widget("file_chooser_button"){
  title = _("select model file"),
  tooltip = _("select your downloaded .onnx curve model file"),
  is_directory = false,
  changed_callback = function(__)
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


-- Widget for batch_size
widgets.batch_size_slider = dt.new_widget("slider"){
  soft_min = 1,
  soft_max = 10,
  hard_min = 1,
  hard_max = 100,
  step = 1,
  digits = 0,
  value = dt.preferences.read("autolevels", "batch_size", "integer") or 1,
  label = _("batch size"),
  tooltip = _("choose the number of images to process in one batch"),
}


-- Button "add AutoLevels curve"
widgets.add_curve_button = dt.new_widget("button"){
  label = _("add AutoLevels curve"),
  tooltip = _('add rgb curve "AutoLevels" to selected images'),
  clicked_callback = function(__)
    widgets.add_curve_button.visible = false
    widgets.stop_button.visible = true
    local model_path = widgets.model_chooser_button.value
    if not model_path or #model_path == 0 then
      widgets.status.label = msg_missing_model
      dt.print(msg_missing_model)
    elseif duf.check_if_bin_exists('autolevels') == false then
      widgets.status.label = msg_autolevels_not_found
      dt.print(msg_autolevels_not_found_long)
    else
      widgets.status.label = msg_calling_autolevels
      add_autolevels_curves()
    end
  end
}


-- Button "stop"
widgets.stop_button = dt.new_widget("button"){
  label = _("stop"),
  tooltip = _('stop processing'),
  clicked_callback = function(__)
    widgets.status.label = msg_stopping
    widgets.stop_button.visible = false
    widgets.add_curve_button.visible = true
  end
}
widgets.stop_button.visible = false


-- Button "help"
widgets.help_button = dt.new_widget("button"){
  label = _("help"),
  tooltip = _("open help page"),
  clicked_callback = function(__)
    local readme = _("README.md")
    local help_url = 'https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/v1.0.0/' .. readme
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
dt.register_event("save_batch_size", "exit", save_batch_size)


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
      widgets.model_path_label,
      widgets.model_chooser_button,
    },
    dt.new_widget("box"){
      orientation = "horizontal",
      widgets.batch_size_slider,
      widgets.help_button,
    },
    dt.new_widget("box"){ 
      orientation = "horizontal",
      widgets.add_curve_button,
      widgets.stop_button,
    },
    widgets.status,
  }
)

return script_data
