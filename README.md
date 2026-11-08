# prepis.py

Přepis audio/video souboru na text pomocí Whisperu (model `medium`, čeština), s časovými kódy. Výsledek se ukládá do `prepis.txt`.

## TLDR

```bash
pip install faster-whisper
python prepis.py "cesta\k\video.mp4"
```

V tomto adresáři je video ve složce `prepis/` a prázdný venv `prepis/venv` — pokud chceš přepis spouštět přes něj, nejdřív do něj nainstaluj `faster-whisper` (jinak funguje systémový Python, kde je už nainstalovaný).

```bash
prepis/venv/Scripts/pip.exe install faster-whisper
prepis/venv/Scripts/python.exe prepis.py "prepis/nazev.mp4"
```

Výstup: `prepis.txt` (jeden řádek = `[čas] text`).

## Detaily

- První běh si stáhne model `medium` (~1,5 GB) do mezipaměti (`~/.cache/huggingface`) — trvá déle.
- `ffmpeg` není potřeba — faster-whisper dekóduje zvuk přes PyAV.
- Podporuje MP4, MP3, WAV, MKV a další formáty, které PyAV/ffmpeg umí číst.
- V Windows terminálu se diakritika může zobrazovat špatně (kódování konzole) — `prepis.txt` je vždy správně v UTF-8.
