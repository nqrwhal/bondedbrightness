#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-}"

if [[ -z "$TAG" ]]; then
  echo "usage: $0 <tag>" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DMG_NAME="BondedBrightness-${TAG}.dmg"
"$ROOT_DIR/script/create_dmg.sh"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required to upload the release artifact." >&2
  exit 1
fi

gh release create "$TAG" "$DMG_NAME" \
  --title "$TAG" \
  --notes-file <(git log --format=%B -n 1 "$TAG" 2>/dev/null || printf '%s\n' "BondedBrightness $TAG")
