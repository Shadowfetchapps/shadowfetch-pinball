#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOME_DIR="${HOME}"
ICON_SRC="$ROOT/icon.svg"
HICOLOR="$HOME_DIR/.local/share/icons/hicolor"
APP_DIR="$HOME_DIR/.local/share/applications"
BIN_DIR="$HOME_DIR/.local/bin"
OPT_DIR="$HOME_DIR/.local/opt/shadowfetch-pinball"
SIZES=(16 22 24 32 48 64 128 256 512)
NAME="shadowfetch-pinball"

mkdir -p "$HICOLOR/scalable/apps" "$APP_DIR" "$BIN_DIR" "$OPT_DIR" \
	"$ROOT/assets/icons/hicolor/scalable/apps"
cp "$ICON_SRC" "$HICOLOR/scalable/apps/${NAME}.svg"
cp "$ICON_SRC" "$ROOT/assets/icons/${NAME}.svg"
cp "$ICON_SRC" "$ROOT/assets/icons/hicolor/scalable/apps/${NAME}.svg"
if ! command -v rsvg-convert >/dev/null 2>&1; then
	echo "Missing rsvg-convert. Install with: sudo apt install librsvg2-bin desktop-file-utils" >&2
else
	for sz in "${SIZES[@]}"; do
		mkdir -p "$HICOLOR/${sz}x${sz}/apps" "$ROOT/assets/icons/hicolor/${sz}x${sz}/apps"
		rsvg-convert -w "$sz" -h "$sz" "$ICON_SRC" -o "$HICOLOR/${sz}x${sz}/apps/${NAME}.png"
		cp "$HICOLOR/${sz}x${sz}/apps/${NAME}.png" "$ROOT/assets/icons/hicolor/${sz}x${sz}/apps/${NAME}.png"
	done
fi
SRC_BIN="$ROOT/export/linux/${NAME}.x86_64"
if [[ -x "$SRC_BIN" ]]; then
	cp -f "$SRC_BIN" "$OPT_DIR/${NAME}"
	chmod +x "$OPT_DIR/${NAME}"
	ln -sfn "$OPT_DIR/${NAME}" "$BIN_DIR/${NAME}"
else
	echo "Export the Linux build first: tools/export_linux.sh" >&2
	exit 1
fi
cat > "$APP_DIR/${NAME}.desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Shadowfetch Pinball
GenericName=Pinball
Comment=Original Shadowfetch pinball for Linux
Exec=${NAME}
TryExec=${NAME}
Icon=${NAME}
Terminal=false
Categories=Game;
Keywords=pinball;flipper;multiball;shadowfetch;
StartupNotify=true
StartupWMClass=Shadowfetch Pinball
EOF
if command -v desktop-file-validate >/dev/null 2>&1; then
	desktop-file-validate "$APP_DIR/${NAME}.desktop"
else
	echo "Missing desktop-file-validate. Install with: sudo apt install desktop-file-utils" >&2
fi
update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
echo "Installed Shadowfetch Pinball launcher: $BIN_DIR/${NAME}"
