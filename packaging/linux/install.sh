#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.local/opt/ps2-store"
mkdir -p "$DEST" "$HOME/.local/share/applications" "$HOME/.local/share/icons/hicolor/256x256/apps"
cp -a "$HERE"/. "$DEST"/
cp "$DEST/ps2-store.png" "$HOME/.local/share/icons/hicolor/256x256/apps/ps2-store.png"
sed "s|^Exec=.*|Exec=$DEST/ps2_store|" "$DEST/ps2-store.desktop" > "$HOME/.local/share/applications/ps2-store.desktop"
echo "PS2 Store instalado no menu de aplicativos."
