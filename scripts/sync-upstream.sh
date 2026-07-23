#!/usr/bin/env bash
# Sync the Vent/Mio Chat fork with upstream FluffyChat, low-conflict.
#
#   1. Fast-forward local `main` to upstream/main (pristine mirror — never commit there).
#   2. Merge `main` into `vent` (our integration branch) so conflicts stay small & frequent.
#
# Usage: ./scripts/sync-upstream.sh   (run from the fork root, clean working tree)
set -euo pipefail

if [[ -n "$(git status --porcelain)" ]]; then
  echo "✋ Working tree not clean. Commit or stash first." >&2
  exit 1
fi

echo "▶ Fetching upstream…"
git fetch upstream --prune

echo "▶ Fast-forwarding main → upstream/main…"
git checkout main
git merge --ff-only upstream/main

echo "▶ Merging main into vent…"
git checkout vent
if git merge --no-edit main; then
  echo "✅ Synced. Review the diff, run 'flutter analyze', then push:  git push origin vent"
else
  echo "⚠️  Merge conflicts. Resolve them (see VENT_CHANGES.md for the customization map),"
  echo "    then: git commit && flutter analyze"
  exit 1
fi
