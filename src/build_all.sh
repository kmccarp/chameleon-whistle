#!/usr/bin/env bash
# Build every yell variant into dist/ as an installable UE5 IoStore mod.
#
# Step 0 extracts the stock SoundWave from YOUR game install (nothing from the
# game is vendored into this repo); steps 1-2 rebuild and repack it.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$(pwd)
GAME=${GAME:-"C:/Program Files (x86)/Steam/steamapps/common/MECCHA CHAMELEON"}
PAKS="$GAME/Chameleon/Content/Paks"
RETOC="$ROOT/tools/retoc.exe"
ASSET="freesound_community-wolf-whistle-6777"

[ -d "$PAKS" ] || { echo "Game not found at: $GAME" >&2; echo "Set GAME=... to override." >&2; exit 1; }

echo "=== extracting stock asset from game install ==="
rm -rf original dist build; mkdir -p original dist build
"$RETOC" to-legacy -f "$ASSET" --no-shaders "$PAKS" original

for wav in previews/[A-D]_*.wav; do
  name=$(basename "$wav" .wav)
  case "$name" in *_AS-YOU-HEAR-IT) continue;; esac
  echo "=== $name ==="
  python src/build_mod.py "$wav" "build/$name"
  cp original/scriptobjects.bin "build/$name/"
  mkdir -p "dist/$name"
  "$RETOC" to-zen --version UE5_6 "build/$name" "dist/$name/zzz_ChameleonYell_P.utoc"
done
echo; echo "Built variants:"; ls -1 dist
