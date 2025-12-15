#!/usr/bin/env bash
set -e

APP="$1"
BREW_PREFIX="/usr/local/opt"

if [[ ! -d "$APP" ]]; then
  echo "❌ App nicht gefunden: $APP"
  exit 1
fi

BIN="$APP/Contents/MacOS/mscore"
FW="$APP/Contents/Frameworks"

mkdir -p "$FW"

echo "📦 Bundling dylibs for:"
echo "   $APP"

# Alle Homebrew-Dylibs sammeln
collect_libs() {
  otool -L "$1" | awk '{print $1}' | grep "$BREW_PREFIX" || true
}

queue=("$BIN")
processed=()

while [[ ${#queue[@]} -gt 0 ]]; do
  current="${queue[0]}"
  queue=("${queue[@]:1}")

  for lib in $(collect_libs "$current"); do
    base=$(basename "$lib")
    target="$FW/$base"

    if [[ ! -f "$target" ]]; then
      echo "➡️  Kopiere $base"
      cp "$lib" "$target"
      chmod 644 "$target"

      queue+=("$target")
    fi

    install_name_tool -change "$lib" "@rpath/$base" "$current"
  done

  processed+=("$current")
done

# RPATH setzen
install_name_tool -add_rpath \
  @executable_path/../Frameworks \
  "$BIN" || true

echo "✅ DYLIB-Bundling abgeschlossen"
