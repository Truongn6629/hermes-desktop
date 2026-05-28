#!/bin/bash
# Record a 30s screencast of Hermes Desktop and convert to gif/mp4.
# Usage: bash docs/record-demo.sh
#
# Output:
#   docs/demo.mp4  — high-quality H.264, ~3-5MB
#   docs/demo.gif  — Twitter/Reddit-friendly, ~5-10MB at 720p / 12fps
#
# Requirements: ffmpeg (brew install ffmpeg)
# macOS only (uses AVFoundation screen capture).

set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p docs

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg not found. Install it: brew install ffmpeg"
  exit 1
fi

DURATION=${DURATION:-30}
RAW=docs/_demo-raw.mov
MP4=docs/demo.mp4
GIF=docs/demo.gif

echo "→ Listing macOS AVFoundation devices (so you can pick the right screen index):"
ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep -E "AVFoundation|Capture screen" | head

SCREEN_INDEX=${SCREEN_INDEX:-1}   # default to "Capture screen 0" — adjust if multi-monitor

cat <<'EOF'

────────────────────────────────────────────────────────────────────
  Recording starts in 5 seconds. Suggested 30-second flow:

    0:00–0:05   Hermes Desktop window already open at the chat view
    0:05–0:10   Type a question (e.g. "你都会什么"), hit Enter
    0:10–0:20   Show the streaming reply
    0:20–0:25   Switch to DingTalk, @ the bot in a group
    0:25–0:30   Show the bot replying via deepseek

  Press Ctrl-C to stop early.
────────────────────────────────────────────────────────────────────
EOF
sleep 5

ffmpeg -y -hide_banner -loglevel warning \
  -f avfoundation -framerate 30 -capture_cursor 1 -i "${SCREEN_INDEX}:none" \
  -t "$DURATION" \
  -pix_fmt yuv420p \
  "$RAW"

echo "→ Encoding mp4 ($MP4)..."
ffmpeg -y -hide_banner -loglevel warning \
  -i "$RAW" \
  -vf "scale='min(1280,iw)':-2,fps=30" \
  -c:v libx264 -crf 23 -preset slow -movflags +faststart \
  "$MP4"

echo "→ Encoding gif ($GIF)..."
PALETTE=docs/_palette.png
ffmpeg -y -hide_banner -loglevel warning \
  -i "$RAW" -vf "fps=12,scale=720:-1:flags=lanczos,palettegen" "$PALETTE"
ffmpeg -y -hide_banner -loglevel warning \
  -i "$RAW" -i "$PALETTE" \
  -lavfi "fps=12,scale=720:-1:flags=lanczos[v];[v][1:v]paletteuse" \
  "$GIF"
rm -f "$PALETTE"

# Optionally compress further with gifsicle if available
if command -v gifsicle >/dev/null 2>&1; then
  echo "→ gifsicle optimizing..."
  gifsicle -O3 --lossy=80 "$GIF" -o "$GIF.opt" && mv "$GIF.opt" "$GIF"
fi

rm -f "$RAW"

ls -lh "$MP4" "$GIF"
echo "✓ Done. Drop docs/demo.gif into Reddit/Twitter, docs/demo.mp4 into the README."
