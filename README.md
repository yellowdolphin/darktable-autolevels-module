# autolevels

A Lua script for [darktable](https://www.darktable.org)

## Name

autolevels.lua - automatic color correction using _rgb curve_

## Description

This script calls AutoLevels to add an _rgb curve_ instance with a baseline color correction.

[AutoLevels](https://github.com/yellowdolphin/autolevels) is a Python script for batch-processing images with a focus on scanned analog photos with degraded colors. It uses a machine-learning (ML) model to automatically correct bleached colors and restore contrast acceptable for display (sRGB or Adobe RGB output color spaces). This model predicts curves for the three color channels, which are used as splines in darktable's _rgb curve_ module.

This script automates basic color correction using RGB curves. It does not add any color grading or “look” to the image. You can fine-tune the curves manually if needed. Any further artistic editing should be done in a separate _rgb curve_ instance.

## Installation

* For the English version, download [autolevels.lua](https://raw.githubusercontent.com/yellowdolphin/darktable-autolevels-module/master/autolevels.lua) and move it to a lua subfolder in your darktable configuration directory (e.g. `~/.config/darktable/lua/contrib/` under Linux or `%LocalAppData%\darktable\lua\contrib\` under Windows).

* For the translated version, download [autolevels.zip](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/nightly/autolevels-nightly.zip) and extract it inside a lua subfolder in your darktable configuration directory (e.g. `~/.config/darktable/lua/contrib/` under Linux or `%LocalAppData%\darktable\lua\contrib\` under Windows).

* Install additional required software, see [below](https://github.com/yellowdolphin/darktable-autolevels-module?tab=readme-ov-file#additional-software-required)

## Usage

* Start this script in the _scripts_ module in the lighttable view. An _AutoLevels_ module will appear in the same panel.

* Download the ONNX curve model [here](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/v1.0.0rc/free_xcittiny_wa14.onnx) or from the [RetroShine webpage](https://retroshine.eu/download/free_xcittiny_wa14.onnx)

* Click the little file browser button to search for the downloaded .onnx file

* Select images and press the "add AutoLevels curve" button

* You can accelerate the processing (up to 2x) by increasing the *batch size* in the _AutoLevels_ module. This will update progress and allow stopping only after each batch completes.

* In the darkroom, you will find a new history item that adds an _rgb curve_ instance in mode "RGB, independent channels". Feel free to make adjustments to the curves, the original curves will remain in the _history_ until you compress the history stack.

You might notice that the _rgb curve_ instance created by AutoLevels is applied right before the _input color profile_ module. This is where the channel-wise color correction works most effectively for JPEGs and most HDR images (RAW formats are not yet supported by the script). If you create a new _rgb curve_ instance, this will appear at the usual place in the pipeline.

**Pro tip**: If you want to process scanned photos, disable the scanner's color profile in the scan program, import scanned images as raw 48-bit PNG or TIFF files, find your scanner's ICC files and copy them into a subfolder `~/.config/darktable/color/in` (Linux) or `%LocalAppData%\darktable\lua\contrib\` (Windows). Create this folder if it does not exist yet. In the darkroom, open the _input color profile_ module and select the correct scanner profile there as input profile. This will yield much better results than starting from a JPEG in sRGB color space.

### What it Does

Under the hood, the Lua script calls `autolevels` with the `--export darktable <version>` argument:

```
autolevels --model ~/Downloads/free_xcittiny_wa14.onnx --export darktable 5.3.0 --outsuffix .jpg.xmp -- myimage.jpg
```

AutoLevels reads the XMP sidecar file associated with each selected image (or duplicate). It is passed via the `--outsuffix` option. If the XMP file does not exist, AutoLevels will create a minimal one with the default auto-apply presets. The `--outsuffix` option is optional and prevents AutoLevels from creating an output image if its value ends with ".xmp".

If you want to call AutoLevels with the `--export darktable` option outside of darktable, note that darktable only reads XMP files on startup if you have activated the `look for updated XMP files on startup` option in preferences/storage.

## Additional Software Required

- Python 3.9, 3.10, 3.11, 3.12, or 3.13

- AutoLevels

On most Linux distros, Python is already pre-installed. For other operating systems, download it from [Python.org](https://www.python.org/downloads/) or install it via your favourite app store. Make sure you mark the checkbox "Add Python executable to PATH". Then, to install AutoLevels, open a shell (cmd on Windows) and execute:

```bash
pip install autolevels
```

This will automatically install AutoLevels and the following dependencies:

- numpy
- pillow
- piexif
- opencv-python
- h5py
- onnxruntime

### Windows 10 only

The latest versions of onnxruntime don't support Windows 10. To use AutoLevels in darktable on Windows 10, install Python version 3.13 or earlier (but not before version 3.9), then install autolevels and onnxruntime version 1.20.1:

```bash
pip install autolevels onnxruntime==1.20.1
```

## Limitations

RAW images are currently not supported.

## Author

Marius Wanko - marius.wanko@outlook.de

## Change Log
