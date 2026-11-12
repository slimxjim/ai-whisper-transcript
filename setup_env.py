"""
Instalace projektoveho prostredi (Windows ekvivalent setup.sh).

Spousti se z install_wizard.bat, ale jde i samostatne:
    python setup_env.py

Co dela:
  1. Vytvori .venv (kdyz neexistuje)
  2. Nainstaluje requirements.txt
  3. Zkopiruje CUDA 12 DLL do balicku ctranslate2
  4. Overi pocet CUDA zarizeni
  5. Stahne Whisper model "medium" do HF cache — preskoci,
     kdyz uz tam je. Cache je projektova (.whisper/.cache/huggingface),
     prepise ji promenna prostredi HF_HOME.
"""

import glob
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
VENV_PY = ROOT / ".venv" / "Scripts" / "python.exe"
MODEL_REPO = "models--Systran--faster-whisper-medium"
# Whisper modely drzi projekt interne — stejne jako v prepis.py.
HF_HOME = Path(os.environ.get("HF_HOME") or (ROOT / ".whisper" / ".cache" / "huggingface"))
os.environ.setdefault("HF_HOME", str(HF_HOME))


def run(cmd, **kw):
    print(f"\n>> {' '.join(str(c) for c in cmd)}", flush=True)
    subprocess.check_call(cmd, cwd=ROOT, **kw)


def main() -> int:
    # 1) .venv
    if not VENV_PY.exists():
        print(">> Vytvarim .venv ...")
        run([sys.executable, "-m", "venv", str(ROOT / ".venv")])

    # 2) balicky
    run([str(VENV_PY), "-m", "pip", "install", "--upgrade", "pip"])
    run([str(VENV_PY), "-m", "pip", "install", "-r", "requirements.txt"])

    # 3) CUDA 12 DLL do balicku ctranslate2 (stejny kod jako setup.sh)
    print(">> Kopiruji CUDA runtime do balicku ctranslate2 ...")
    run([str(VENV_PY), "-c", CUDA_DLL_SNIPPET])

    # 4) overeni CUDA
    print(">> Overuji CUDA ...")
    run([str(VENV_PY), "-c",
         "import ctranslate2; print('CUDA zarizeni:', ctranslate2.get_cuda_device_count())"])

    # 5) Whisper model — stahne jen kdyz v cache neni
    snap = HF_HOME / "hub" / MODEL_REPO / "snapshots"
    if snap.is_dir() and any(snap.iterdir()):
        print(f">> Model 'medium' uz je v cache ({snap}) — nestahuji.")
    else:
        print(f">> Stahuji Whisper model 'medium' do {HF_HOME} ...")
        print("   (jednorazove, radove ~1.5 GB — muzes byt chvili bez odezvy)")
        run([str(VENV_PY), "-c",
             "from faster_whisper import WhisperModel; "
             "WhisperModel('medium'); print('model medium: OK')"])

    print("\n============================================")
    print(" INSTALACE DOBEHLA — HOTOVO")
    print("============================================")
    print("Spusteni: start.bat  (nebo .venv\\Scripts\\python.exe prepis.py ...)")
    return 0


CUDA_DLL_SNIPPET = r"""
import glob, os, shutil, sys
import ctranslate2

ct2_dir = os.path.dirname(ctranslate2.__file__)
site_packages = os.path.dirname(ct2_dir)
wanted = ["cublas64_12.dll", "cublasLt64_12.dll", "cudart64_12.dll"]
found = []
for root in glob.glob(os.path.join(site_packages, "nvidia", "*", "*")):
    for name in os.listdir(root):
        for w in wanted:
            if name == w:
                dst = os.path.join(ct2_dir, name)
                if not os.path.exists(dst):
                    shutil.copy2(os.path.join(root, name), dst)
                found.append(name)
print("   zkopirovano/nalezeno:", ", ".join(sorted(set(found))) or "NIC — CUDA runtime chyb")
if not found:
    sys.exit("CUDA runtime DLL se v .venv nenasly — zkontroluj requirements.txt")
"""


if __name__ == "__main__":
    sys.exit(main())
