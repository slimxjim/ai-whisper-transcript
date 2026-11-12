# PROJEKT-STAV - co projekt potrebuje

> Vygenerovano: 2026-11-12 15:25
> Skriptem ``project_state.ps1`` - po kazde instalaci/zmene staci spustit znovu.

## Metadata pocitace

| Polozka | Hodnota |
|---|---|
| Pocitac | `MORIONET-PC` |
| Uzivatel | `MORIONET-PC\Morionet-PC` |
| OS | Microsoft Windows 10 Pro 10.0.19045 (build 19045) |
| CPU | Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz |
| RAM | 31.9 GB |
| GPU | NVIDIA GeForce GTX 1050 Ti |

## Nastroje

| Nastroj | Cesta |
|---|---|
| `.venv` python | `D:\PROJECTS\AI\video-transcript\.venv\Scripts\python.exe` (existuje) |

## Gitignored obsah (co instalace musi vytvorit / co se prenasi)

### `.venv` - 1,9 GB, 4748 souboru

> vytvari install_wizard.bat -> setup_env.py (pip install -r requirements.txt + CUDA DLL)

- ... (vetsi objem - souhrn vyse)

### `.whisper` - 3,4 GB, 19 souboru

> cache Whisper modelu; stahne setup_env.py, prepise se HF_HOME v prepis.py

- `.cache/` - 3,4 GB

### `__pycache__` - 32,3 KB, 4 souboru

> vznika automaticky pri behu pythonu

- `prepis.cpython-311.pyc` - 4,0 KB
- `prepis.cpython-312.pyc` - 3,8 KB
- `prepis_batch.cpython-311.pyc` - 19,9 KB
- `setup_env.cpython-312.pyc` - 4,7 KB

### `nul` - 0 B, 1 souboru

> omylem vznikly soubor (Windows), smazat


### `prepis` - 19,3 MB, 905 souboru

> testovaci videa - nejde o instalaci, jen data

- ... (vetsi objem - souhrn vyse)

### `prepis_run.log` - 1,6 KB, 1 souboru

> logy a docasne vysledky prepis_batch.py (*.log, *.docasny.txt) - vznikaji za behu


### `PROJEKT-STAV.md` - 3,8 KB, 1 souboru

### `sync.ffs_db` - 0 B, 1 souboru

> osobni data / sync, do instalace nepatri


## PATH

<details><summary>Aktualni PATH</summary>

- `C:\Program Files\Git\mingw64\bin`
- `C:\Program Files\Git\usr\bin`
- `C:\Users\Morionet-PC\bin`
- `C:\Users\Morionet-PC\AppData\Local\Programs\Devin\resources\app\extensions\windsurf\bin`
- `C:\Python312\Scripts`
- `C:\Python312`
- `C:\Program Files (x86)\Common Files\Intel\Shared Libraries\redist\intel64\compiler`
- `C:\Program Files\Common Files\Oracle\Java\javapath`
- `C:\Program Files (x86)\Common Files\Oracle\Java\java8path`
- `C:\Program Files (x86)\Common Files\Oracle\Java\javapath`
- `C:\Windows\system32`
- `C:\Windows`
- `C:\Windows\System32\Wbem`
- `C:\Windows\System32\WindowsPowerShell\v1.0`
- `C:\Windows\System32\OpenSSH`
- `C:\_bat`
- `C:\Libs\maven\apache-maven-3.5.4\bin`
- `C:\Program Files\dotnet`
- `C:\ProgramData\chocolatey\bin`
- `C:\Users\Morionet-PC\AppData\Roaming\nvm`
- `C:\Program Files\nodejs`
- `C:\Libs\apache\maven\apache-maven-3.9.6\bin`
- `C:\Program Files\Git\cmd`
- `C:\Program Files\TortoiseSVN\bin`
- `C:\Program Files\TortoiseGit\bin`
- `C:\Program Files\NVIDIA Corporation\NVIDIA app\NvDLISR`
- `C:\Program Files\Docker\Docker\resources\bin`
- `C:\Program Files (x86)\NVIDIA Corporation\PhysX\Common`
- `C:\Program Files\Tesseract-OCR`
- `C:\Program Files\Calibre2`
- `C:\Users\Morionet-PC\AppData\Local\Microsoft\WindowsApps`
- `C:\Users\Morionet-PC\AppData\Local\Programs\Microsoft VS Code\bin`
- `C:\Program Files\JetBrains\IntelliJ IDEA 2023.3.2\bin`
- `C:\Users\Morionet-PC\AppData\Roaming\npm`
- `C:\Users\Morionet-PC\AppData\Roaming\nvm`
- `C:\Program Files\nodejs`
- `C:\Users\Morionet-PC\go\bin`
- `C:\Users\Morionet-PC\AppData\Roaming\Programs\Zero Install`
- `C:\Users\Morionet-PC\.dotnet\tools`
- `C:\Users\Morionet-PC\AppData\Local\Microsoft\WinGet\Packages\DenoLand.Deno_Microsoft.Winget.Source_8wekyb3d8bbwe`
- `C:\Users\Morionet-PC\AppData\Local\Microsoft\WinGet\Packages\yt-dlp.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-N-127043-g5a54fcf75e-win64-gpl\bin`
- `C:\Users\Morionet-PC\AppData\Local\Microsoft\WinGet\Packages\yt-dlp.yt-dlp_Microsoft.Winget.Source_8wekyb3d8bbwe`
- `C:\Users\Morionet-PC\AppData\Local\Programs\Devin\bin`

</details>

