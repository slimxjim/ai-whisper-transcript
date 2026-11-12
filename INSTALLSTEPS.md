# INSTALLSTEPS — co potřebuje projekt

Rychlý seznam toho, co `install_wizard.bat` kontroluje a jak chybějící
nástroj doinstalovat. Wizard na chybějící věci upozorní a počká,
až je opravíš — pak stačí stisknout Enter a znovu ověří.

## 1) Python 3.10–3.13 (povinné)

Projekt běží ve `.venv` (virtuelní prostředí), které wizard vytvoří
sám — stačí mít na počítači jakýkoli Python 3.10+.

**Instalace:**

- Stáhni z <https://www.python.org/downloads/> (Windows installer),
  nebo jedním příkazem:

  ```bat
  winget install Python.Python.3.12
  ```

- Při instalaci **zaškrtni** „Add python.exe to PATH“ (na první
  obrazovce installeru, nebo jako dílčí možnost dole).
- Po instalaci **zavři a znovu otevři** okno terminálu — PATH se
  nepromítne do už běžícího okna.

**Kam se Python nainstaluje** (podle zvolených voleb installeru):

- `C:\Python312` — pokud instalace „for all users" / do kořene
  disku (tak je to i na tomto PC — viz `PROJEKT-STAV.md`).
- `%LOCALAPPDATA%\Programs\Python\Python312` — typicky při instalaci
  „just for me" bez admin práv.
- `%USERPROFILE%\AppData\Local\Microsoft\WindowsApps` — zástupce
  z Microsoft Store (doporučuje se **nepoužívat** — virtuální
  prostředí `.venv` na ni někdy špatně reaguje).

Projekt ale Python nikam nehledá natvrdo — stačí, aby `python`
byl v PATH.

Ověření (v novém cmd):

```bat
python --version
```

Mělo by vypsat např. `Python 3.12.x`.

## 2) NVIDIA GPU + CUDA (volitelné, jen pro rychlost)

Bez NVIDIA grafické karty to **není nutné** — Whisper poběží na CPU
(výrazně pomaleji). Wizard CUDA runtime nainstaluje automaticky přes
pip balíčky — samostatný CUDA Toolkit se nestahuje.

Pokud chceš GPU akceleraci:

- NVIDIA ovladače ze <https://www.nvidia.com/Download/index.aspx>
- Podporovaná je CUDA 12 ( GTX 1050 Ti a novější Pascal+ ).

## 3) ffmpeg (NENÍ potřeba)

`faster-whisper` dekóduje audio přes PyAV, takže ffmpeg se
neinstaluje ani nevyžaduje.

## 4) Whisper modely

Modely se ukládají **do projektu** do `.whisper/.cache/huggingface`
(přesměrování přes proměnnou `HF_HOME`, nastavené v `prepis.py` a
`setup_env.py`). Model `medium` je ~1,5 GB — stáhne se jednou a zůstane
v projektu, takže se přenesou i s ním. Pokud už tam je, wizard ho
znovu nestahuje.

---

## Krátké vysvětlivky

- **Python** — programovací jazyk, na kterém jsou skripty projektu
  napsané; zdroj: <https://www.python.org/about/gettingstarted/>
- **PATH** — systémová proměnná s adresáři, kde Windows hledá
  spustitelné programy; zdroj: <https://learn.microsoft.com/windows/win32/shell/environment-variables>
- **`.venv` (virtuelní prostředí)** — oddělená složka s vlastními
  verzemi Python balíčků pro projekt; zdroj: <https://docs.python.org/3/library/venv.html>
- **pip** — správce balíčků pro Python, instaluje `requirements.txt`;
  zdroj: <https://pip.pypa.io/>
- **CUDA** — NVIDIA platforma pro výpočty na GPU; `ctranslate2`
  (jádro Whisperu) ji využívá pro zrychlení přepisu; zdroj:
  <https://developer.nvidia.com/cuda-toolkit>
- **HF_HOME** — proměnná prostředí, která říká huggingface_hub, kam
  ukládat stažené modely. Výchozí bez nastavení je
  `%USERPROFILE%\.cache\huggingface`; v tomto projektu je ale
  přesměrovaná na `.whisper/.cache/huggingface` (viz `prepis.py`);
  zdroj: <https://huggingface.co/docs/huggingface_hub/package_reference/environment_variables>
- **PyAV** — Python wrapper kolem ffmpeg knihoven pro čtení videa/
  audia, nahrazuje samostatný ffmpeg; zdroj: <https://pyav.org/>
