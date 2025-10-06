# autolevels

Um script Lua para [darktable](https://www.darktable.org)

## Nome

autolevels.lua — correção automática de cores usando _rgb curve_

## Descrição

Este script chama o AutoLevels para adicionar uma instância de _rgb curve_ com uma correção de cores básica.

[AutoLevels](https://github.com/yellowdolphin/autolevels) é um script Python para processamento em lote de imagens com foco em fotos analógicas digitalizadas com cores degradadas. Ele usa um modelo de aprendizado de máquina (ML) para corrigir automaticamente cores desbotadas e restaurar o contraste aceitável para exibição (espaços de cor de saída sRGB ou Adobe RGB). Este modelo prevê curvas para os três canais de cor, que são usadas como splines no módulo _rgb curve_ do darktable.

Este script automatiza a correção básica de cores usando curvas RGB. Ele não adiciona nenhuma gradação de cor ou "visual" à imagem. Você pode ajustar as curvas manualmente, se necessário. Qualquer edição artística adicional deve ser feita em uma instância separada de _rgb curve_.

## Instalação

Baixe [autolevels.zip](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/nightly/autolevels-nightly.zip) e extraia-o dentro de uma subpasta lua no seu diretório de configuração do darktable (por exemplo, `~/.config/darktable/lua/contrib/` no Linux ou `%AppData%\darktable\lua\contrib\` no Windows).

## Uso

* Inicie este script no módulo _scripts_ na visualização de mesa de luz. Um módulo _AutoLevels_ aparecerá no mesmo painel.

* Baixe o modelo de curva ONNX [aqui](https://github.com/yellowdolphin/darktable-autolevels-module/releases/download/v1.0.0rc/free_xcittiny_wa14.onnx) ou na [página do RetroShine](https://retroshine.eu/download/free_xcittiny_wa14.onnx)

* Clique no pequeno botão do navegador de arquivos para procurar o arquivo .onnx baixado

* Selecione as imagens e pressione o botão "adicionar curva AutoLevels"

* Você pode acelerar o processamento (até 2x) aumentando o *tamanho do lote* no módulo _AutoLevels_. Isso atualizará o progresso e permitirá a interrupção somente após a conclusão de cada lote.

* Na cuarto escuro, você encontrará um novo item de historial que adiciona uma instância de _rgb curve_ no modo "RGB, independent channels". Sinta-se à vontade para fazer ajustes nas curvas; as curvas originais permanecerão no _historial_ até você comprimir o historial de ações.

Você notará que a instância de _rgb curve_ criada pelo AutoLevels é aplicada logo antes do módulo _perfil de cor de entrada_. É aqui que a correção de cores por canal funciona de forma mais eficaz para JPEGs e a maioria das imagens HDR (formatos RAW ainda não são suportados pelo script). Se você criar uma nova instância de _rgb curve_, ela aparecerá no local habitual do pipeline.

### O que ele faz

Nos bastidores, o script Lua chama `autolevels` com o argumento `--export darktable <versão>`:

```
autolevels --model ~/Downloads/free_xcittiny_wa14.onnx --export darktable 5.3.0 --outsuffix .jpg.xmp -- myimage.jpg
```

O AutoLevels lê o arquivo sidecar XMP associado a cada imagem selecionada (ou duplicata). Ele é passado através da opção `--outsuffix`. Se o arquivo XMP não existir, o AutoLevels criará um arquivo mínimo com as predefinições de aplicação automática padrão. A opção `--outsuffix` é opcional e impede que o AutoLevels crie uma imagem de saída se seu valor terminar com ".xmp".

Se você quiser chamar o AutoLevels com a opção `--export darktable` fora do darktable, observe que o darktable só lê arquivos XMP na inicialização se você tiver ativado a opção `look for updated XMP files on startup` nas preferências/storage.

## Software adicional necessário

- Python 3.9 ou posterior

- AutoLevels

Na maioria das distribuições Linux, o Python já está pré-instalado. Para outros sistemas operacionais, baixe-o em [Python.org](https://www.python.org/downloads/) ou instale-o através da sua loja de aplicativos favorita. Certifique-se de marcar a caixa de seleção "Add Python executable to PATH". Em seguida, para instalar o AutoLevels, abra um terminal (cmd no Windows) e execute:

```bash
pip install autolevels
```

Isso instalará automaticamente o AutoLevels e as seguintes dependências:

- numpy
- pillow
- piexif
- opencv-python
- h5py
- onnxruntime

## Limitações

Imagens RAW não são suportadas atualmente.

## Autor

Marius Wanko - marius.wanko@outlook.de

## Registro de alterações