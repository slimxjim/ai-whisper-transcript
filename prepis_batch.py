"""
Batchovy spusti prepis.py pro vsechna videa ve zvolenem adresari (vcetne podadresaru).

Pouziti:
    python prepis_batch.py "cesta\\k\\adresari_s_videi"

Pro kazdy video soubor vytvori <nazev_souboru>.prepis.txt vedle nej.
Pokud prepis jiz existuje a neni prazdny, soubor preskoci a zapise to do logu.
Prubeh zpracovano objemu dat zobrazuje v nazvu konzoloveho okna.
Druhe soubezne spusteni je blokovano souborem prepis_batch.lock.
"""

import ctypes
import os
import re
import subprocess
import sys
import threading
import time
from pathlib import Path

PREPIS_PY = Path(__file__).parent / "prepis.py"
VIDEO_EXTS = {".mp4", ".mkv", ".avi", ".mov", ".webm", ".m4v", ".mpg", ".mpeg", ".wmv", ".ts", ".flv", ".3gp", ".ogv"}
TMP_SUFFIX = ".docasny.txt"
LOCK_NAME = "prepis_batch.lock"

# Hruby odhad: medium model int8 na CPU zvladne zhruba polovinu az
# astrophysikalni rychlosti. Prubezne 2 az 4 nasobek delky audia.
# Podle reality si uprav.
EST_SECONDS_PER_AUDIO_SECOND = 3.0

TIMESTAMP_RE = re.compile(r"\[\s*(\d+(?:\.\d+)?)s\]")


def set_console_title(title: str) -> None:
    if os.name == "nt":
        ctypes.windll.kernel32.SetConsoleTitleW(title)
    else:
        sys.stdout.write(f"\033]0;{title}\007")
        sys.stdout.flush()


def transcript_path(video: Path) -> Path:
    return video.with_name(video.name + ".prepis.txt")


def transcript_ready(path: Path) -> bool:
    """Prepis je povazovan za hotovy, jen kdyz existuje a neni prazdny."""
    try:
        return path.exists() and path.stat().st_size > 0
    except OSError:
        return False


def get_duration(path: Path) -> float | None:
    """Vrati delku zvuku ve vteřinach (pres PyAV), None kdyz selze."""
    try:
        import av

        with av.open(str(path)) as container:
            if container.duration:
                return container.duration / 1_000_000
            # fallback: delka prvniho audio/video streamu
            for stream in container.streams:
                if stream.duration and stream.time_base:
                    return float(stream.duration * stream.time_base)
    except Exception:
        pass
    return None


def format_duration(seconds: float) -> str:
    seconds = int(seconds)
    h, rem = divmod(seconds, 3600)
    m, s = divmod(rem, 60)
    if h:
        return f"{h} h {m} min"
    if m:
        return f"{m} min {s} s"
    return f"{s} s"


def format_size(num_bytes: float) -> str:
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if num_bytes < 1024 or unit == "TB":
            return f"{num_bytes:.1f} {unit}" if unit != "B" else f"{int(num_bytes)} B"
        num_bytes /= 1024


def collect_videos(root: Path) -> list[Path]:
    return sorted(
        p for p in root.rglob("*")
        if p.is_file() and p.suffix.lower() in VIDEO_EXTS
    )


