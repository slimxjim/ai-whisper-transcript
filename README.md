# prepis.py — přepis videa na text

Přepis audio/video souboru na text pomocí Whisperu (model `turbo`, čeština), s časovými kódy. Výsledek se ukládá do `prepis.txt` (nebo do souboru zadaného jako 2. argument).

## TLDR

```bash
bash setup.sh                                        # jen poprvé / po přenesení projektu
.venv/Scripts/python.exe prepis.py "video.mp4" vystup.txt
```

`setup.sh` vytvoří projektové `.venv`, nainstaluje `requirements.txt`
a dopojí CUDA 12 runtime, aby `faster-whisper` běžel na NVIDIA GPU.

## Detaily

- **Prostředí:** všechno běží ve `.venv` ve složce projektu — systémový
  Python se nepoužívá a nevznikají konflikty s jinými projekty.
  `.venv` se **nepřenáší** mezi počítači — na novém stroji se vytváří
  znovu přes `setup.sh`.
- **CUDA:** `ctranslate2` (jádro faster-whisperu) potřebuje CUDA 12
  knihovny. Místo instalace celého CUDA Toolkitu se v `requirements.txt`
  instalují pip balíčky `nvidia-*-cu12` a `setup.sh` zkopíruje DLL
  (`cublas64_12.dll`, `cudart64_12.dll`, …) do balíčku `ctranslate2`.
  Bez NVIDIA GPU to není nutné — model poběží na CPU (výrazně pomaleji).
- **Verze:** `av==12.3.0` je záměrně pinned — `faster-whisper` volá
  `av.open(..., metadata_errors="ignore")`, což PyAV ≥13 odmítá.
- **Model:** `turbo` se při prvním běhu stáhne do mezipaměti
  (`~/.cache/huggingface`, řádově ~1,6 GB) — pak už je v cache.
- `ffmpeg` není potřeba — faster-whisper dekóduje zvuk přes PyAV.
- Podporuje MP4, MP3, WAV, MKV a další formáty, které PyAV/ffmpeg umí číst.
- Volitelný 3. argument = sekundová pozice, od které pokračovat
  (0 = od začátku); výsledek se **přidává** do zadaného výstupního souboru.
- V Windows terminálu se diakritika může zobrazovat špatně (kódování
  konzole) — výstupní soubor je vždy správně v UTF-8.

## Hromadné zpracování

Pro dávku videí viz `NAVOD.md` — skript `prepis_batch.py` projde
adresář včetně podadresářů a ke každému videu vytvoří
`<název>.prepis.txt` (přepis dělá přes `prepis.py`).
