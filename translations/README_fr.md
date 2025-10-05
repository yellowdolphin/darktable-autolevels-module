# autolevels

Un script Lua pour [darktable](https://www.darktable.org)

## Nom

autolevels.lua – correction automatique des couleurs avec _Courbe RVB_

## Description

Ce script appelle AutoLevels pour ajouter une instance de _Courbe RVB_ avec une correction colorimétrique de base.

[AutoLevels](https://github.com/yellowdolphin/autolevels) est un script Python pour le traitement par lots d'images, axé sur les photos analogiques numérisées avec des couleurs dégradées. Il utilise un modèle d'apprentissage automatique (ML) pour corriger automatiquement les couleurs délavées et restaurer un contraste acceptable pour l'affichage (espaces colorimétriques de sortie sRGB ou Adobe RGB). Ce modèle prédit des courbes pour les trois canaux de couleur, qui sont utilisées comme splines dans le module _Courbe RVB_ de darktable.

Ce script automatise la correction colorimétrique de base à l'aide de courbes RVB. Il n'ajoute ni étalonnage des couleurs ni « look » à l'image. Vous pouvez affiner les courbes manuellement si nécessaire. Toute autre retouche artistique doit être effectuée dans une instance de _Courbe RVB_ séparée.

## Utilisation

* Téléchargez [autolevels.lua](https://raw.githubusercontent.com/yellowdolphin/darktable-autolevels-module/master/autolevels.lua) et déplacez-le dans un sous-répertoire lua de votre répertoire de configuration darktable (par exemple `~/.config/darktable/lua/contrib/` sous Linux ou `%AppData%\darktable\lua\contrib\` sous Windows).

* Démarrez ce script dans le module _scripts_ dans la vue table lumineuse. Un module _AutoLevels_ apparaîtra dans le même panneau.

* Téléchargez le modèle de courbe ONNX [ici](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/v1.0.0rc/free_xcittiny_wa14.onnx) ou depuis la [page web RetroShine](https://retroshine.eu/download/free_xcittiny_wa14.onnx)

* Cliquez sur le petit bouton de navigation pour rechercher le fichier .onnx téléchargé

* Sélectionnez des images et appuyez sur le bouton « ajouter une courbe AutoLevels »

* Vous pouvez accélérer le traitement (jusqu'à 2x) en augmentant la *taille de lot* dans le module _AutoLevels_. Cela mettra à jour la progression et permettra l'arrêt uniquement après la fin de chaque lot.

* Dans la chambre noire, vous trouverez un nouvel élément d'historique qui ajoute une instance de _Courbe RVB_ en mode « RVB, canaux indépendants ». N'hésitez pas à apporter des ajustements aux courbes, les courbes d'origine resteront dans l'_historique_ jusqu'à ce que vous compressiez la pile d'historique.

Vous remarquerez que l'instance de _Courbe RVB_ créée par AutoLevels est appliquée juste avant le module _Profil couleur d'entrée_. C'est à cet endroit que la correction colorimétrique par canal fonctionne le plus efficacement pour les JPEG et la plupart des images HDR (les formats RAW ne sont pas encore pris en charge par le script). Si vous créez une nouvelle instance de _Courbe RVB_, celle-ci apparaîtra à l'emplacement habituel dans le pipeline.

### Ce qu'il fait

En coulisses, le script Lua appelle `autolevels` avec l'argument `--export darktable <version>` :

```
autolevels --model ~/Downloads/free_xcittiny_wa14.onnx --export darktable 5.3.0 --outsuffix .jpg.xmp -- myimage.jpg
```

AutoLevels lit le fichier XMP sidecar associé à chaque image sélectionnée (ou clone). Il est transmis via l'option `--outsuffix`. Si le fichier XMP n'existe pas, AutoLevels créera un fichier minimal avec les préréglages automatiques par défaut. L'option `--outsuffix` est facultative et empêche AutoLevels de créer une image de sortie si sa valeur se termine par « .xmp ».

Si vous souhaitez appeler AutoLevels avec l'option `--export darktable` en dehors de darktable, notez que darktable ne lit les fichiers XMP au démarrage que si vous avez activé l'option `Vérifier les fichiers XMP modifiès au démarrage` dans Préférences/Stockage.

## Logiciels supplémentaires requis

- Python 3.9 ou ultérieur

- AutoLevels

Sur la plupart des distributions Linux, Python est déjà préinstallé. Pour les autres systèmes d'exploitation, téléchargez-le depuis [Python.org](https://www.python.org/downloads/) ou installez-le via votre magasin d'applications préféré. Assurez-vous de cocher la case « Add Python executable to PATH ». Ensuite, pour installer AutoLevels, ouvrez un shell (cmd sous Windows) et exécutez :

```bash
pip install autolevels
```

Cela installera automatiquement AutoLevels et les dépendances suivantes :

- numpy
- pillow
- piexif
- opencv-python
- h5py
- onnxruntime

## Limitations

Les images RAW ne sont actuellement pas prises en charge.

## Auteur

Marius Wanko - marius.wanko@outlook.de

## Journal des modifications