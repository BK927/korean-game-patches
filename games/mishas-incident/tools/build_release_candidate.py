#!/usr/bin/env python3
"""Validate and deterministically package the Misha's incident patch."""

from __future__ import annotations

import hashlib
import json
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "dist"
ARCHIVE_NAME = "Mishas_incident_KoreanPatch_0.1.0-rc1.zip"
FILES = [
    "README.md",
    "LEGAL-NOTICE.txt",
    "RELEASE-NOTES.md",
    "TRANSLATION-QA.md",
    "TRANSLATION-QA.json",
    "manifest.json",
    "install.ps1",
    "restore.ps1",
    "verify.ps1",
    "payload/translations.json",
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def main() -> None:
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    payload_path = ROOT / manifest["payload"]["path"]
    payload = json.loads(payload_path.read_text(encoding="utf-8-sig"))

    if payload["format"] != manifest["payload"]["format"]:
        raise SystemExit("payload format mismatch")
    if sha256(payload_path) != manifest["payload"]["sha256"]:
        raise SystemExit("payload SHA-256 mismatch")
    if payload_path.stat().st_size != manifest["payload"]["bytes"]:
        raise SystemExit("payload size mismatch")
    checks = {
        "files": len(payload["files"]),
        "operations": len(payload["operations"]),
        "uniqueTargets": len({item["target"] for item in payload["operations"]}),
        "acceptedPreviousAliases": sum(
            len(item.get("acceptedPreviousSha256s", []))
            for item in payload["operations"]
        ),
    }
    for key, value in checks.items():
        if value != manifest["payload"][key]:
            raise SystemExit(f"payload {key} mismatch: {value}")

    DIST.mkdir(parents=True, exist_ok=True)
    archive = DIST / ARCHIVE_NAME
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as output:
        for relative in FILES:
            source = ROOT / relative
            if not source.is_file():
                raise SystemExit(f"missing release file: {relative}")
            info = zipfile.ZipInfo(
                f"Mishas_incident_KoreanPatch_0.1.0-rc1/{relative}",
                date_time=(1980, 1, 1, 0, 0, 0),
            )
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            output.writestr(info, source.read_bytes(), compresslevel=9)

    digest = sha256(archive)
    checksum = archive.with_suffix(archive.suffix + ".sha256")
    checksum.write_text(f"{digest}  {archive.name}\n", encoding="ascii", newline="\n")
    print(json.dumps({"archive": str(archive), "bytes": archive.stat().st_size, "sha256": digest}, indent=2))


if __name__ == "__main__":
    main()
