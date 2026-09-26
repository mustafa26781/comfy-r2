#!/usr/bin/env bash
# usage: tts "text to speak" [out.wav] [exaggeration]
# Chatterbox runs in its own venv (/opt/tts) so ComfyUI's PyTorch is never touched.
set -euo pipefail
TEXT="${1:?usage: tts \"text\" [out.wav] [exaggeration]}"
OUT="${2:-/app/ComfyUI/output/tts_$(date +%H%M%S).wav}"
EXAG="${3:-0.5}"
CKPT=/app/ComfyUI/models/TTS/chatterbox
if [ ! -s "$CKPT/t3_cfg.safetensors" ]; then echo ">>> loading chatterbox weights from R2 ..."; getmodel chatterbox; fi
if [ ! -x /opt/tts/bin/python ]; then
  echo ">>> first run: installing Chatterbox in /opt/tts (2-3 min, one time per pod) ..."
  /opt/conda/bin/python -m venv /opt/tts
  /opt/tts/bin/pip install -q --upgrade pip
  /opt/tts/bin/pip install -q chatterbox-tts
fi
HF_HUB_OFFLINE=1 /opt/tts/bin/python - "$TEXT" "$OUT" "$EXAG" "$CKPT" <<'PY' 2>&1 | grep -vE "Sampling|warn|Warning|sdpa|self.gen"
import sys, torchaudio as ta
from chatterbox.tts import ChatterboxTTS
text, out, exag, ckpt = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4]
m = ChatterboxTTS.from_local(ckpt, device="cuda")
ta.save(out, m.generate(text, exaggeration=exag), m.sr)
print(">>> saved", out)
PY
