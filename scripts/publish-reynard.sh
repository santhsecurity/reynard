#!/usr/bin/env bash
#
# publish-reynard.sh — reproducibly publish the reynard product tree to the
# public repository (github.com/santhsecurity/reynard).
#
# Replaces the by-hand export done on 2026-06-06. It exports the COMMITTED tree
# (HEAD — working-tree WIP is intentionally excluded), strips the
# non-redistributable OS font payloads, and pushes the result as a normal delta
# on the public repo's history (no force-push, so history + diffs are preserved).
#
# A FAIL-CLOSED legal gate refuses to publish if ANY font payload survived the
# strip — so a future tree change can never silently leak a proprietary font to
# the public repo.
#
#   scripts/publish-reynard.sh --dry-run   # build + verify the export, do NOT push
#   scripts/publish-reynard.sh             # build, verify, and push to main
#
# Env:
#   REYNARD_PUBLIC_REMOTE  override the push target (default santhsecurity/reynard)
set -euo pipefail

PUBLIC_REMOTE="${REYNARD_PUBLIC_REMOTE:-https://github.com/santhsecurity/reynard.git}"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

STAGING="$(git rev-parse --show-toplevel)"
cd "$STAGING"
HEAD_SHA="$(git rev-parse --short HEAD)"
HEAD_SUBJECT="$(git log -1 --pretty=%s)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/reynard-publish.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
EXPORT="$WORK/export"
mkdir -p "$EXPORT"

echo "==> exporting committed tree at HEAD $HEAD_SHA (\"$HEAD_SUBJECT\")"
git archive HEAD | tar -x -C "$EXPORT"

# --- Strip non-redistributable OS font payloads -----------------------------
# Established policy: the public repo ships ZERO font files. They are proprietary
# vendor fonts (macOS/Windows Segoe, Tor-Browser Linux sets, extensionless
# Multiple-Master fonts like TimesLTMM) supplied from an upstream Camoufox
# release at build time. Strip BOTH:
#   (a) everything under bundle/fonts/ except the README + regeneration recipe
#       (catches the extensionless MM fonts a suffix filter would miss), and
#   (b) every .ttf/.ttc/.otf/.dfont ANYWHERE else (e.g. the Segoe fonts in
#       pythonlib/camoufox/gui/assets/ — outside bundle/fonts/).
if [ -d "$EXPORT/bundle/fonts" ]; then
  find "$EXPORT/bundle/fonts" -mindepth 1 -type f \
    ! -name '000_README.txt' ! -name 'cleanfonts.sh' -delete
fi
find "$EXPORT" -type f \
  \( -iname '*.ttf' -o -iname '*.ttc' -o -iname '*.otf' -o -iname '*.dfont' \) -delete
find "$EXPORT/bundle/fonts" -mindepth 1 -type d -empty -delete 2>/dev/null || true

# --- Strip editor / OS junk that should never be published -------------------
find "$EXPORT" -type f \
  \( -name '.DS_Store' -o -name 'Thumbs.db' -o -name '*.pyc' -o -name '*.old' \) -delete 2>/dev/null || true
find "$EXPORT" -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true

# --- FAIL-CLOSED legal gate -------------------------------------------------
# Refuse to publish if any font payload survived, by extension OR by living
# under bundle/fonts/ (minus the two allowed text files).
LEAK="$(find "$EXPORT" -type f \
  \( -iname '*.ttf' -o -iname '*.ttc' -o -iname '*.otf' -o -iname '*.dfont' \
     -o -path '*/bundle/fonts/*' \) \
  ! -name '000_README.txt' ! -name 'cleanfonts.sh' 2>/dev/null || true)"
if [ -n "$LEAK" ]; then
  echo "ABORT: non-redistributable font payload survived the strip:" >&2
  printf '%s\n' "$LEAK" | head >&2
  exit 3
fi

# --- Sanity bounds ----------------------------------------------------------
FILES="$(find "$EXPORT" -type f | wc -l | tr -d ' ')"
SIZE_KB="$(du -sk "$EXPORT" | cut -f1)"
echo "==> export: $FILES files, ${SIZE_KB} KB (fonts stripped)"
if [ "$SIZE_KB" -gt 51200 ]; then
  echo "ABORT: export is ${SIZE_KB} KB (>50 MB) — the Firefox source or fonts likely leaked in." >&2
  exit 4
fi
for required in NOTICE REYNARD.md LICENSE README.md patches additions; do
  if [ ! -e "$EXPORT/$required" ]; then
    echo "ABORT: export is missing expected product entry: $required" >&2
    exit 5
  fi
done

if [ "$DRY_RUN" = 1 ]; then
  echo "==> DRY RUN — verified export at $EXPORT (NOT pushed)"
  trap - EXIT   # keep the export around for inspection
  echo "    inspect: $EXPORT"
  exit 0
fi

# --- Publish as a delta on the public repo's history ------------------------
echo "==> cloning $PUBLIC_REMOTE"
PUB="$WORK/public"
git clone --depth 1 "$PUBLIC_REMOTE" "$PUB"

# Replace tracked content (keep .git) with the fresh export.
( cd "$PUB" && git ls-files -z | xargs -0 -r rm -f )
cp -a "$EXPORT/." "$PUB/"

cd "$PUB"
git add -A
if git diff --cached --quiet; then
  echo "==> public repo already matches HEAD $HEAD_SHA — nothing to publish"
  exit 0
fi
echo "==> changes to publish:"
git diff --cached --stat | tail -20
git commit -q -m "reynard: sync engine tree from staging $HEAD_SHA"
git push origin HEAD:main
echo "==> published HEAD $HEAD_SHA to $PUBLIC_REMOTE (main)"
