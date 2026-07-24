#!/bin/bash
# script para generar AppIcon.icns a partir de favicon.ico o png
set -e

MAC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONSET_DIR="$MAC_DIR/AppIcon.iconset"

mkdir -p "$ICONSET_DIR"

# Si existe un PNG de origen en el repositorio
SRC_PNG="$MAC_DIR/../logo-texto-blanco.png"
if [ ! -f "$SRC_PNG" ]; then
    SRC_PNG="$MAC_DIR/../favicon.ico"
fi

if [ -f "$SRC_PNG" ]; then
    # Usar sips para generar todas las resoluciones requeridas por Apple
    sips -z 16 16     "$SRC_PNG" --out "$ICONSET_DIR/icon_16x16.png"
    sips -z 32 32     "$SRC_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png"
    sips -z 32 32     "$SRC_PNG" --out "$ICONSET_DIR/icon_32x32.png"
    sips -z 64 64     "$SRC_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png"
    sips -z 128 128   "$SRC_PNG" --out "$ICONSET_DIR/icon_128x128.png"
    sips -z 256 256   "$SRC_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png"
    sips -z 256 256   "$SRC_PNG" --out "$ICONSET_DIR/icon_256x256.png"
    sips -z 512 512   "$SRC_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png"
    sips -z 512 512   "$SRC_PNG" --out "$ICONSET_DIR/icon_512x512.png"
    sips -z 1024 1024 "$SRC_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png"

    iconutil -c icns "$ICONSET_DIR" -o "$MAC_DIR/AppIcon.icns"
    rm -rf "$ICONSET_DIR"
    echo "AppIcon.icns generado con éxito."
fi
