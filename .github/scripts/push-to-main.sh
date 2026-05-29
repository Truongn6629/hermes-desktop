#!/usr/bin/env bash
# Fast path: patches sanity check passed → commit upstream bumps directly to
# main + push tag. Driven by RELEASE_TOKEN PAT so the push event triggers
# release.yml downstream (default GITHUB_TOKEN pushes don't fire other
# workflows by design).
#
# Inputs come via env: any combination of web-ui (npm) and hermes-agent
# (PyPI) may have moved this run — message and title text are conditional.

set -euo pipefail

git config user.name "hermes-desktop-bot"
git config user.email "hermes-desktop-bot@users.noreply.github.com"

# Make sure remote auth uses the PAT (RELEASE_TOKEN exposed as GH_TOKEN).
git remote set-url origin "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

# Compose a commit subject + body that reflects what actually changed.
SUBJECT_PARTS=()
BODY_LINES=()
if [ "${WEBUI_CHANGED:-false}" = "true" ]; then
  SUBJECT_PARTS+=("hermes-web-ui ${WEBUI_TAG:-?}")
  BODY_LINES+=("- web-ui: v${WEBUI_OLD_VER:-?} → v${WEBUI_NEW_VER:-?} (${WEBUI_COMMIT_COUNT:-?} commits, submodule ${WEBUI_OLD_SHA:0:12} → ${WEBUI_NEW_SHA:0:12})")
fi
if [ "${AGENT_CHANGED:-false}" = "true" ]; then
  SUBJECT_PARTS+=("hermes-agent v${AGENT_NEW_VER}")
  BODY_LINES+=("- hermes-agent (PyPI): v${AGENT_OLD_VER:-?} → v${AGENT_NEW_VER:-?}")
fi

# Joined subject ("a + b" if both changed)
JOINED=$(printf "%s + " "${SUBJECT_PARTS[@]}")
JOINED=${JOINED% + }

cat > /tmp/commit-msg.txt <<EOF
chore(deps): bump ${JOINED}

Auto-sync from upstream releases. Patches sanity check passed,
fast-pathed straight to main.

$(printf "%s\n" "${BODY_LINES[@]}")
- desktop: v${OLD_VER} → v${NEW_VER}
EOF

git add -A
git commit -F /tmp/commit-msg.txt
git push origin main

TAG="v${NEW_VER}"
git tag -a "$TAG" -m "Automated release $TAG"
git push origin "$TAG"

echo "✓ Pushed commit + $TAG. release.yml will pick it up."
