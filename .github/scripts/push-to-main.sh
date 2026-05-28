#!/usr/bin/env bash
# Fast path: patches sanity check passed → commit submodule bump directly to
# main + push tag. Driven by RELEASE_TOKEN PAT so the push event triggers
# release.yml downstream (default GITHUB_TOKEN pushes don't fire other
# workflows by design).

set -euo pipefail

git config user.name "hermes-desktop-bot"
git config user.email "hermes-desktop-bot@users.noreply.github.com"

# Make sure remote auth uses the PAT (RELEASE_TOKEN exposed as GH_TOKEN).
git remote set-url origin "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

# Commit the staged submodule pointer + version bump.
git add -A
cat > /tmp/commit-msg.txt <<EOF
chore(deps): bump hermes-web-ui to ${NEW_SHA:0:12}

Auto-sync from upstream (${COMMIT_COUNT} commit(s)). Patches sanity
check passed, fast-pathed straight to main.

- ${OLD_SHA} → ${NEW_SHA}
- v${OLD_VER} → v${NEW_VER}
EOF
git commit -F /tmp/commit-msg.txt

git push origin main

# Tag and push — release.yml is triggered on tag push matching v*.
TAG="v${NEW_VER}"
git tag -a "$TAG" -m "Automated release $TAG"
git push origin "$TAG"

echo "✓ Pushed commit + $TAG. release.yml will pick it up."