def pid_alive(pid: int) -> bool:
    if pid <= 0:
        return False
    if os.name == "nt":
        PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
        handle = ctypes.windll.kernel32.OpenProcess(
            PROCESS_QUERY_LIMITED_INFORMATION, False, pid
        )
        if not handle:
            return False
        ctypes.windll.kernel32.CloseHandle(handle)
        return True
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def acquire_lock(root: Path) -> Path | None:
    """Vrati cestu k locku, pokud je volny; None kdyz jiz bezi jina instance."""
    lock_path = root / LOCK_NAME
    for _ in range(2):
        try:
            fd = os.open(lock_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            with os.fdopen(fd, "w") as f:
                f.write(str(os.getpid()))
            return lock_path
        except FileExistsError:
            try:
                pid = int(lock_path.read_text().strip())
            except (OSError, ValueError):
                pid = -1
            if pid_alive(pid):
                return None
            # mrtvy proces — uklidime zataty lock a zkusime jeste jednou
            try:
                lock_path.unlink()
            except OSError:
                return None
    return None


def replace_with_retry(src: Path, dst: Path, attempts: int = 5, delay: float = 2.0) -> None:
    """os.replace s retry — Windows nekdy chvili drzi soubor (antivirus, indexer)."""
    for i in range(attempts):
        try:
            src.replace(dst)
            return
        except PermissionError:
            if i == attempts - 1:
                raise
            time.sleep(delay)


def main() -> int:
    # Pri presmerovani do roury/na Windows pouziva stdout cp1250,
    # coz by na nahradnich znacich (�) spadlo — nahraď je otaznikem.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(errors="replace")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(errors="replace")

    if len(sys.argv) < 2:
        print(f'Pouziti: python {Path(__file__).name} "cesta\\k\\adresari_s_videi"')
        return 1

    root = Path(sys.argv[1]).resolve()
    if not root.is_dir():
        print(f"Chyba: '{root}' neni adresar.")
        return 1

    lock_path = acquire_lock(root)
    if lock_path is None:
        print("Chyba: v tomto adresari jiz prepis bezi (prepis_batch.lock).")
        return 1

    try:
        return run(root)
    finally:
        try:
            lock_path.unlink()
        except OSError:
            pass


def run(root: Path) -> int:
    videos = collect_videos(root)
    if not videos:
        print(f"V '{root}' nebyly nalezeny zadne video soubory.")
        return 0

    log_path = root / "prepis_batch.log"

    # --- Prubezny pruzkum: preskoceni hotovych, pak velikost a delka ---
    print(f"Nalezeno {len(videos)} video souboru. Zjistuji, co je jiz hotove...")
    total_bytes = 0
    skipped_bytes = 0
    skipped = 0
    unknown_duration = 0
    infos = []
    for i, video in enumerate(videos, 1):
        size = video.stat().st_size
        total_bytes += size
        transcript = transcript_path(video)
        if transcript_ready(transcript):
            skipped += 1
            skipped_bytes += size
            print(f"  [{i}/{len(videos)}] {video.name} — {format_size(size)} — JIZ HOTOVO, preskakuji")
            continue
        duration = get_duration(video)
        if duration is None:
            unknown_duration += 1
        infos.append((video, size, duration))
        print(f"  [{i}/{len(videos)}] {video.name} — {format_size(size)}"
              + (f", {format_duration(duration)}" if duration else ", delka neznama"))

    pending_duration = sum(d for _, _, d in infos if d)
    est_seconds = pending_duration * EST_SECONDS_PER_AUDIO_SECOND
    print()
    print(f"Celkem: {format_size(total_bytes)} dat"
          + (f", {format_duration(pending_duration)} audia ke zpracovani"
             + (f" ({unknown_duration} souboru s neznámou délkou)" if unknown_duration else "")
             if infos else ""))
    if skipped:
        print(f"Preskoceno (prepis jiz existuje): {skipped} souboru, {format_size(skipped_bytes)}")
    if est_seconds:
        print(f"Hruby odhad doby zpracovani: ~{format_duration(est_seconds)}"
              f" (odhad {EST_SECONDS_PER_AUDIO_SECOND:.1f}× délky audia)")
    print()

    if not infos:
        print("Vsechny prepisy jiz existuji — neni co delat.")
        return 0

    # --- Zpracovani ---
    done_bytes = skipped_bytes
    failed = 0
    processed = 0
    lock = threading.Lock()

    def update_title(current_video: Path | None = None, frac: float = 0.0) -> None:
        with lock:
            pct = (done_bytes + frac) / total_bytes * 100 if total_bytes else 100.0
            pct = min(pct, 100.0)
            title = f"Prepis: {pct:.1f}% ({format_size(done_bytes)}/{format_size(total_bytes)})"
            if current_video:
                title += f" — {current_video.name}"
            set_console_title(title)

    def log(msg: str) -> None:
        line = f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}"
        print(line)
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(line + "\n")

    def worker(video: Path, size: int, duration: float | None) -> None:
        nonlocal done_bytes, failed, processed
        transcript = transcript_path(video)
        tmp = video.with_name(video.name + TMP_SUFFIX)

        # Prazdny cilovy soubor = "rezervace": kdyz beh spadne, zustane
        # 0-bajtovy .prepis.txt, ktery se za hotovy nepocita (viz
        # transcript_ready) — dalsi beh video znovu zpracuje. Soubezna
        # instance stejneho skriptu navic hlida prepis_batch.lock.
        try:
            transcript.touch()
        except OSError as e:
            log(f"CHYBA (nelze vytvorit {transcript.name}): {e}")
            failed += 1
            done_bytes += size
            update_title()
            return

        # Pokud po predchozim behu zustal castecny vysledek, pokracujeme
        # od jeho posledni casove znacky (prepis.py dekoduje o 5 s driveji).
        start_od = 0.0
        if tmp.exists():
            try:
                ts = TIMESTAMP_RE.findall(
                    tmp.read_text(encoding="utf-8", errors="replace")
                )
                if ts:
                    start_od = max(float(t) for t in ts)
            except OSError:
                pass
            if start_od > 0:
                log(f"POKRAČOVÁNÍ od {format_duration(start_od)}: {video.name}")

        log(f"ZACATEK: {video} ({format_size(size)})")
        start = time.time()

        proc = subprocess.Popen(
            [sys.executable, str(PREPIS_PY), str(video), str(tmp), str(start_od)],
            cwd=str(video.parent),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )

        try:
            assert proc.stdout is not None
            for line in proc.stdout:
                print(f"    {line}", end="")
                m = TIMESTAMP_RE.search(line)
                if m:
                    frac = 0.0
                    if duration:
                        frac = min(float(m.group(1)) / duration, 0.999) * size
                    update_title(video, frac)
        finally:
            proc.wait()

        if proc.returncode == 0 and tmp.exists():
            try:
                # prazdny vysledek (napr. video bez audia) -> aspon newline,
                # at se soubor pocita za hotovy a nema se donekolola preorderavat
                if tmp.stat().st_size == 0:
                    tmp.write_text("\n", encoding="utf-8")
                replace_with_retry(tmp, transcript)
            except OSError as e:
                failed += 1
                log(f"CHYBA (nelze premenovat vysledek): {e} — {video}")
            else:
                processed += 1
                elapsed = time.time() - start
                log(f"OK ({format_duration(elapsed)}): {video} -> {transcript.name}")
        else:
            failed += 1
            log(f"CHYBA (kod {proc.returncode}), castecny vysledek ponechan: {video}")
            # prazdna rezervace se smaze, at se da prepis zopakovat
            try:
                if transcript.exists() and transcript.stat().st_size == 0:
                    transcript.unlink()
            except OSError:
                pass

        done_bytes += size
        update_title()

    set_console_title("Prepis: start")
    for video, size, duration in infos:
        worker(video, size, duration)

    set_console_title("Prepis: hotovo")
    summary = (f"Dokonceno: {processed} prepsano, {skipped} preskoceno, "
               f"{failed} chyb. Log: {log_path}")
    print(summary)
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] SOUCET: {summary}\n")
    return 0 if failed == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
