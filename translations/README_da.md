# autolevels

Et Lua-script til [darktable](https://www.darktable.org)

## Navn

autolevels.lua – automatisk farvekorrektion ved hjælp af _rgb-kurve_

## Beskrivelse

Dette script kalder AutoLevels for at tilføje en _rgb-kurve_-instans med en grundlæggende farvekorrektion.

[AutoLevels](https://github.com/yellowdolphin/autolevels) er et Python-script til batchbehandling af billeder med fokus på scannede analoge fotos med nedbrudte farver. Det bruger en maskinlærings- (ML-) model til automatisk at korrigere blegede farver og gendanne en kontrast, der er acceptabel til visning (sRGB eller Adobe RGB udgangsfarveprofiler). Denne model forudsiger kurver for de tre farvekanaler, som anvendes som splines i darktables _rgb-kurve_-modul.

Dette script automatiserer grundlæggende farvekorrektion ved hjælp af RGB-kurver. Det tilføjer ikke nogen farvegradering eller "look" til billedet. Du kan finjustere kurverne manuelt om nødvendigt. Enhver yderligere kunstnerisk redigering bør udføres i en separat _rgb-kurve_-instans.

## Installation

Download [autolevels.zip](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/nightly/autolevels-nightly.zip) og udpak det i en lua-undermappe i din darktable-konfigurationsmappe (f.eks. `~/.config/darktable/lua/contrib/` under Linux eller `%AppData%\darktable\lua\contrib\` under Windows).

## Anvendelse

* Start dette script i _scripts_-modulet i lysbords-visningen. Et _AutoLevels_-modul vil vises i samme panel.

* Download ONNX-kurvemodellen [her](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/v1.0.0rc/free_xcittiny_wa14.onnx) eller fra [RetroShine-websiden](https://retroshine.eu/download/free_xcittiny_wa14.onnx)

* Klik på den lille filbrowser-knap for at søge efter den downloadede .onnx-fil

* Vælg billeder og tryk på knappen "tilføj AutoLevels-kurve"

* Du kan accelerere behandlingen (op til 2x) ved at øge *batchstørrelsen* i _AutoLevels_-modulet. Dette vil opdatere fremskridtet og tillade stop først efter hver batch er færdig.

* I mørkekammeret finder du et nyt historik-element, der tilføjer en _rgb-kurve_-instans i tilstanden "RGB, uafhængige kanaler". Du er velkommen til at foretage justeringer af kurverne, de originale kurver forbliver i _historik_, indtil du komprimerer historikstakken.

Du vil måske bemærke, at den _rgb-kurve_-instans, der oprettes af AutoLevels, anvendes lige før modulet _input-farveprofil_. Det er her, den kanalvise farvekorrektion fungerer mest effektivt for JPEG'er og de fleste HDR-billeder (RAW-formater understøttes endnu ikke af scriptet). Hvis du opretter en ny _rgb-kurve_-instans, vil denne vises på det sædvanlige sted i pipelinen.

### Hvad det gør

Under motorhjelmen kalder Lua-scriptet `autolevels` med argumentet `--export darktable <version>`:

```
autolevels --model ~/Downloads/free_xcittiny_wa14.onnx --export darktable 5.3.0 --outsuffix .jpg.xmp -- myimage.jpg
```

AutoLevels læser XMP-sidecar-filen, der er tilknyttet hvert valgt billede (eller duplikat). Den overføres via `--outsuffix`-indstillingen. Hvis XMP-filen ikke eksisterer, vil AutoLevels oprette en minimal fil med standard auto-apply-forindstillingerne. `--outsuffix`-indstillingen er valgfri og forhindrer AutoLevels i at oprette et udgangsbillede, hvis værdien ender med ".xmp".

Hvis du vil kalde AutoLevels med `--export darktable`-indstillingen uden for darktable, skal du bemærke, at darktable kun læser XMP-filer ved opstart, hvis du har aktiveret indstillingen `look for updated XMP files on startup` i indstillinger/storage.

## Yderligere nødvendig software

- Python 3.9 eller nyere

- AutoLevels

På de fleste Linux-distributioner er Python allerede forudinstalleret. For andre operativsystemer kan du downloade det fra [Python.org](https://www.python.org/downloads/) eller installere det via din foretrukne app-butik. Sørg for at markere afkrydsningsfeltet "Add Python executable to PATH". For at installere AutoLevels skal du derefter åbne en shell (cmd på Windows) og udføre:

```bash
pip install autolevels
```

Dette vil automatisk installere AutoLevels og følgende afhængigheder:

- numpy
- pillow
- piexif
- opencv-python
- h5py
- onnxruntime

## Begrænsninger

RAW-billeder understøttes i øjeblikket ikke.

## Forfatter

Marius Wanko - marius.wanko@outlook.de

## Ændringslog