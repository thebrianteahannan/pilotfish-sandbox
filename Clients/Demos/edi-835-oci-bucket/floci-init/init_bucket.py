#!/usr/bin/env python3
"""Create namespace bucket on floci-oci for the EDI 835 demo."""
from __future__ import annotations

import os
import sys
import time

import oci
from oci.exceptions import ServiceError

ENDPOINT = os.environ.get("OCI_ENDPOINT", "http://floci-oci:4599")
NAMESPACE = os.environ.get("OCI_NAMESPACE", "floci-local")
BUCKET = os.environ.get("OCI_BUCKET", "edi-835-payments")
COMPARTMENT = os.environ.get(
    "OCI_COMPARTMENT",
    "ocid1.tenancy.oc1..flocilocaltenancy0000000000000000000000000000000000000000",
)
CONFIG_FILE = os.environ.get("OCI_CONFIG_FILE", "/oci-config/config")


def wait_health(timeout: int = 120) -> None:
    import urllib.request

    deadline = time.time() + timeout
    url = ENDPOINT.rstrip("/") + "/_floci-oci/health"
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(url, timeout=2) as r:
                if r.status == 200:
                    print("floci healthy:", url)
                    return
        except Exception as exc:  # noqa: BLE001
            print("waiting for floci:", exc)
            time.sleep(2)
    raise SystemExit(f"floci not healthy at {url}")


def main() -> int:
    wait_health()
    config = oci.config.from_file(CONFIG_FILE, "DEFAULT")
    client = oci.object_storage.ObjectStorageClient(config, service_endpoint=ENDPOINT)
    ns = client.get_namespace().data
    print("namespace:", ns)
    if ns != NAMESPACE:
        print(f"warning: expected namespace {NAMESPACE}, got {ns}")

    try:
        client.get_bucket(NAMESPACE, BUCKET)
        print(f"bucket exists: {BUCKET}")
    except ServiceError as e:
        if e.status != 404:
            raise
        print(f"creating bucket {BUCKET} ...")
        details = oci.object_storage.models.CreateBucketDetails(
            name=BUCKET,
            compartment_id=COMPARTMENT,
        )
        client.create_bucket(NAMESPACE, details)
        print("created")
    return 0


if __name__ == "__main__":
    sys.exit(main())
