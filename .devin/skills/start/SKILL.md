---
name: start
description: Onboarding projektu — seznámí uživatele s videopřepisem, zkontroluje instalaci a dovede ho k prvnímu přepisu
triggers:
  - user
---

Proveď uživatele prvním spuštěním projektu `video-transcript`
(česky, jednoduché věty — projekt je pro běžného uživatele,
ne programátora).

## 1) Představ projekt (krátce)

- Nástroj přepisuje video/audio na **český text s časovými kódy**
  (Whisper, model `medium`).
- Dva režimy: **jeden soubor** (`prepis.py`) nebo **celá složka**
  s videi včetně podadresářů (`prepis_batch.py`).
- `start.bat` = ruční spuštění s otázkami; `install_wizard.bat` =
  instalace na novém počítači.

## 2) Zkontroluj instalaci

Ověř (přes `.venv\Scripts\python.exe`, ne systémový python):

```bat
.venv\Scripts\python.exe -c "import faster_whisper; print('ok')"
```

a existenci modelu:

```bat
dir /b ".whisper\.cache\huggingface\hub\models--Systran--faster-whisper-medium\snapshots"
```

- **Všechno OK** → rovnou pokračuj krokem 4.
- **něco chybí** → řekni uživateli, ať **dvojklikem spustí
  `install_wizard.bat`** ve složce projektu (je interaktivní —
  sám se zeptá na Python a doinstalace; nezkoušej ho spouštět
  za uživatele). Až wizard doběhne, znovu ověř krok 2.
  - Když chybí už systémový Python, wizard sám poradí
    (`INSTALLSTEPS.md`), ty jen odkaž na soubor.

## 3) Volitelně: report stavu

Pokud chce uživatel přehled, co projekt potřebuje:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File project_state.ps1
```

vygeneruje `PROJEKT-STAV.md` (metadata PC + strom gitignorovaných
souborů s velikostmi).

## 4) Přejdi k prvnímu použití

Pokračuj **postupem skillu `run`** (soubor `.devin/skills/run/SKILL.md`)
— polož uživateli otázku, jestli chce přepsat jeden video soubor
nebo složku, získej cestu a dej mu přesný příkaz ke zkopírování.
