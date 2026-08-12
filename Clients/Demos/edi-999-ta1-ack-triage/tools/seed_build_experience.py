#!/usr/bin/env python3
"""Seed a full narrated build-experience.json for edi-999-ta1-ack-triage, then re-record route steps."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
DEMO = Path(__file__).resolve().parents[1]


def run(args: list[str]) -> None:
    print("+", " ".join(args), flush=True)
    subprocess.check_call(args, cwd=str(ROOT))


def log(**kwargs: str) -> None:
    cmd = ["python3", "tools/log_build_experience.py", "--root", str(DEMO)]
    for k, v in kwargs.items():
        if not v:
            continue
        if k == "alternative":
            continue
        flag = "--" + k.replace("_", "-")
        cmd.extend([flag, v])
    for alt in kwargs.get("_alts") or []:
        cmd.extend(["--alternative", alt])
    # support multi alternatives via separate helper
    run(cmd)


def main() -> None:
    pause = sys.argv[1] if len(sys.argv) > 1 else "1.0"

    run(["python3", "tools/log_build_experience.py", "--root", str(DEMO), "--clear"])
    run(["python3", "tools/publish_route_progress.py", "--root", str(DEMO), "--clear-replay"])

    events = [
        dict(
            kind="phase",
            title="Picked pitch §3: 999 / TA1 acknowledgment triage",
            summary="Net-new Sandbox demo — production-ops story after 837/835 demos.",
            rationale="276/277 was already under construction; 999/TA1 was still uncovered and Low–Med difficulty — ideal for progressive theater.",
            _alts=["Re-deepen existing 835 payment integrity", "Provider roster → FHIR (heavier FHIR surface)"],
            status_message="Experience: chose 999/TA1 pitch from the opportunity PDF…",
        ),
        dict(
            kind="phase",
            title="Scaffolded stage Web UI before any routes",
            summary="docker compose --profile stage on :8129 with live Routes / Timing / Info.",
            rationale="Visibility-first playbook: stakeholders need something to watch in the first minutes, not after a silent 15-minute route grind.",
            _alts=["Finish all routes then open Web UI (old order)"],
            status_message="Experience: stage UI live — waiting for first modules…",
        ),
        dict(
            kind="decision",
            title="Mount demo-eip-root/routes (no spaces in path)",
            summary="Web UI ROUTES_DIR binds to pilotfish/demo-eip-root/routes.",
            rationale="Docker Desktop often mounts paths with spaces (e.g. “EDI 999 TA1 Ack Triage”) as empty folders — that caused the earlier “0 progress” bug on 276/277.",
            _alts=["Bind-mount eip-root/interfaces/<Name With Spaces>/routes"],
            detail="Compose volume:\n  ./pilotfish/demo-eip-root/routes:/routes:ro\n  ./webui/static:/app/static:ro",
            status_message="Experience: fixed Docker mount strategy for live diagrams…",
        ),
        dict(
            kind="decision",
            title="Directory Listener for inbound acks (not HTTP)",
            summary="Poll input/ for .edi / .999 / .ta1; archive after read.",
            rationale="Clearinghouses typically drop acknowledgment files. Directory Listener matches ops reality and is trivial to smoke with sample files. HTTP fits real-time 270/271 façades better.",
            _alts=["HTTP Post listener", "SFTP/JSCH poll"],
            status_message="Experience: chose Directory Listener for ack intake…",
        ),
        dict(
            kind="decision",
            title="Classify with XPath + XSLT (no custom Java)",
            summary="Extract AK9/IK5/TA1 codes → AckDecision XML → Conditional Node Router buckets.",
            rationale="Playbook §3.4: prefer stock PilotFish modules. XPath Evaluation + XSLT + Conditional Node Router are honest demo topology and editable in eiConsole.",
            _alts=["Custom Java AckClassifierProcessor", "External Python sidecar"],
            status_message="Experience: stock PF classify path — no custom module…",
        ),
        dict(
            kind="note",
            title="No SQL Server in this demo (on purpose)",
            summary="999/TA1 triage is file-in / bucket-out — no DB lookup required for the story.",
            rationale="When a demo does use SQL (eligibility, claim scrub, 837 SQL), the Experience log will show INSERT/SELECT excerpts under kind=sql so you can see the data kickoff. This pitch stays file-based to keep the ops-ack story crisp.",
            detail="If we add payer-profile SQL later, expect events like:\nINSERT INTO ack_rules (partner, reject_on_partial) VALUES ('CH01', 1);",
            status_message="Experience: noted — no SQL in this interface…",
        ),
        dict(
            kind="ops",
            title="Record construction snapshots for Replay",
            summary="Each publish writes documents/build-replay/steps/NNNN + experience route events.",
            rationale="If someone misses the live build, Replay construction / Replay full experience can walk the same story later.",
            status_message="Experience: enabling recorded replay…",
        ),
    ]

    for ev in events:
        cmd = [
            "python3",
            "tools/log_build_experience.py",
            "--root",
            str(DEMO),
            "--kind",
            ev["kind"],
            "--title",
            ev["title"],
            "--summary",
            ev.get("summary", ""),
            "--rationale",
            ev.get("rationale", ""),
            "--detail",
            ev.get("detail", ""),
            "--status-message",
            ev.get("status_message", ev["title"]),
        ]
        for alt in ev.get("_alts") or []:
            cmd.extend(["--alternative", alt])
        run(cmd)

    # Rebuild routes progressively (visibility), then replace replay with true
    # module-by-module snapshots (empty → one node at a time).
    run(["python3", str(DEMO / "tools" / "progressive_build_theater.py"), pause])
    run(["python3", "tools/record_module_replay.py", "--root", str(DEMO)])

    run(
        [
            "python3",
            "tools/log_build_experience.py",
            "--root",
            str(DEMO),
            "--kind",
            "docs",
            "--title",
            "Synced module deep-dive PDFs",
            "--summary",
            "documents/module-docs/ now lists Listener / XPath / XSLT / Router / Transport references.",
            "--rationale",
            "Info tab should show real PilotFish documentation for every module on the diagram — not a blank docs folder at the end.",
            "--status-message",
            "Experience: module docs synced…",
        ]
    )
    run(
        [
            "python3",
            "tools/log_build_experience.py",
            "--root",
            str(DEMO),
            "--kind",
            "test",
            "--title",
            "Test plan queued (stage theater)",
            "--summary",
            "Next: tests/plan.json + run_interface_tests.py once EIP profile full is wired.",
            "--detail",
            "Planned cases:\n1) Drop samples/999-partial-accept.edi → rejected bucket + ops report\n2) Drop samples/999-all-accept.edi → accepted\n3) Drop samples/ta1-accept.edi → accepted\n4) Bad/unknown ST → error bucket",
            "--rationale",
            "Show tests in the Experience log even before EIP is up so stakeholders see the validation path is part of the build, not an afterthought.",
            "--status-message",
            "Experience: test plan narrated — ready for Replay full experience",
        ]
    )
    run(
        [
            "python3",
            "tools/update_build_status.py",
            "--root",
            str(DEMO),
            "--complete",
            "--message",
            "Build complete — demo UI ready",
        ]
    )
    print("DONE — open http://localhost:8129/ (demo mode; use Construction view for theater)", flush=True)


if __name__ == "__main__":
    main()
