#!/usr/bin/env bash
# Remove the mod. Only deletes files this mod added; stock files are untouched.
set -euo pipefail
GAME=${GAME:-"C:/Program Files (x86)/Steam/steamapps/common/MECCHA CHAMELEON"}
PAKS="$GAME/Chameleon/Content/Paks"
n=0
for f in "$PAKS"/zzz_ChameleonYell_P.*; do
  [ -e "$f" ] || continue
  rm -v "$f"; n=$((n+1))
done
[ "$n" -gt 0 ] && echo "Mod removed." || echo "Mod was not installed."
