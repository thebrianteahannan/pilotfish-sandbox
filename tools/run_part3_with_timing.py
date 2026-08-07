#!/usr/bin/env python3
"""Wait for Part2 to finish, drop Part3 with timing marker, emit bottleneck PDF."""
from __future__ import annotations

import json
import shutil
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IN_DIR = ROOT / "data" / "in"
OUT_DIR = ROOT / "data" / "out"
PARTS = (
    ROOT
    / "Clients"
    / "Med Rec"
    / "data"
    / "Halifax-Historical-File-Issue"
    / "Halifax"
    / "Historical file - Input"
    / "Brian Split Up"
    / "August 5th 2026 Five Parts"
)
DELIVERY = (
    ROOT
    / "Clients"
    / "Med Rec"
    / "data"
    / "Halifax-Historical-File-Issue"
    / "Halifax"
    / "Historical file - Output"
    / "Five_Parts_20260805"
)
MARKER = OUT_DIR / "_active_run_marker.json"


def log(msg: str) -> None:
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)


def out_hl7_ready() -> bool:
    adt = list(OUT_DIR.glob("*.ADT"))
    dft = list(OUT_DIR.glob("*.DFT"))
    return bool(adt) and bool(dft)


def container_ok() -> bool:
    try:
        st = subprocess.check_output(
            ["docker", "inspect", "-f", "{{.State.Status}}", "pilotfish-eip"],
            text=True,
        ).strip()
        return st == "running"
    except subprocess.CalledProcessError:
        return False


def eip_log_now() -> str:
    """Approximate EIP log timestamp (container often UTC)."""
    return datetime.now(timezone.utc).strftime("%m/%d/%y %H:%M:%S")


def save_outputs(part_name: str) -> None:
    dest = DELIVERY / part_name
    dest.mkdir(parents=True, exist_ok=True)
    for p in OUT_DIR.iterdir():
        if p.is_file() and not p.name.startswith("_"):
            shutil.copy2(p, dest / p.name)
    log(f"Saved outputs → {dest}")


def clear_out_files() -> None:
    for p in OUT_DIR.iterdir():
        if p.is_file() and not p.name.startswith("_"):
            p.unlink()


def restart_eip() -> None:
    log("Restarting pilotfish-eip for free heap…")
    subprocess.check_call(["docker", "restart", "pilotfish-eip"])
    for i in range(40):
        try:
            r = subprocess.run(
                ["curl", "-sf", "-o", "/dev/null", "http://127.0.0.1:8080/eip/"],
                check=False,
            )
            if r.returncode == 0:
                log(f"EIP ready (try {i+1})")
                return
        except OSError:
            pass
        time.sleep(3)
    raise RuntimeError("EIP did not become ready")


def drop_part(n: int) -> None:
    demo = PARTS / f"MedReceivables_Demographic_20260629_Historical_Part{n}.txt"
    chg = PARTS / f"MedReceivables_Charges_20260629_Historical_Part{n}.txt"
    for src in (demo, chg):
        if not src.exists():
            raise FileNotFoundError(src)
        shutil.copy2(src, IN_DIR / src.name)
    log(f"Dropped Part{n} into data/in")


def write_marker(label: str, after: str) -> None:
    MARKER.write_text(
        json.dumps(
            {
                "label": label,
                "after": after,
                "started_local": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            },
            indent=2,
        )
    )
    log(f"Timing marker {label} after={after}")


def generate_pdf(label: str, after: str) -> Path:
    pdf = DELIVERY / f"{label}_Bottleneck_Report.pdf"
    cmd = [
        "python3",
        str(ROOT / "tools" / "eip_stage_timings.py"),
        "--after",
        after,
        "--label",
        label,
        "--pdf",
        "--pdf-out",
        str(pdf),
        "--json-out",
        str(DELIVERY / f"{label}_stage_timings.json"),
    ]
    subprocess.check_call(cmd)
    log(f"Bottleneck PDF → {pdf}")
    return pdf


def wait_for_hl7(label: str, timeout_s: int = 3600) -> None:
    log(f"Waiting for {label} ADT+DFT (timeout {timeout_s}s)…")
    start = time.time()
    while time.time() - start < timeout_s:
        if not container_ok():
            raise RuntimeError("pilotfish-eip not running")
        if out_hl7_ready():
            # settle a bit for count files / reports
            time.sleep(40)
            if out_hl7_ready():
                log(f"{label} HL7 outputs present")
                return
        time.sleep(15)
    raise TimeoutError(f"{label} did not produce ADT+DFT in time")


def main() -> None:
    DELIVERY.mkdir(parents=True, exist_ok=True)

    # Phase A: finish Part2 if still running / wait for outputs
    if out_hl7_ready():
        log("HL7 already in data/out — treating as Part2 complete")
    else:
        log("Waiting for Part2 to finish…")
        wait_for_hl7("Part2", timeout_s=3600)

    save_outputs("Part2")
    clear_out_files()
    restart_eip()

    # Phase B: Part3 with timing
    after = eip_log_now()
    time.sleep(2)  # ensure marker precedes first Part3 stage line
    write_marker("Part3", after)
    drop_part(3)
    wait_for_hl7("Part3", timeout_s=3600)
    save_outputs("Part3")
    pdf = generate_pdf("Part3", after)
    log(f"DONE Part3 + PDF: {pdf}")


if __name__ == "__main__":
    main()
