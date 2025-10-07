# autolevels

Ein Lua-Skript für [darktable](https://www.darktable.org)

## Name

autolevels.lua – automatische Farbkorrektur mit _RGB-Kurve_

## Beschreibung

Dieses Skript ruft AutoLevels auf, um eine _RGB-Kurve_-Instanz mit einer grundlegenden Farbkorrektur hinzuzufügen.

[AutoLevels](https://github.com/yellowdolphin/autolevels) ist ein Python-Skript für die Stapelverarbeitung von Bildern mit Fokus auf gescannten Analogfotos mit verblassten Farben. Es verwendet ein Machine-Learning- (ML-) Modell, um automatisch ausgebleichte Farben zu korrigieren und einen für den Bildschirm akzeptablen Kontrast wiederherzustellen (sRGB oder Adobe RGB Ausgabefarbprofil). Dieses Modell sagt Kurven für die drei Farbkanäle vorher, die als Splines in darktables _RGB-Kurve_-Modul verwendet werden.

Dieses Skript automatisiert die Farbkorrektur mittels RGB-Kurven. Es fügt dem Bild weder Farbgradierung noch einen „Look" hinzu. Du kannst die Kurven bei Bedarf manuell feinabstimmen. Jede weitere künstlerische Bearbeitung sollte jedoch in einer separaten _RGB-Kurve_-Instanz durchgeführt werden.

## Installation

Lade [autolevels.zip](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/nightly/autolevels-nightly.zip) herunter und entpacke es in einen lua-Unterordner in Ihrem darktable-Konfigurationsverzeichnis (z.B. `~/.config/darktable/lua/contrib/` unter Linux oder `%AppData%\darktable\lua\contrib\` unter Windows).

## Verwendung

* Starte dieses Skript im _scripts_-Modul in der Leuchtisch-Ansicht. Ein _AutoLevels_-Modul erscheint im selben Panel.

* Lade das ONNX-Kurvenmodell [hier](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/v1.0.0rc/free_xcittiny_wa14.onnx) herunter

* Klicke auf die kleine Dateibrowser-Schaltfläche, um nach der heruntergeladenen .onnx-Datei zu suchen

* Wähle Bilder aus und drücke die Schaltfläche „AutoLevels-Kurve hinzufügen"

* Du kannst die Verarbeitung beschleunigen (bis zu 2x), indem du die *Stapelgröße* im _AutoLevels_-Modul erhöhst. Dies aktualisiert den Fortschritt und ermöglicht das Stoppen erst nach Abschluss eines Stapels.

* In der Dunkelkammer findest du einen neuen Verlaufseintrag, der eine _RGB-Kurve_-Instanz im Modus „RGB, unabhängige Kanäle" hinzufügt. Du kannst gerne Anpassungen an den Kurven vornehmen, die ursprünglichen Kurven bleiben im _Verlauf_ erhalten, bis du den Verlaufsstapel komprimierst.

Du wirst bemerken, dass die von AutoLevels erstellte _RGB-Kurve_-Instanz direkt vor dem _Eingabefarbprofil_-Modul angewendet wird. Dies ist der Ort, an dem die kanalweise Farbkorrektur bei JPEGs und den meisten HDR-Bildern am effektivsten funktioniert (RAW-Formate werden vom Skript noch nicht unterstützt). Wenn du eine neue _RGB-Kurve_-Instanz erstellst, erscheint diese an der üblichen Stelle in der Pipeline.

### Was es tut

Unter der Haube ruft das Lua-Skript `autolevels` mit dem Argument `--export darktable <version>` auf:

```
autolevels --model ~/Downloads/free_xcittiny_wa14.onnx --export darktable 5.3.0 --outsuffix .jpg.xmp -- myimage.jpg
```

AutoLevels liest die XMP-Begleitdatei, die mit jedem ausgewählten Bild (oder Duplikat) verbunden ist. Sie wird über die Option `--outsuffix` übergeben. Wenn die XMP-Datei nicht existiert, erstellt AutoLevels eine minimale Datei mit den standardmäßigen automatischen Voreinstellungen. Die Option `--outsuffix` ist optional und verhindert, dass AutoLevels ein Ausgabebild erstellt, wenn ihr Wert auf „.xmp" endet.

Wenn du AutoLevels mit der Option `--export darktable` außerhalb von darktable aufrufen möchtest, beachte, dass darktable XMP-Dateien bei Programmstart nur liest, wenn du die Option `beim Start nach aktualisierten XMP-Dateien suchen` in den darktable-Einstellungen/Speichern aktiviert hast.

## Zusätzlich erforderliche Software

- Python 3.9 oder neuer

- AutoLevels

Bei den meisten Linux-Distributionen ist Python bereits vorinstalliert. Für andere Betriebssysteme lade es von [Python.org](https://www.python.org/downloads/) herunter oder installiere es über deinen bevorzugten App Store. Stelle sicher, dass das Kontrollkästchen "Add Python executable to PATH" aktiviert ist. Um AutoLevels zu installieren, öffne dann eine Shell (cmd unter Windows) und führe folgendes aus:

```bash
pip install autolevels
```

Dies installiert automatisch AutoLevels und die folgenden Abhängigkeiten:

- numpy
- pillow
- piexif
- opencv-python
- h5py
- onnxruntime

## Einschränkungen

RAW-Bilder werden derzeit nicht unterstützt.

## Autor

Marius Wanko - marius.wanko@outlook.de

## Änderungsprotokoll
