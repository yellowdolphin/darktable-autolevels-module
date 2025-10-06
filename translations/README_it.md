# autolevels

Uno script Lua per [darktable](https://www.darktable.org)

## Nome

autolevels.lua - correzione automatica del colore usando _Curva RGB_

## Descrizione

Questo script chiama AutoLevels per aggiungere un'istanza di _Curva RGB_ con una correzione del colore di base.

[AutoLevels](https://github.com/yellowdolphin/autolevels) è uno script Python per l'elaborazione batch di immagini con particolare attenzione alle foto analogiche scannerizzate con colori degradati. Utilizza un modello di apprendimento automatico (ML) per correggere automaticamente i colori sbiaditi e ripristinare un contrasto accettabile per la visualizzazione (spazi colore di output sRGB o Adobe RGB). Questo modello predice le curve per i tre canali di colore, che vengono utilizzate come spline nel modulo _Curva RGB_ di darktable.

Questo script automatizza la correzione del colore di base usando curve RGB. Non aggiunge alcuna gradazione di colore o "look" all'immagine. Puoi regolare manualmente le curve se necessario. Qualsiasi ulteriore editing artistico dovrebbe essere fatto in un'istanza separata di _Curva RGB_.

## Installazione

Scarica [autolevels.zip](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/nightly/autolevels-nightly.zip) ed estrailo in una sottocartella lua nella tua directory di configurazione di darktable (ad esempio, `~/.config/darktable/lua/contrib/` su Linux o `%AppData%\darktable\lua\contrib\` su Windows).

## Utilizzo

* Avvia questo script nel modulo _scripts_ nella vista tavolo luminoso. Un modulo _AutoLevels_ apparirà nello stesso pannello.

* Scarica il modello di curva ONNX [qui](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/v1.0.0rc/free_xcittiny_wa14.onnx) o dalla [pagina web RetroShine](https://retroshine.eu/download/free_xcittiny_wa14.onnx)

* Fai clic sul piccolo pulsante di esplorazione file per cercare il file .onnx scaricato

* Seleziona le immagini e premi il pulsante "aggiungi curva AutoLevels"

* Puoi accelerare l'elaborazione (fino a 2x) aumentando la *dimensione batch* nel modulo _AutoLevels_. Questo aggiornerà il progresso e permetterà di fermare solo dopo il completamento di ogni batch.

* Nella camera oscura, troverai un nuovo elemento della coda di sviluppo che aggiunge un'istanza di _Curva RGB_ in modalità "RGB, canali indipendenti". Sentiti libero di apportare modifiche alle curve, le curve originali rimarranno nella _Coda di sviluppo_ fino a quando non comprimi la coda di sviluppo.

Potresti notare che l'istanza di _Curva RGB_ creata da AutoLevels viene applicata subito prima del modulo _Profilo colore in ingresso_. Questo è il punto in cui la correzione del colore per canale funziona più efficacemente per i JPEG e la maggior parte delle immagini HDR (i formati RAW non sono ancora supportati dallo script). Se crei una nuova istanza di _Curva RGB_, questa apparirà nel posto abituale nella coda di elaborazione.

### Cosa fa

Internamente, lo script Lua chiama `autolevels` con l'argomento `--export darktable <versione>`:

```
autolevels --model ~/Downloads/free_xcittiny_wa14.onnx --export darktable 5.3.0 --outsuffix .jpg.xmp -- myimage.jpg
```

AutoLevels legge il file sidecar XMP associato a ciascuna immagine selezionata (o duplicato). Viene passato tramite l'opzione `--outsuffix`. Se il file XMP non esiste, AutoLevels ne creerà uno minimale con i preset di applicazione automatica predefiniti. L'opzione `--outsuffix` è facoltativa e impedisce ad AutoLevels di creare un'immagine di output se il suo valore termina con ".xmp".

Se vuoi chiamare AutoLevels con l'opzione `--export darktable` al di fuori di darktable, nota che darktable legge i file XMP all'avvio solo se hai attivato l'opzione `Controlla i file XMP aggiornati all'avvio` in Preferenze/Supporto.

## Software aggiuntivo richiesto

- Python 3.9 o successivo

- AutoLevels

Sulla maggior parte delle distribuzioni Linux, Python è già preinstallato. Per altri sistemi operativi, scaricalo da [Python.org](https://www.python.org/downloads/) o installalo tramite il tuo app store preferito. Assicurati di selezionare la casella "Add Python executable to PATH". Quindi, per installare AutoLevels, apri una shell (cmd su Windows) ed esegui:

```bash
pip install autolevels
```

Questo installerà automaticamente AutoLevels e le seguenti dipendenze:

- numpy
- pillow
- piexif
- opencv-python
- h5py
- onnxruntime

## Limitazioni

Le immagini RAW attualmente non sono supportate.

## Autore

Marius Wanko - marius.wanko@outlook.de

## Registro delle modifiche
