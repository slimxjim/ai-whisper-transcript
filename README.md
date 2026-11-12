# prepis.py — přepis videa na text

Přepis audio/video souboru na text pomocí Whisperu (model `medium`, čeština), s časovými kódy. Výsledek se ukládá do `prepis.txt` (nebo do souboru zadaného jako 2. argument). Pro hromadný přepis celé složky se 사용하는 `prepis_batch.py`.

## TLDR

Nejjednodušší je dvojklik na `start.bat` — zeptá se, jestli chceš
přepsat jeden video soubor (volba 1) nebo celou složku s videi
(včetně podadresářů, volba 2), a pak se zeptá na cestu.

```bat
install_wizard.bat                                    :: prvni instalace na novem PC (kontroly + navod)
project_state.ps1                                     :: vygeneruje PROJEKT-STAV.md (stav projektu + metadata PC)
start.bat                                              :: pruvodce s otazkami
.venv\Scripts\python.exe prepis.py "video.mp4"         :: jen jeden soubor
.venv\Scripts\python.exe prepis_batch.py "slozka"      :: cela slozka
```

**Ve Devinovi** (agent CLI/desktop) — projektové skilly
`.devin/skills/`, spouští se jako `/start` a `/run`:

```
/start   :: onboarding — seznámí s projektem, zkontroluje instalaci
            (případně pošle na install_wizard.bat) a pak plynule
            naváže na /run
/run     :: průvodce spuštěním — zeptá se na soubor/složku a dá
            přesný příkaz ke zkopírování do cmd; umí i spustit
            přepis odpojeně na pozadí (bez sledování výstupu,
            aby neběžel na úkor tokenů/ACU)
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
- **Model:** `medium` se při prvním běhu stáhne do projektové cache
  `.whisper/.cache/huggingface` (přes `HF_HOME`, řádově ~1,5 GB) —
  pak už je v cache a projekt je přenositelný i s modely.
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
Stejnou věc umí i `start.bat` — stačí vybrat volbu 2 a zadat cestu k adresáři.
