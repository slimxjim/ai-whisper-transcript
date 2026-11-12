# prepis_batch.py — hromadný přepis videí

Skript projde zadaný adresář **včetně podadresářů**, najde video soubory a pro každý
vytvoří přepis `<název_souboru>.prepis.txt` vedle něj (např. `video.mp4` →
`video.mp4.prepis.txt`).

- Přepis dělá přes `prepis.py` (faster-whisper, model `medium`, čeština,
  CUDA na NVIDIA GPU).
- Pokud přepis už existuje, soubor **přeskočí** a zapíše to do logu.
- Na začátku zjistí počet souborů, celkovou velikost a délku a odhad doby
  zpracování. Průběh zpracovaného objemu dat ukazuje v **záhlaví okna
  terminálu** (např. `Prepis: 42.3% (1.2 GB / 2.9 GB)`).
- Průběh a výsledky se ukládají do `prepis_batch.log` v kořeni zadaného
  adresáře.

> **Důležité:** spouštěj to **pythonem z projektového `.venv`**
> (`.venv\Scripts\python.exe`), kde je nainstalovaný `faster-whisper`.
> Skript i `prepis.py` musí zůstat ve složce projektu — `prepis_batch.py`
> spouští `prepis.py` přes `sys.executable`, takže se `.venv` přenese
> i do podprocesů automaticky.

---

## TLDR — nejrychlejší spuštění

**Nejjednodušší:** dvojklik na `start.bat` ve složce projektu — zeptá se,
chceš jeden video soubor (volba 1) nebo složku s videi (volba 2), a pak
se zeptá na cestu. Pro složku s videi se tak spustí právě tenhle
`prepis_batch.py`.

Ruční spuštění přes `Win + R`:
2. Vlož tento řádek a stiskni Enter (předpokládá `.venv` připravené
   přes `bash setup.sh` — viz README):

   ```
   cmd /k cd /d "D:\PROJECTS\AI\video-transcript" && .venv\Scripts\python.exe prepis_batch.py "cesta\k\videim"
   ```

3. Až to poběží, můžeš okno minimalizovat — průběh je vidět v záhlaví okna
   (procenta zpracovaného objemu dat).

Hotovo. Podrobnosti a další způsoby spuštění jsou níž.

---

## 1) Příprava (jen poprvé / pokud python nefunguje)

Ověř, že `.venv` umí faster-whisper:

```bat
.venv\Scripts\python.exe -c "import faster_whisper; print('ok')"
```

Pokud `.venv` neexistuje (nový počítač, smazaná složka), vytvoř a
nakonfiguruj ho jedním příkazem:

```bash
bash setup.sh
```

Skript nainstaluje `requirements.txt` a dopojí CUDA 12 runtime pro NVIDIA GPU.
Pokud `.venv` už existuje, `setup.sh` je bezpečně zopakuje (idempotentní).

---

## 2) Spuštění v Command Promptu (cmd)

1. Stiskni `Win + R`, do řádku napiš `cmd` a Enter.
2. Přesuň se do složky projektu:

   ```bat
   cd /d "D:\PROJECTS\AI\video-transcript"
   ```

3. Spusť skript s cestou k adresáři s videi (cesta **musí být v uvozovkách**,
   pokud obsahuje mezery):

   ```bat
   .venv\Scripts\python.exe prepis_batch.py "cesta\k\videim"
   ```

  Poznámka: skript bere **jen adresář** jako argument — další parametry
   (`--help` apod.) ignoruje.

---

## 3) Spuštění v PowerShellu

1. Stiskni `Win + R`, do řádku napiš `powershell` a Enter.
   (Nebo `pwsh` pro PowerShell 7.)
2. Přesuň se do složky projektu:

   ```powershell
   Set-Location "D:\PROJECTS\AI\video-transscript"
   ```

3. Spusť skript:

   ```powershell
   .venv\Scripts\python.exe prepis_batch.py "cesta\k\videim"
   ```

   V PowerShellu funguje i kratší varianta `.\.venv\Scripts\python.exe`,
   ale plný tvar je jednoznačnější.

