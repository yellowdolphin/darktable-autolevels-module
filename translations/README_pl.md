# autolevels

Skrypt Lua dla [darktable](https://www.darktable.org)

## Nazwa

autolevels.lua – automatyczna korekcja kolorów przy użyciu _krzywa RGB_

## Opis

Ten skrypt wywołuje AutoLevels w celu dodania instancji _krzywa RGB_ z podstawową korekcją kolorów.

[AutoLevels](https://github.com/yellowdolphin/autolevels) to skrypt Pythona do wsadowego przetwarzania obrazów, skoncentrowany na zeskanowanych zdjęciach analogowych z wyblakłymi kolorami. Wykorzystuje model uczenia maszynowego (ML) do automatycznej korekcji wyblakłych kolorów i przywrócenia kontrastu akceptowalnego do wyświetlania (w przestrzeni kolorów sRGB lub Adobe RGB). Model ten przewiduje krzywe dla trzech kanałów kolorów, które są używane jako splajny w module _krzywa rgb_ darktable.

Ten skrypt automatyzuje podstawową korekcję kolorów przy użyciu krzywych RGB. Nie dodaje żadnej gradacji kolorów ani „stylu" do obrazu. W razie potrzeby możesz ręcznie dostroić krzywe. Wszelkie dalsze edycje artystyczne powinny być wykonywane w oddzielnej instancji _krzywa RGB_.

## Użytkowanie

* Pobierz [autolevels.lua](https://raw.githubusercontent.com/yellowdolphin/darktable-autolevels-module/master/autolevels.lua) i przenieś go do podfolderu lua w katalogu konfiguracyjnym darktable (np. `~/.config/darktable/lua/contrib/` w systemie Linux lub `%AppData%\darktable\lua\contrib\` w systemie Windows).

* Uruchom ten skrypt w module _skrypty_ w widoku stosu zdjęć. Moduł _AutoLevels_ pojawi się w tym samym panelu.

* Pobierz model krzywej ONNX [tutaj](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/v1.0.0rc/free_xcittiny_wa14.onnx) lub ze [strony RetroShine](https://retroshine.eu/download/free_xcittiny_wa14.onnx)

* Kliknij małą ikonę przeglądarki plików, aby wyszukać pobrany plik .onnx

* Zaznacz obrazy i naciśnij przycisk „dodaj krzywą AutoLevels"

* Możesz przyspieszyć przetwarzanie (do 2x), zwiększając *rozmiar partii* w module _AutoLevels_. Spowoduje to aktualizację postępu i umożliwi zatrzymanie dopiero po zakończeniu każdego partii.

* W ciemni znajdziesz nową pozycję historii, która dodaje instancję _krzywa RGB_ w trybie „RGB, niezależne kanały". Możesz swobodnie wprowadzać zmiany w krzywych, oryginalne krzywe pozostaną w _historia_ do momentu skompresowania stosu historii.

Możesz zauważyć, że instancja _krzywa RGB_ utworzona przez AutoLevels jest stosowana tuż przed modułem _wejściowy profil koloru_. To miejsce, w którym korekcja kolorów dla poszczególnych kanałów działa najskuteczniej w przypadku plików JPEG i większości obrazów HDR (formaty RAW nie są jeszcze obsługiwane przez skrypt). Jeśli utworzysz nową instancję _krzywa RGB_, pojawi się ona w zwykłym miejscu w potoku.

### Co robi

Pod maską skrypt Lua wywołuje `autolevels` z argumentem `--export darktable <version>`:

```
autolevels --model ~/Downloads/free_xcittiny_wa14.onnx --export darktable 5.3.0 --outsuffix .jpg.xmp -- myimage.jpg
```

AutoLevels odczytuje plik dodatkowy XMP powiązany z każdym zaznaczonym obrazem (lub duplikatem). Jest on przekazywany przez opcję `--outsuffix`. Jeśli plik XMP nie istnieje, AutoLevels utworzy minimalny plik z domyślnymi automatycznie stosowanymi ustawieniami wstępnymi. Opcja `--outsuffix` jest opcjonalna i zapobiega tworzeniu przez AutoLevels obrazu wyjściowego, jeśli jej wartość kończy się na „.xmp".

Jeśli chcesz wywołać AutoLevels z opcją `--export darktable` poza darktable, pamiętaj, że darktable odczytuje pliki XMP przy uruchomieniu tylko wtedy, gdy aktywowałeś opcję `wyszukuj zaktualizowane pliki XMP przy starcie` w ustawienia/miejsca.

## Wymagane dodatkowe oprogramowanie

- Python 3.9 lub nowszy

- AutoLevels

W większości dystrybucji Linuksa Python jest już preinstalowany. W przypadku innych systemów operacyjnych pobierz go z [Python.org](https://www.python.org/downloads/) lub zainstaluj za pośrednictwem ulubionego sklepu z aplikacjami. Upewnij się, że zaznaczyłeś pole wyboru „Add Python executable to PATH". Następnie, aby zainstalować AutoLevels, otwórz powłokę (cmd w systemie Windows) i wykonaj:

```bash
pip install autolevels
```

Spowoduje to automatyczną instalację AutoLevels i następujących zależności:

- numpy
- pillow
- piexif
- opencv-python
- h5py
- onnxruntime

## Ograniczenia

Obrazy RAW nie są obecnie obsługiwane.

## Autor

Marius Wanko - marius.wanko@outlook.de

## Dziennik zmian