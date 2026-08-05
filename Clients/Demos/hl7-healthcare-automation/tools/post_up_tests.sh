#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
echo "== post-up tests for $(basename "$ROOT") =="
python3 tools/export_test_plan_pdf.py || true
python3 tools/run_interface_tests.py --wait
echo "Results: documents/test-results.html"

