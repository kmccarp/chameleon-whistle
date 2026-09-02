#!/usr/bin/env bash
# Install a built variant into the game's Paks folder.
#   bash src/install.sh A_male_scream
#
# Refuses to copy anything unless every target file is writable, so a locked
# file (usually: the game is running) can never leave a half-swapped set.
set -euo pipefail
cd "$(dirname "$0")/.."
VARIANT=${1:-A_male_scream}
GAME=${GAME:-"C:/Program Files (x86)/Steam/steamapps/common/MECCHA CHAMELEON"}
PAKS="$GAME/Chameleon/Content/Paks"

[ -d "dist/$VARIANT" ] || {
  echo "No such variant: $VARIANT" >&2
  echo "Available:" >&2; ls -1 dist | sed 's/^/  /' >&2
  exit 1
}
[ -d "$PAKS" ] || { echo "Game not found: $PAKS" >&2; exit 1; }

# Pre-flight: every existing target must be replaceable before we touch any of them.
locked=""
for f in dist/"$VARIANT"/zzz_ChameleonYell_P.*; do
  t="$PAKS/$(basename "$f")"
  [ -e "$t" ] || continue
  # opening for append is enough to detect a Windows share-lock
  (exec 3>>"$t") 2>/dev/null || locked="$locked $(basename "$t")"
done
if [ -n "$locked" ]; then
  echo "Cannot install: file(s) in use ->$locked" >&2
  echo "MECCHA CHAMELEON is almost certainly running. Quit the game, then re-run." >&2
  echo "Nothing was changed; your current install is untouched." >&2
  exit 1
fi

for f in dist/"$VARIANT"/zzz_ChameleonYell_P.*; do cp "$f" "$PAKS/"; done

# Verify what actually landed.
for f in dist/"$VARIANT"/zzz_ChameleonYell_P.*; do
  cmp -s "$f" "$PAKS/$(basename "$f")" || { echo "Verify FAILED: $(basename "$f")" >&2; exit 1; }
done
echo "Installed '$VARIANT' (all files verified). Remove with: bash src/uninstall.sh"
