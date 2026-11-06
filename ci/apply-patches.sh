#!/usr/bin/env bash
# Applies our patches to a pristine upstream orchestra-app checkout.
# Usage (from the orchestra-android repo root):
#   bash ci/apply-patches.sh [path-to-upstream-checkout]
# Default upstream path is ../orchestra-app (sibling of this repo),
# which is what app/build.gradle.kts expects.
# Pinned upstream commit: 39945ca8 (see PATCHES.md — 827fb10 was a local-only
# merge commit; 39945ca8 is the same state on the remote).
# Every patch is verified after applying; the script fails loudly on mismatch.
set -euo pipefail

UPSTREAM="${1:-../orchestra-app}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "apply-patches: FAIL: $*" >&2; exit 1; }

[ -d "$UPSTREAM" ] || fail "upstream checkout not found: $UPSTREAM"
[ -f "$UPSTREAM/package.json" ] || fail "not an orchestra-app checkout: $UPSTREAM"

# 1. Photon-node: drop the patched dependency + its patch file (breaks bun install).
sed -i '/photon-node/d' "$UPSTREAM/package.json"
rm -f "$UPSTREAM/patches/@silvia-odwyer%2Fphoton-node@0.3.4.patch"
grep -q photon "$UPSTREAM/package.json" && fail "photon still in package.json"
[ -e "$UPSTREAM/patches/@silvia-odwyer%2Fphoton-node@0.3.4.patch" ] && fail "photon patch file still there"

# 2. _assets -> webassets: AGP silently drops asset folders starting with "_".
sed -i 's/assetsDir: "_assets"/assetsDir: "webassets"/' "$UPSTREAM/packages/app/vite.config.ts"
grep -q 'assetsDir: "webassets"' "$UPSTREAM/packages/app/vite.config.ts" || fail "vite.config.ts assetsDir not patched"
sed -i 's/(?:_assets|assets)/(?:webassets|assets)/' "$UPSTREAM/packages/app/vite.pwa.ts"
grep -q '(?:webassets|assets)' "$UPSTREAM/packages/app/vite.pwa.ts" || fail "vite.pwa.ts denylist not patched"

# 3. Mobile overrides (v2.2): the CSS file + its import + dvh fallback on #root.
cp "$REPO_ROOT/ci/mobile-overrides.css" "$UPSTREAM/packages/app/src/mobile-overrides.css"
CSS="$UPSTREAM/packages/app/src/index.css"
grep -q 'mobile-overrides' "$CSS" || sed -i '4a @import "./mobile-overrides.css";' "$CSS"
grep -q '@import "./mobile-overrides.css";' "$CSS" || fail "mobile-overrides import missing"
# Add `height: 100dvh;` after every `height: 100vh;` (exactly 2 in #root blocks),
# keeping each line's own indentation. Skip if already applied.
if ! grep -q 'height: 100dvh;' "$CSS"; then
  # NOTE: [ \t]* — not \s* — or the trailing newline gets eaten and the
  # next line (the closing brace) joins the new dvh line.
  perl -i -pe 's/^(\s*)height: 100vh;[ \t]*$/$1height: 100vh;\n$1height: 100dvh;/' "$CSS"
fi
[ "$(grep -c 'height: 100dvh;' "$CSS")" -eq 2 ] || fail "expected 2 dvh lines in index.css"
[ -f "$UPSTREAM/packages/app/src/mobile-overrides.css" ] || fail "mobile-overrides.css not copied"

echo "apply-patches: OK ($UPSTREAM)"
