# autolevels

Ett Lua-skript för [darktable](https://www.darktable.org)

## Namn

autolevels.lua – automatisk färgkorrigering med _rgb-kurva_

## Beskrivning

Detta skript anropar AutoLevels för att lägga till en _rgb-kurva_-instans med en grundläggande färgkorrigering.

[AutoLevels](https://github.com/yellowdolphin/autolevels) är ett Python-skript för batch-bearbetning av bilder med fokus på skannade analogfoton med nedbrytna färger. Det använder en maskininlärningsmodell (ML) för att automatiskt korrigera blekta färger och återställa kontrast som är acceptabel för visning (sRGB eller Adobe RGB utfärgsrymder). Denna modell förutsäger kurvor för de tre färgkanalerna, som används som splines i darktables _rgb-kurva_-modul.

Detta skript automatiserar grundläggande färgkorrigering med RGB-kurvor. Det lägger inte till någon färggradering eller "look" till bilden. Du kan finjustera kurvorna manuellt vid behov. Eventuell ytterligare konstnärlig redigering bör göras i en separat _rgb-kurva_-instans.

## Installation

Ladda ner [autolevels.zip](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/nightly/autolevels-nightly.zip) och packa upp den i en lua-undermapp i din darktable-konfigurationskatalog (t.ex. `~/.config/darktable/lua/contrib/` under Linux eller `%LocalAppData%\darktable\lua\contrib\` under Windows).

## Användning

* Starta detta skript i _script_-modulen i ljusbordsvyn. En _AutoLevels_-modul kommer att visas i samma panel.

* Ladda ner ONNX-kurvmodellen [här](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/v1.0.0rc/free_xcittiny_wa14.onnx) eller från [RetroShine-webbsidan](https://retroshine.eu/download/free_xcittiny_wa14.onnx)

* Klicka på den lilla filbläddringsknappen för att söka efter den nedladdade .onnx-filen

* Välj bilder och tryck på knappen "lägg til AutoLevels-kurva"

* Du kan påskynda bearbetningen (upp till 2x) genom att öka *batchstorlek* i _AutoLevels_-modulen. Detta uppdaterar framstegsindikatorn och tillåter stopp endast efter att varje batch har slutförts.

* I mörkrummet hittar du ett nytt historikobjekt som lägger till en _rgb-kurva_-instans i läget "RGB, oberoende kanaler". Du kan gärna göra justeringar av kurvorna, originalkurvorna kommer att finnas kvar i _historik_ tills du komprimerar historikstacken.

Du kanske märker att _rgb-kurva_-instansen som skapas av AutoLevels tillämpas precis före modulen _ingående färgprofil_. Detta är där den kanalvisa färgkorrigeringen fungerar mest effektivt för JPEG och de flesta HDR-bilder (RAW-format stöds ännu inte av skriptet). Om du skapar en ny _rgb-kurva_-instans kommer denna att visas på den vanliga platsen i pipelines.

### Vad det gör

Under huven anropar Lua-skriptet `autolevels` med argumentet `--export darktable <version>`:

```
autolevels --model ~/Downloads/free_xcittiny_wa14.onnx --export darktable 5.3.0 --outsuffix .jpg.xmp -- myimage.jpg
```

AutoLevels läser XMP-sidofilen som är kopplad till varje vald bild (eller duplikat). Den skickas via alternativet `--outsuffix`. Om XMP-filen inte finns kommer AutoLevels att skapa en minimal fil med standardinställningarna för automatisk tillämpning. Alternativet `--outsuffix` är valfritt och förhindrar att AutoLevels skapar en utdatabild om dess värde slutar med ".xmp".

Om du vill anropa AutoLevels med alternativet `--export darktable` utanför darktable, observera att darktable endast läser XMP-filer vid uppstart om du har aktiverat alternativet `sök efter uppdaterade XMP-filer vid start` i inställningar/lagring.

## Ytterligare programvara som krävs

- Python 3.9 eller senare

- AutoLevels

På de flesta Linux-distributioner är Python redan förinstallerat. För andra operativsystem, ladda ner det från [Python.org](https://www.python.org/downloads/) eller installera det via din favoritappbutik. Se till att du markerar kryssrutan "Add Python executable to PATH". Öppna sedan ett skal (cmd på Windows) och kör:

```bash
pip install autolevels
```

Detta kommer automatiskt att installera AutoLevels och följande beroenden:

- numpy
- pillow
- piexif
- opencv-python
- h5py
- onnxruntime

## Begränsningar

RAW-bilder stöds för närvarande inte.

## Författare

Marius Wanko - marius.wanko@outlook.de

## Ändringslogg
