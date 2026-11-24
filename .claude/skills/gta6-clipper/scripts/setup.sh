#!/usr/bin/env bash
# GTA 6 Clipper setup (Linux/macOS): venv with yt-dlp, faster-whisper, OpenCV, Pillow + models.
set -euo pipefail
S="$(cd "$(dirname "$0")/.." && pwd)"
command -v ffmpeg >/dev/null || { echo "MISSING: ffmpeg (apt-get install -y ffmpeg)"; exit 1; }
command -v uv >/dev/null || { curl -LsSf https://astral.sh/uv/install.sh | sh; export PATH="$HOME/.local/bin:$PATH"; }
if ! command -v deno >/dev/null && [ ! -x "$HOME/.deno/bin/deno" ]; then
  curl -fsSL https://deno.land/install.sh | sh -s -- -y >/dev/null || echo "WARN: deno not installed (yt-dlp may need it for YouTube)"
fi
[ -d "$S/.venv" ] || uv venv -q --python 3.12 "$S/.venv"
PY="$S/.venv/bin/python"
uv pip install --python "$PY" -q -U "yt-dlp[default]" faster-whisper opencv-python-headless pillow numpy
mkdir -p "$S/models/whisper"
"$PY" -c "from faster_whisper import WhisperModel; WhisperModel('small.en', device='cpu', compute_type='int8', download_root='$S/models/whisper')"
Y="$S/models/face_detection_yunet_2023mar.onnx"
[ -s "$Y" ] || curl -fsSL -o "$Y" https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx || true
printf '{"whisper_model":"small.en","whisper_dir":"%s","yunet_model":"%s","path_dirs":["%s"]}\n' \
  "$S/models/whisper" "$Y" "$HOME/.deno/bin" > "$S/config.json"
date -Iseconds > "$S/.ready"
echo READY
