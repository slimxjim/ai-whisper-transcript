#!/usr/bin/env bash
# Inicializace projektoveho prostredi pro prepis.py (faster-whisper + CUDA).
# Spoustet z korene projektu:  bash setup.sh
set -euo pipefail
cd "$(dirname "$0")"

PYTHON="${PYTHON:-python}"
VENV_DIR=".venv"
VENV_PY="$VENV_DIR/Scripts/python.exe"   # Windows
[ -f "$VENV_PY" ] || VENV_PY="$VENV_DIR/bin/python"  # Linux/macOS fallback

if [ ! -x "$VENV_PY" ]; then
    echo ">> Vytvarim $VENV_DIR ..."
    "$PYTHON" -m venv "$VENV_DIR"
fi

echo ">> Instaluji balicky z requirements.txt ..."
"$VENV_PY" -m pip install --upgrade pip
"$VENV_PY" -m pip install -r requirements.txt

# ctranslate2 potrebuje CUDA 12 runtime DLL, ktere nvidia pip balicky
# nedavaji na Library path. Zkopiruji je vedle cudnn64_9.dll v balicku
# ctranslate2, aby se nasly bez zasahu do PATH (idempotentni).
echo ">> Kopiruji CUDA runtime do balicku ctranslate2 ..."
"$VENV_PY" - <<'PY'
import glob
import os
import shutil
import sys

import ctranslate2

ct2_dir = os.path.dirname(ctranslate2.__file__)
site_packages = os.path.dirname(ct2_dir)

# (hledany nazev, kam se ma zkopirovat) — .dll na Windows, .so na Linuxu
wanted = ["cublas64_12.dll", "cublasLt64_12.dll", "cudart64_12.dll",
          "libcublas.so.12", "libcublasLt.so.12", "libcudart.so.12"]

found = []
for root in glob.glob(os.path.join(site_packages, "nvidia", "*", "*")):
    for name in os.listdir(root):
        base = name.split(".")[0] if name.endswith(".so") else os.path.splitext(name)[0]
        for w in wanted:
            if name == w or (w.endswith(".so.12") and name.startswith(base + ".so")):
                dst = os.path.join(ct2_dir, name)
                if not os.path.exists(dst):
                    shutil.copy2(os.path.join(root, name), dst)
                found.append(name)

print("   zkopirovano/nalezeno:", ", ".join(sorted(set(found))) or "NIC — CUDA runtime chyb")
if not found:
    sys.exit("CUDA runtime DLL se v .venv nenasly — zkontroluj requirements.txt")
PY

echo ">> Overuji CUDA ..."
"$VENV_PY" -c "import ctranslate2; print('CUDA zarizeni:', ctranslate2.get_cuda_device_count())"

echo ""
echo "Hotovo. Spusteni:"
echo "  $VENV_PY prepis.py \"video.mp4\" vystup.txt"
