# prepis_batch.py — hromadný přepis videí

Skript projde zadaný adresář **včetně podadresářů**, najde video soubory a pro každý
vytvoří přepis `<název_souboru>.prepis.txt` vedle něj (např. `video.mp4` →
`video.mp4.prepis.txt`).

- Přepis dělá přes `prepis.py` (faster-whisper, model `medium`, čeština).
- Pokud přepis už existuje, soubor **přeskočí** a zapíše to do logu.
- Na začátku zjistí počet souborů, celkovou velikost a délku a odhad doby
  zpracování. Průběh zpracovaného objemu dat ukazuje v **záhlaví okna
  terminálu** (např. `Prepis: 42.3% (1.2 GB / 2.9 GB)`).
- Průběh a výsledky se ukládají do `prepis_batch.log` v kořeni zadaného
  adresáře.

> **Důležité:** spouštěj to **systémovým `python`**, kde je nainstalovaný
> `faster-whisper` — ne prázdným `prepis/venv`. Skript i `prepis.py` musí
> zůstat ve složce `C:\HOME\DATA\Dokumenty`.

---

## TLDR — nejrychlejší spuštění

1. Stiskni `Win + R`.
2. Vlož tento řádek a stiskni Enter:

   ```
   cmd /k cd /d "C:\HOME\DATA\Dokumenty" && python prepis_batch.py "c:\HOME\DATA\Rekvalifikační kurz\2026 - Personalistka\4. SUO – 2. část"
   ```

3. Až to poběží, můžeš okno minimalizovat — průběh je vidět v záhlaví okna
   (procenta zpracovaného objemu dat).

Hotovo. Podrobnosti a další způsoby spuštění jsou níž.

---

## 1) Příprava (jen poprvé / pokud python nefunguje)

Ověř, že python umí faster-whisper:

```bat
python -c "import faster_whisper; print('ok')"
```

Pokud vypíše `ok`, můžeš spouštět. Pokud ne, nainstaluj:

```bat
pip install faster-whisper
```

---

## 2) Spuštění v Command Promptu (cmd)

1. Stiskni `Win + R`, do řádku napiš `cmd` a Enter.
2. Přesuň se do složky se skripty:

   ```bat
   cd /d "C:\HOME\DATA\Dokumenty"
   ```

3. Spusť skript s cestou k adresáři s videi (cesta **musí být v uvozovkách**,
   protože obsahuje mezery):

   ```bat
   python prepis_batch.py "c:\HOME\DATA\Rekvalifikační kurz\2026 - Personalistka\4. SUO – 2. část"
   ```

  Poznámka: skript bere **jen adresář** jako argument — další parametry
   (`--help` apod.) ignoruje.

---

## 3) Spuštění v PowerShellu

1. Stiskni `Win + R`, do řádku napiš `powershell` a Enter.
   (Nebo `pwsh` pro PowerShell 7.)
2. Přesuň se do složky se skripty:

   ```powershell
   Set-Location "C:\HOME\DATA\Dokumenty"
   ```

3. Spusť skript:

   ```powershell
   python prepis_batch.py "c:\HOME\DATA\Rekvalifikační kurz\2026 - Personalistka\4. SUO – 2. část"
   ```

   V PowerShellu funguje i kratší varianta bez `.py`, ale plný tvar je
   jednoznačnější.

---

## 4) Spuštění přes Win + R (přímo, bez otevírání terminálu)

Stiskni `Win + R` a do řádku vlož celý příkaz:

```
cmd /k cd /d "C:\HOME\DATA\Dokumenty" && python prepis_batch.py "c:\HOME\DATA\Rekvalifikační kurz\2026 - Personalistka\4. SUO – 2. část"
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
  se automaticky přeskočí.
- **Log:** `prepis_batch.log` ve složce s videi obsahuje přehled toho, co
  bylo přepsáno, přeskočeno nebo selhalo.
- **Odhad doby:** koeficient `EST_SECONDS_PER_AUDIO_SECOND` v
  `prepis_batch.py` (výchozí 3,0) je jen hrubý — skutečná rychlost záleží
  na výkonu PC. První video ukáže, jak to reálně běží.
- **První běh** model `medium` (~1,5 GB) stáhne do mezipaměti — pak už je
  v cache.
- **Rychlost:** `prepis.py` pro každý soubor znovu načítá model do paměti
  (řádově desítky sekund navíc na soubor). U 17 videí to znamená ~15 min
  čistého overheadu — pro pravidelné dávky by se vyplatilo model načíst
  jednou.
- Cesta k adresáři je v příkladech s **uvozovkami** kvůli mezerám a
  diakritice — bez uvozovek by to nefungovalo.

### Řešení problémů

- **`RuntimeError: mkl_malloc: failed to allocate memory`** — model
  `medium` se nevejde do RAM (potřebuje zhruba 1,5–3 GB volné paměti).
  Uvolni paměť (zavři prohlížeč apod.) a zkus znovu. Pokud se to opakuje,
  je nutné v `prepis.py` přepnout na menší model — `WhisperModel("small")`
  nebo `"base"` (řádek 6) — za cenu horší kvality přepisu.
- **Skript hlásí `CHYBA` u některých souborů** — přepis daného souboru
  selhal, ale skript **pokračuje dalším** (chyby najdeš v
  `prepis_batch.log`). Oprav a pusť příkaz znovu — úspěšné přepisy se
  přeskočí.
- **Diakritika v logu** — `prepis_batch.log` je UTF-8; v `cmd` se může
  zobrazovat špatně, soubor samotný je v pořádku.
