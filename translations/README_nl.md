# autolevels

Een Lua-script voor [darktable](https://www.darktable.org)

## Naam

autolevels.lua - automatische kleurcorrectie met _rgb curve_

## Beschrijving

Dit script roept AutoLevels aan om een _rgb curve_ instantie toe te voegen met een basale kleurcorrectie.

[AutoLevels](https://github.com/yellowdolphin/autolevels) is een Python-script voor batchverwerking van afbeeldingen met focus op gescande analoge foto's met gedegradeerde kleuren. Het gebruikt een machine learning (ML) model om automatisch verbleekte kleuren te corrigeren en acceptabel contrast te herstellen voor weergave (sRGB of Adobe RGB uitvoerkleurruimtes). Dit model voorspelt curves voor de drie kleurkanalen, die worden gebruikt als splines in darktable's _rgb curve_ module.

Dit script automatiseert basale kleurcorrectie met rgb curves. Het voegt geen kleurgradering of "look" toe aan de afbeelding. Je kunt de curves handmatig verfijnen indien nodig. Verdere artistieke bewerkingen moeten in een aparte _rgb curve_ instantie worden gedaan.

## Installatie

Download [autolevels.zip](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/nightly/autolevels-nightly.zip) en pak het uit in een lua-submap in uw darktable-configuratiemap (bijv. `~/.config/darktable/lua/contrib/` onder Linux of `%AppData%\darktable\lua\contrib\` onder Windows).

## Gebruik

* Start dit script in de _scripts_ module in de bibliotheek-weergave. Een _AutoLevels_ module zal verschijnen in hetzelfde paneel.

* Start dit script in de _scripts_ module in de bibliotheek-weergave. Een _AutoLevels_ module zal verschijnen in hetzelfde paneel.

* Download het ONNX-curvemodel [hier](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/v1.0.0rc/free_xcittiny_wa14.onnx) of van de [RetroShine webpagina](https://retroshine.eu/download/free_xcittiny_wa14.onnx)

* Klik op de kleine bestandsbrowserknop om het gedownloade .onnx-bestand te zoeken

* Selecteer afbeeldingen en druk op de knop "AutoLevels-curve toevoegen"

* Je kunt de verwerking versnellen (tot 2x) door de *batchgrootte* in de _AutoLevels_ module te verhogen. Dit zal de voortgang bijwerken en alleen stoppen toestaan nadat elke batch is voltooid.

* In de ontwikkel je een nieuw historieitem dat een _rgb curve_ instantie toevoegt in de modus "RGB, onafhankelijke kanalen". Voel je vrij om aanpassingen aan de curves te maken, de originele curves blijven in de _historie_ totdat je de historie comprimeert.

Je zou kunnen merken dat de _rgb curve_ instantie die door AutoLevels is aangemaakt, direct vóór de _ingaand kleurprofiel_ module wordt toegepast. Dit is waar de kanaalgewijze kleurcorrectie het meest effectief werkt voor JPEG's en de meeste HDR-afbeeldingen (RAW-formaten worden nog niet ondersteund door het script). Als je een nieuwe _rgb curve_ instantie aanmaakt, verschijnt deze op de gebruikelijke plaats in de pipeline.

### Wat het doet

Onder de motorkap roept het Lua-script `autolevels` aan met het `--export darktable <versie>` argument:

```
autolevels --model ~/Downloads/free_xcittiny_wa14.onnx --export darktable 5.3.0 --outsuffix .jpg.xmp -- myimage.jpg
```

AutoLevels leest het XMP-sidecar-bestand dat is gekoppeld aan elke geselecteerde afbeelding (of duplicaat). Het wordt doorgegeven via de `--outsuffix` optie. Als het XMP-bestand niet bestaat, zal AutoLevels er een minimaal bestand mee aanmaken met de standaard automatisch toegepaste presets. De `--outsuffix` optie is optioneel en voorkomt dat AutoLevels een uitvoerafbeelding aanmaakt als de waarde eindigt op ".xmp".

Als je AutoLevels wilt aanroepen met de `--export darktable` optie buiten darktable, let dan op dat darktable alleen XMP-bestanden bij het opstarten leest als je de optie `zoek naar bijgewerkte XMP-bestanden bij het opstarten` hebt geactiveerd in voorkeuren/opslagruimte.

## Aanvullende vereiste software

- Python 3.9 of hoger

- AutoLevels

Op de meeste Linux-distributies is Python al voorgeïnstalleerd. Voor andere besturingssystemen kun je het downloaden van [Python.org](https://www.python.org/downloads/) of installeren via je favoriete app store. Zorg ervoor dat je het vakje "Add Python executable to PATH" aanvinkt. Vervolgens, om AutoLevels te installeren, open een shell (cmd op Windows) en voer uit:

```bash
pip install autolevels
```

Dit zal automatisch AutoLevels en de volgende afhankelijkheden installeren:

- numpy
- pillow
- piexif
- opencv-python
- h5py
- onnxruntime

## Beperkingen

RAW-afbeeldingen worden momenteel niet ondersteund.

## Auteur

Marius Wanko - marius.wanko@outlook.de

## Wijzigingslogboek