---

## 4) Spuštění přes Win + R (přímo, bez otevírání terminálu)

Stiskni `Win + R` a do řádku vlož celý příkaz:

```
cmd /k cd /d "D:\PROJECTS\AI\video-transcript" && .venv\Scripts\python.exe prepis_batch.py "cesta\k\videim"
```

- `cmd /k` = po skončení skriptu okno **zůstane otevřené**, takže uvidíš
  výsledky a případné chyby. Kdybys chtěl, aby se okno samo zavřelo, použij
  `cmd /c` místo `cmd /k`.
- Pozor: tento řádek je na **jedno použití** — až skončí, zavři okno.
  Pro opakované spouštění je pohodlnější postup z bodu 2.

---

## 5) Co očekávat při běhu

1. Skript vypíše počet nalezených videí a u každého jeho velikost a délku.
2. Na konci přehledu ukáže celková data, celková délka audia a hrubý odhad
   doby zpracování.
3. Pak začne přepisovat — průběh je vidět v záhlaví okna terminálu
   (procenta zpracovaného objemu dat) a řádek po řádku i v okně.
4. Když skončí, vypíše souhrn: kolik souborů přepsáno, kolik přeskočeno
   (přepis už existoval) a kolik chyb.

### Poznámky

- **Přerušení:** `Ctrl + C` zastaví aktuální přepis. Už hotové
  `.prepis.txt` soubory zůstanou — při dalším spuštění se přeskočí.
- **Pokračování:** stačí spustit stejný příkaz znovu — existující přepisy
  se automaticky přeskočí. U jednotlivého `prepis.py` jde o pokračování
  od zadané sekundy (3. argument).
- **Log:** `prepis_batch.log` ve složce s videi obsahuje přehled toho, co
  bylo přepsáno, přeskočeno nebo selhalo.
- **Odhad doby:** koeficient `EST_SECONDS_PER_AUDIO_SECOND` v
  `prepis_batch.py` (výchozí 3,0) je jen hrubý — skutečná rychlost záleží
  na výkonu PC a GPU. První video ukáže, jak to reálně běží.
- **První běh** model `medium` (~1,5 GB) stáhne do projektové cache
  `.whisper\.cache\huggingface` — pak už je v cache.
- **Rychlost:** `prepis.py` pro každý soubor znovu načítá model do paměti
  (řádově desítky sekund navíc na soubor). U 17 videí to znamená ~15 min
  čistého overheadu — pro pravidelné dávky by se vyplatilo model načíst
  jednou.
- **GPU:** s CUDA (připraveným přes `setup.sh`) běží `medium` na NVIDIA
  GPU. Na GTX 1050 Ti se model interně přepne na float32 (float16 na
  Pascalu není efektivní) — varování ctranslate2 je normální.
- Cesta k adresáři je v příkladech s **uvozovkami** kvůli mezerám a
  diakritice — bez uvozovek by to nefungovalo.

### Řešení problémů

- **`RuntimeError: ... cublas64_12.dll is not found`** — chybí CUDA 12
  runtime. Spusť `bash setup.sh`.
- **`TypeError: open() got an unexpected keyword argument 'metadata_errors'`**
  — nainstalovaná verze `av` je moc nová. `requirements.txt` pinnuje
  `av==12.3.0`; oprav přes `.venv\Scripts\pip.exe install "av==12.3.0"`.
- **`RuntimeError: mkl_malloc: failed to allocate memory`** — model se
  nevejde do RAM. Uvolni paměť (zavři prohlížeč apod.) a zkus znovu.
- **Skript hlásí `CHYBA` u některých souborů** — přepis daného souboru
  selhal, ale skript **pokračuje dalším** (chyby najdeš v
  `prepis_batch.log`). Oprav a pusť příkaz znovu — úspěšné přepisy se
  přeskočí.
- **Diakritika v logu** — `prepis_batch.log` je UTF-8; v `cmd` se může
  zobrazovat špatně, soubor samotný je v pořádku.
