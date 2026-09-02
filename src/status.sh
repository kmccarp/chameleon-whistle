#!/usr/bin/env bash
# Report which variant is currently installed.
set -uo pipefail
cd "$(dirname "$0")/.."
GAME=${GAME:-"C:/Program Files (x86)/Steam/steamapps/common/MECCHA CHAMELEON"}
PAKS="$GAME/Chameleon/Content/Paks"
[ -e "$PAKS/zzz_ChameleonYell_P.utoc" ] || { echo "Mod is not installed."; exit 0; }
for f in utoc ucas pak; do
  m="(unknown)"
  for v in $(ls -1 dist 2>/dev/null); do
    cmp -s "dist/$v/zzz_ChameleonYell_P.$f" "$PAKS/zzz_ChameleonYell_P.$f" && { m="$v"; break; }
  done
  printf "  %-5s %s\n" "$f" "$m"
done
echo "(.pak is identical across variants, so .utoc/.ucas decide what you hear)"
