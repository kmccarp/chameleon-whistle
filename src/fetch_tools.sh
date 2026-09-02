#!/usr/bin/env bash
# Download retoc (MIT) and verify its checksum. Not vendored into the repo, so
# CI and fresh clones both fetch it the same way.
set -euo pipefail
cd "$(dirname "$0")/.."

RETOC_VERSION="v0.1.5"
RETOC_SHA256="cc036b06ad3bdcf7003690b00d82719980c374e48a95bf0654f9959148d263aa"
URL="https://github.com/trumank/retoc/releases/download/${RETOC_VERSION}/retoc_cli-x86_64-pc-windows-msvc.zip"

mkdir -p tools
if [ -x tools/retoc.exe ]; then
  echo "retoc already present: tools/retoc.exe"
  exit 0
fi

echo "Fetching retoc ${RETOC_VERSION}..."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/retoc.zip" "$URL"

actual=$(sha256sum "$tmp/retoc.zip" | cut -d' ' -f1)
if [ "$actual" != "$RETOC_SHA256" ]; then
  echo "CHECKSUM MISMATCH for retoc" >&2
  echo "  expected: $RETOC_SHA256" >&2
  echo "  actual:   $actual" >&2
  exit 1
fi
echo "checksum verified"

python -c "
import zipfile,sys,os
z=zipfile.ZipFile(sys.argv[1])
for n in ('retoc.exe','LICENSE'):
    open(os.path.join('tools',n),'wb').write(z.read(n))
" "$tmp/retoc.zip"
chmod +x tools/retoc.exe
echo "installed tools/retoc.exe"
