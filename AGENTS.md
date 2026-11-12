# AGENTS.md

## Project
Video/audio transcription tool (Windows). Transcribes to Czech text with timestamps via faster-whisper.

## Structure
- `prepis.py` — transcribes ONE file: `python prepis.py <video> [output.txt] [start_seconds]` (appends if start>0, decodes 5s earlier for context).
- `prepis_batch.py` — recursively transcribes a directory, writes `<name>.prepis.txt` next to each video, skips existing non-empty transcripts, resumes from last timestamp in `.docasny.txt`, lock file `prepis_batch.lock`, progress in console title, log `prepis_batch.log`.
- `start.bat` — interactive launcher: asks 1 (single file) / 2 (folder), then path.
- `setup.sh` / `setup_env.py` — environment setup (venv, requirements, CUDA DLL copy). `setup_env.py` is the Windows path used by `install_wizard.bat`, which checks for Python, waits for user fixes, then runs `setup_env.py` (pre-downloads the `medium` model unless already cached). `INSTALLSTEPS.md` lists prerequisites.
- `project_state.ps1` — generates `PROJEKT-STAV.md` (gitignored): PC metadata, tool paths, tree of gitignored files with sizes and notes on what creates them. Run after install/migration.
- `.devin/skills/start/SKILL.md` — `/start` onboarding: introduces project, verifies install (`.venv` + faster_whisper + `.whisper` model cache), points to `install_wizard.bat` if missing, then hands off to `run`.
- `.devin/skills/run/SKILL.md` — `/run` guides the user to launch a transcription: asks single file vs folder, gives exact copy-paste cmd; can launch detached via `cmd /c start` — must NOT poll output (hours-long run, burns tokens/ACUs).
- `NAVOD.md` — Czech user guide for batch mode; `README.md` — overview.

## Environment
- Always use `.venv\Scripts\python.exe` — never system Python.
- Model: `medium`, lang `cs`. Weights live in project cache `.whisper/.cache/huggingface` via `HF_HOME` (set in `prepis.py`/`setup_env.py` before faster-whisper import; ~1.5 GB, already copied there).
- CUDA DLLs are copied into the `ctranslate2` package inside `.venv` — project-local, nothing global needed.
- No ffmpeg needed — PyAV decodes audio.

## Gotchas
- `av==12.3.0` is pinned: faster-whisper passes `metadata_errors="ignore"` which av>=13 rejects.
- GPU optional; without CUDA it falls back to CPU (much slower). float16 warning on older GPUs is normal.
- Batch stdout is reconfigured with `errors="replace"` — keep it that way.
- Docs are in Czech (UTF-8); comments in code are Czech.
