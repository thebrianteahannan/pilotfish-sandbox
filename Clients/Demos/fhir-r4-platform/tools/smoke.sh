#!/usr/bin/env bash
set -euo pipefail
BASE="${1:-http://127.0.0.1:8110/eip/rest/fhir}"
SAMPLES="$(dirname "$0")/../samples"
echo "== metadata =="
curl -sf "$BASE/metadata" | head -c 180; echo
echo "== create Patient =="
curl -sf -D- -H 'Content-Type: application/fhir+json' --data-binary @"$SAMPLES/Patient_alice.json" "$BASE/Patient" | head -n 20
echo "== read =="
curl -sf "$BASE/Patient/pat-alice-001" | head -c 180; echo
echo "== search _id =="
curl -sf "$BASE/Patient?_id=pat-alice-001" | head -c 220; echo
echo "== search family=Smith =="
fam="$(curl -sf "$BASE/Patient?family=Smith")"
echo "$fam" | head -c 220; echo
echo "$fam" | grep -q '"total":1\|"total": [1-9]' || { echo "FAIL: family=Smith expected hits"; exit 1; }
echo "== obs =="
curl -sf -H 'Content-Type: application/fhir+json' --data-binary @"$SAMPLES/Observation_heart_rate.json" "$BASE/Observation" | head -c 120; echo
echo "== search Observation patient+code =="
obs="$(curl -sf "$BASE/Observation?patient=Patient/pat-alice-001&code=8867-4")"
echo "$obs" | head -c 240; echo
echo "$obs" | grep -q 'obs-hr-001' || { echo "FAIL: Observation search missed obs-hr-001"; exit 1; }
echo "== transaction Bundle =="
txn="$(curl -sf -H 'Content-Type: application/fhir+json' --data-binary @"$SAMPLES/Bundle_transaction_patient_obs.json" "$BASE/Bundle")"
echo "$txn" | head -c 260; echo
echo "$txn" | grep -q 'transaction-response' || { echo "FAIL: expected transaction-response"; exit 1; }
echo "$txn" | grep -q 'pat-txn-001' || { echo "FAIL: transaction missing pat-txn-001"; exit 1; }
curl -sf "$BASE/Patient/pat-txn-001" | grep -q 'pat-txn-001' || { echo "FAIL: txn patient not persisted"; exit 1; }
echo "== batch Bundle =="
batch="$(curl -sf -H 'Content-Type: application/fhir+json' --data-binary @"$SAMPLES/Bundle_batch_mixed.json" "$BASE/Bundle")"
echo "$batch" | head -c 260; echo
echo "$batch" | grep -q 'batch-response' || { echo "FAIL: expected batch-response"; exit 1; }
echo "$batch" | grep -q '404' || { echo "FAIL: batch should include 404 entry"; exit 1; }
curl -sf "$BASE/Organization/org-batch-001" | grep -q 'org-batch-001' || { echo "FAIL: batch org not persisted"; exit 1; }
echo "== invalid Patient gender (expect 400 OperationOutcome) =="
code="$(curl -s -o /tmp/fhir-bad.json -w '%{http_code}' -H 'Content-Type: application/fhir+json' --data-binary @"$SAMPLES/Patient_invalid_gender.json" "$BASE/Patient")"
echo "HTTP $code"; head -c 280 /tmp/fhir-bad.json; echo
[ "$code" = "400" ] || { echo "FAIL: expected HTTP 400 for invalid gender"; exit 1; }
grep -q 'OperationOutcome' /tmp/fhir-bad.json || { echo "FAIL: expected OperationOutcome body"; exit 1; }
echo OK

