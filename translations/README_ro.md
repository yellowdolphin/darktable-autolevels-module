# autolevels

Un script Lua pentru [darktable](https://www.darktable.org)

## Nume

autolevels.lua – corecție automată a culorilor folosind _rgb curve_

## Descriere

Acest script apelează AutoLevels pentru a adăuga o instanță de _rgb curve_ cu o corecție de culoare de bază.

[AutoLevels](https://github.com/yellowdolphin/autolevels) este un script Python pentru procesarea în serie a imaginilor, cu accent pe fotografiile analogice scanate cu culori degradate. Utilizează un model de învățare automată (ML) pentru a corecta automat culorile decolorate și a restabili un contrast acceptabil pentru afișare (spații de culoare de ieșire sRGB sau Adobe RGB). Acest model prezice curbe pentru cele trei canale de culoare, care sunt utilizate ca spline-uri în modulul _rgb curve_ din darktable.

Acest script automatizează corecția de bază a culorilor folosind curbe RGB. Nu adaugă nicio gradare de culoare sau „aspect" imaginii. Puteți ajusta fin curbele manual dacă este necesar. Orice editare artistică suplimentară ar trebui efectuată într-o instanță separată de _rgb curve_.

## Utilizare

* Descărcați [autolevels.lua](https://raw.githubusercontent.com/yellowdolphin/darktable-autolevels-module/master/autolevels.lua) și mutați-l într-un subdirector lua din directorul de configurare darktable (de exemplu `~/.config/darktable/lua/contrib/` sub Linux sau `%AppData%\darktable\lua\contrib\` sub Windows).

* Porniți acest script în modulul _scripts_ din vizualizarea masă luminoasă. Un modul _AutoLevels_ va apărea în același panel.

* Descărcați modelul de curbe ONNX [aici](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/v1.0.0rc/free_xcittiny_wa14.onnx) sau de pe [pagina RetroShine](https://retroshine.eu/download/free_xcittiny_wa14.onnx)

* Faceți clic pe butonul mic de browser de fișiere pentru a căuta fișierul .onnx descărcat

* Selectați imaginile și apăsați butonul „adaugă curbă AutoLevels"

* Puteți accelera procesarea (până la 2x) prin creșterea *dimensiune lot* în modulul _AutoLevels_. Acest lucru va actualiza progresul și va permite oprirea doar după finalizarea fiecărui lot.

* În cameră obscură, veți găsi un nou element în istoric care adaugă o instanță de _rgb curve_ în modul „RGB, independent channels". Simțiți-vă liber să faceți ajustări la curbe, curbele originale vor rămâne în _istoric_ până când comprimați stiva de istoric.

S-ar putea să observați că instanța de _rgb curve_ creată de AutoLevels este aplicată chiar înainte de modulul _profil de culoare de intrare_. Acesta este locul unde corecția de culoare pe canale funcționează cel mai eficient pentru fișierele JPEG și majoritatea imaginilor HDR (formatele RAW nu sunt încă suportate de script). Dacă creați o nouă instanță de _rgb curve_, aceasta va apărea la locul obișnuit în pipeline.

### Ce face

În spate, scriptul Lua apelează `autolevels` cu argumentul `--export darktable <versiune>`:

```
autolevels --model ~/Downloads/free_xcittiny_wa14.onnx --export darktable 5.3.0 --outsuffix .jpg.xmp -- myimage.jpg
```

AutoLevels citește fișierul sidecar XMP asociat cu fiecare imagine selectată (sau duplicat). Este transmis prin opțiunea `--outsuffix`. Dacă fișierul XMP nu există, AutoLevels va crea unul minimal cu presetările auto-aplicate implicite. Opțiunea `--outsuffix` este opțională și împiedică AutoLevels să creeze o imagine de ieșire dacă valoarea sa se termină cu „.xmp".

Dacă doriți să apelați AutoLevels cu opțiunea `--export darktable` în afara darktable, rețineți că darktable citește fișierele XMP la pornire doar dacă ați activat opțiunea `look for updated XMP files on startup` (caută fișiere XMP actualizate la pornire) în preferințe/storage.

## Software suplimentar necesar

- Python 3.9 sau mai recent

- AutoLevels

Pe majoritatea distribuțiilor Linux, Python este deja preinstalat. Pentru alte sisteme de operare, descărcați-l de pe [Python.org](https://www.python.org/downloads/) sau instalați-l prin magazinul dvs. de aplicații preferat. Asigurați-vă că bifați caseta „Add Python executable to PATH". Apoi, pentru a instala AutoLevels, deschideți un terminal (cmd pe Windows) și executați:

```bash
pip install autolevels
```

Acest lucru va instala automat AutoLevels și următoarele dependențe:

- numpy
- pillow
- piexif
- opencv-python
- h5py
- onnxruntime

## Limitări

Imaginile RAW nu sunt suportate în prezent.

## Autor

Marius Wanko - marius.wanko@outlook.de

## Jurnalul modificărilor