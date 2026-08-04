#!/usr/bin/env python3
"""Upload Top_100_Male_Music_Artists.pdf to Google Drive (CursorFiles)."""

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

FOLDER_NAME = "CursorFiles"
ROOT = Path(__file__).resolve().parent
file_path = ROOT / "Top_100_Male_Music_Artists.pdf"
filename = file_path.name

if "Google Drive" not in os.environ:
    print("MISSING_SECRET", file=sys.stderr)
    sys.exit(2)
if not file_path.exists():
    print("MISSING_PDF", file_path, file=sys.stderr)
    sys.exit(3)

raw = json.loads(os.environ["Google Drive"])
client_id = raw["client_id"]
while client_id.count(".apps.googleusercontent.com") > 1:
    client_id = client_id.replace(
        ".apps.googleusercontent.com.apps.googleusercontent.com",
        ".apps.googleusercontent.com",
    )
creds = Credentials(
    token=None,
    refresh_token=raw["refresh_token"],
    token_uri="https://oauth2.googleapis.com/token",
    client_id=client_id,
    client_secret=raw["client_secret"],
)
creds.refresh(Request())
service = build("drive", "v3", credentials=creds)


def get_folder_id(service):
    q = (
        "mimeType='application/vnd.google-apps.folder' "
        f"and name='{FOLDER_NAME}' and trashed=false"
    )
    found = (
        service.files()
        .list(q=q, spaces="drive", fields="files(id,name,createdTime)", pageSize=100)
        .execute()
        .get("files", [])
    )
    if found:
        found.sort(key=lambda f: f.get("createdTime", ""))
        return found[0]["id"]
    folder = (
        service.files()
        .create(
            body={"name": FOLDER_NAME, "mimeType": "application/vnd.google-apps.folder"},
            fields="id",
        )
        .execute()
    )
    return folder["id"]


def unique_name(service, folder_id, filename: str) -> str:
    stem = Path(filename).stem
    suffix = Path(filename).suffix
    candidate = filename
    n = 0
    while True:
        q = f"'{folder_id}' in parents and name='{candidate}' and trashed=false"
        existing = (
            service.files()
            .list(q=q, spaces="drive", fields="files(id)", pageSize=1)
            .execute()
            .get("files", [])
        )
        if not existing:
            return candidate
        n += 1
        ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        candidate = f"{stem}_{ts}{suffix}" if n == 1 else f"{stem}_{ts}_{n}{suffix}"


folder_id = get_folder_id(service)
final_name = unique_name(service, folder_id, filename)
media = MediaFileUpload(str(file_path), mimetype="application/pdf", resumable=True)
uploaded = (
    service.files()
    .create(
        body={"name": final_name, "parents": [folder_id]},
        media_body=media,
        fields="id, name, webViewLink, parents",
    )
    .execute()
)
print(uploaded["name"])
print(uploaded["webViewLink"])
print(uploaded["id"])
