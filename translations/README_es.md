# autolevels

Un script de Lua para [darktable](https://www.darktable.org)

## Nombre

autolevels.lua - corrección automática de color usando _curva rgb_

## Descripción

Este script llama a AutoLevels para añadir una instancia de _curva rgb_ con una corrección de color básica.

[AutoLevels](https://github.com/yellowdolphin/autolevels) es un script de Python para el procesamiento por lotes de imágenes con enfoque en fotografías analógicas escaneadas con colores degradados. Utiliza un modelo de aprendizaje automático (ML) para corregir automáticamente los colores desteñidos y restaurar un contraste aceptable para visualización (perfil de color de salida sRGB o Adobe RGB). Este modelo predice curvas para los tres canales de color, que se utilizan como splines en el módulo _curva rgb_ de darktable.

Este script automatiza la corrección básica de color usando curvas RGB. No añade ninguna gradación de color o "look" a la imagen. Puedes ajustar las curvas manualmente si es necesario. Cualquier edición artística adicional debe realizarse en una instancia separada de _curva rgb_.

## Uso

* Descarga [autolevels.lua](https://raw.githubusercontent.com/yellowdolphin/darktable-autolevels-module/master/autolevels.lua) y muévelo a una subcarpeta lua en el directorio de configuración de darktable (por ejemplo, ~/.config/darktable/lua/contrib/ en Linux o %AppData%\darktable\lua\contrib\ en Windows).

* Inicia este script en el módulo _scripts_ en la vista de mesa de luz. Un módulo _AutoLevels_ aparecerá en el mismo panel.

* Descarga el modelo de curva ONNX [aquí](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/v1.0.0rc/free_xcittiny_wa14.onnx)

* Haz clic en el pequeño botón del explorador de archivos para buscar el archivo .onnx descargado

* Selecciona las imágenes y presiona el botón "añadir curva AutoLevels"

* Puedes acelerar el procesamiento (hasta 2x) aumentando el *tamaño de lote* en el módulo _AutoLevels_. Esto actualizará el progreso y permitirá detener solo después de que se complete cada lote.

* En el cuarto oscuro, encontrarás un nuevo elemento del historial que añade una instancia de _curva rgb_ en modo "canales independientes RGB". Siéntete libre de hacer ajustes a las curvas, las curvas originales permanecerán en el _historial_ hasta que comprimas el historial de acciones.

Podrías notar que la instancia de _curva rgb_ creada por AutoLevels se aplica justo antes del módulo _perfil de color de entrada_. Este es el lugar donde la corrección de color por canales funciona más efectivamente para JPEGs y la mayoría de imágenes HDR (los formatos RAW aún no son compatibles con el script). Si creas una nueva instancia de _curva rgb_, esta aparecerá en el lugar habitual en el pipeline.

### Qué hace

Internamente, el script de Lua llama a `autolevels` con el argumento `--export darktable <versión>`:

```
autolevels --model ~/Downloads/free_xcittiny_wa14.onnx --export darktable 5.3.0 --outsuffix .jpg.xmp -- ejemplo.jpg
```

AutoLevels lee el archivo XMP asociado con cada imagen seleccionada (o duplicado). Se pasa a través de la opción `--outsuffix`. Si el archivo XMP no existe, AutoLevels creará uno mínimo con los preajustes de aplicación automática predeterminados. La opción `--outsuffix` es opcional y evita que AutoLevels cree una imagen de salida si su valor termina con ".xmp".

Si quieres llamar a AutoLevels con la opción `--export darktable` fuera de darktable, ten en cuenta que darktable solo lee archivos XMP de las imágenes importadas previamente si has activado la opción `Buscar archivos XMP actualizados al iniciar` en preferencias/almacenamiento.

## Software adicional requerido

- Python 3.9 o posterior

- AutoLevels

En la mayoría de distribuciones de Linux, Python ya viene preinstalado. Para otros sistemas operativos, descárgalo desde [Python.org](https://www.python.org/downloads/) o instálalo a través de tu tienda de aplicaciones favorita. Asegúrate de marcar la casilla "Add Python executable to PATH". Luego, para instalar AutoLevels, abre una terminal (cmd en Windows) y ejecuta:

```bash
pip install autolevels
```

Esto instalará automáticamente AutoLevels y las siguientes dependencias:

- numpy
- pillow
- piexif
- opencv-python
- h5py
- onnxruntime

## Limitaciones

Las imágenes RAW actualmente no son compatibles.

## Autor

Marius Wanko - marius.wanko@outlook.de

## Registro de cambios