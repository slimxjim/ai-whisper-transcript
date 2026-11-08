from faster_whisper import WhisperModel
import sys

video = sys.argv[1]
output = sys.argv[2] if len(sys.argv) > 2 else "prepis.txt"
# Volitelny argument: od kolikate sekundy pokracovat (0 = od zacatku)
start_od = float(sys.argv[3]) if len(sys.argv) > 3 else 0.0

PRESAH_PRED = 5.0  # whisper potrebuje kontext — dekodujeme o 5 s driveji


def decode_audio_od(path, start_seconds):
    """Dekoduje audio od start_seconds: 16 kHz, mono, float32 numpy.

    Rychlejsi Whisper Variante: misto cesty k souboru se transcribuje
    numpy pole se zvukem.
    """
    import av
    import numpy as np

    container = av.open(str(path))
    stream = container.streams.audio[0]
    resampler = av.AudioResampler(format="s16", layout="mono", rate=16000)
    skip = int(round(start_seconds * 16000))
    chunks = []
    pos = 0

    def absorb(frame):
        nonlocal pos
        for rf in resampler.resample(frame):
            data = rf.to_ndarray().reshape(-1)
            samples = data.astype(np.float32) / 32768.0
            if pos + len(samples) <= skip:
                pos += len(samples)
                continue
            cut = max(0, skip - pos)
            pos += len(samples)
            chunks.append(samples[cut:] if cut else samples)

    for frame in container.decode(stream):
        absorb(frame)
    absorb(None)  # flush zbytků resampleru
    container.close()

    if not chunks:
        return np.zeros(0, dtype=np.float32)
    return np.concatenate(chunks)


model = WhisperModel("turbo", device="auto", compute_type="int8")

if start_od > 0:
    decode_od = max(0.0, start_od - PRESAH_PRED)
    audio = decode_audio_od(video, decode_od)
    segments, info = model.transcribe(audio, language="cs", vad_filter=True)
else:
    decode_od = 0.0
    segments, info = model.transcribe(video, language="cs", vad_filter=True)

mode = "a" if start_od > 0 else "w"
with open(output, mode, encoding="utf-8") as f:
    for s in segments:
        # zahodime segmenty, ktere konci jeste pred bodem pokracovani
        if start_od > 0 and s.end + decode_od <= start_od:
            continue
        ts = s.start + decode_od
        radek = f"[{ts:.1f}s] {s.text.strip()}"
        print(radek, flush=True)
        f.write(radek + "\n")
        f.flush()  # ať je cast vysledku na disku i pri predcasnem ukonceni
