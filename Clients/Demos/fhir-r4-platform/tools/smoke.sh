#!/usr/bin/env bash
set -euo pipefail
BASE="${1:-http://127.0.0.1:8110/eip/rest/fhir}"
echo "== metadata =="
curl -sf "$BASE/metadata" | head -c 180; echo
echo "== create Patient =="
curl -sf -D- -H 'Content-Type: application/fhir+json' --data-binary @"$(dirname "$0")/../samples/Patient_alice.json" "$BASE/Patient" | head -n 20
echo "== read =="
curl -sf "$BASE/Patient/pat-alice-001" | head -c 180; echo
echo "== search _id =="
curl -sf "$BASE/Patient?_id=pat-alice-001" | head -c 220; echo
echo "== search family=Smith =="
fam="$(curl -sf "$BASE/Patient?family=Smith")"
echo "$fam" | head -c 220; echo
echo "$fam" | grep -q '"total":1\|"total": [1-9]' || { echo "FAIL: family=Smith expected hits"; exit 1; }
echo "== obs =="
curl -sf -H 'Content-Type: application/fhir+json' --data-binary @"$(dirname "$0")/../samples/Observation_heart_rate.json" "$BASE/Observation" | head -c 120; echo
echo "== search Observation patient+code =="
obs="$(curl -sf "$BASE/Observation?patient=Patient/pat-alice-001&code=8867-4")"
echo "$obs" | head -c 240; echo
echo "$obs" | grep -q 'obs-hr-001' || { echo "FAIL: Observation search missed obs-hr-001"; exit 1; }
echo OK
