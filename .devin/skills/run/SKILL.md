---
name: run
description: Provede uživatele spuštěním přepisu videa — zeptá se na soubor/složku a dá přesný příkaz ke zkopírování
triggers:
  - user
---

Proveď uživatele spuštěním přepisu. Odpovídej česky.

## 1) Zjisti, co se bude přepisovat

Zeptej se uživatele:

- **jeden video soubor**, nebo
- **složka** se všemi videi (včetně podadresářů)?

Pak získej **přesnou cestu** (může obsahovat mezery a diakritiku —
vždy ve uvozovkách).

## 2) Dej přesný příkaz ke zkopírování

Podle volby připrav blok kódu — zkopírujeme do `cmd`:

** Jeden soubor:**

```bat
cd /d "D:\PROJECTS\AI\video-transcript" && .venv\Scripts\python.exe prepis.py "C:\CESTA\K\VIDEO.mp4"
```

** Složka:**

```bat
cd /d "D:\PROJECTS\AI\video-transcript" && .venv\Scripts\python.exe prepis_batch.py "C:\CESTA\K\SLOZCE"
```

Vysvětli jak:

- `Win + R` → vlož příkaz → Enter. Okno **nechávej zavřené** —
  běh trvá dlouho (u složky klidně hodiny).
- Průběh je vidět v **záhlaví okna** (procenta zpracovaných dat)
  a řádek po řádku v okně; okno jde minimalizovat.
- U složky se výsledek ukládá jako `<nazev>.prepis.txt` vedle
  každého videa + `prepis_batch.log`; hotové soubory se při
  opakovaném spuštění přeskakují.
- Při jednom souboru je výstup `prepis.txt` ve složce projektu —
  pokud chceš výstup jinam, přidej druhý argument s cestou.

## 3) Nabídni variantu "spustit v Devinovi"

Řekni, že to jde i spustit odsud, ale **varuj**:

- Přepis jedné hodiny videa trvá řádově desítky minut až hodiny —
  session by musela zůstat otevřená, což je nepraktické.
- Agent **nesmí** výstup pravidelně sledovat (spálilo by tokeny
  a ACUs). Správný postup: spustit proces **odpojeně** a pak se
  jen jednou za čas podívat na log/výsledek.

Pokud uživatel trvá na spuštění odtud, spusť **odpojeně**
(pokračování v pozadí, žádné sledování výstupu):

```bat
cmd /c start "Prepis videa" /min cmd /k "cd /d "D:\PROJECTS\AI\video-transcript" && .venv\Scripts\python.exe prepis_batch.py "C:\CESTA\K\SLOZCE""
```

(pro jeden soubor `prepis.py` místo `prepis_batch.py`).

Potom **ihned skonči** — nečekej na výsledek, nečti log
e opakovaně. Uživatel sledování dělá sám: okno `Prepis videa`
v liště úloh (záhlaví ukazuje procenta), log
`prepis_batch.log` ve složce s videi, nebo existenci
`.prepis.txt` souborů.

## 4) Poznámky pro agenta

- Nikdy nespouštěj přepis **přímo v popředí** a nečekej na
  dokončení — běh je příliš dlouhý.
- Pokud uživatel přeruší (`Ctrl+C`), hotové `.prepis.txt` zůstanou
  a další spuštění pokračuje tam, kde skončilo.
