#!/usr/bin/env bash
# Rebuild the shareable zip from dist/, previews/ and src/.
#   bash src/make_package.sh [version]
# Version defaults to "dev"; CI passes the release tag.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=${1:-dev}
ZIP="MecchaChameleon-LowFreqYell-${VERSION}.zip"

[ -d dist ] || { echo "No dist/ - nothing to package." >&2; exit 1; }
[ -x tools/retoc.exe ] || bash src/fetch_tools.sh

rm -rf package && mkdir -p package/mods package/previews package/source/tools
for v in $(ls -1 dist); do
  mkdir -p "package/mods/$v"
  cp dist/"$v"/* "package/mods/$v/"
done
cp previews/*.wav package/previews/
cp src/make_audio.py src/build_mod.py src/build_all.sh src/fetch_tools.sh \
   src/install.sh src/uninstall.sh src/status.sh src/make_package.sh package/source/
cp README.md package/source/README.md
cp tools/retoc.exe tools/LICENSE package/source/tools/
cp dist_files/* package/

VERSION="$VERSION" ZIP="$ZIP" python - <<'PY'
import zipfile, os, hashlib
root, zipname, version = "package", os.environ["ZIP"], os.environ["VERSION"]
lines = ["SHA256 checksums for the installable mod files",
         "package version: %s" % version, "=" * 46, ""]
for v in sorted(os.listdir(os.path.join(root, "mods"))):
    lines.append(v)
    for f in sorted(os.listdir(os.path.join(root, "mods", v))):
        p = os.path.join(root, "mods", v, f)
        lines.append("  %s  %s" % (hashlib.sha256(open(p, 'rb').read()).hexdigest(), f))
    lines.append("")
open(os.path.join(root, "CHECKSUMS.txt"), "w").write("\n".join(lines))

n = 0
with zipfile.ZipFile(zipname, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for dp, dn, fn in os.walk(root):
        for f in sorted(fn):
            full = os.path.join(dp, f)
            z.write(full, os.path.relpath(full, root))
            n += 1
print("created %s (%d files, %.1f MB)" % (zipname, n, os.path.getsize(zipname) / 1e6))
PY
