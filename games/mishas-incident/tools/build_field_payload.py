#!/usr/bin/env python3
"""Build a field-level Misha's incident Korean patch without game JSON files."""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import defaultdict
from pathlib import Path


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def read_jsonl(path: Path):
    with path.open("r", encoding="utf-8-sig") as handle:
        return [json.loads(line) for line in handle if line.strip()]


def path_get(obj, parts):
    current = obj
    for part in parts:
        current = current[part]
    return current


def string_sha256(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest().upper()


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--records", type=Path, required=True)
    parser.add_argument("--clean-data", type=Path, required=True)
    parser.add_argument(
        "--previous-data",
        type=Path,
        action="append",
        required=True,
        help="Accepted prior patch data directory; may be supplied more than once.",
    )
    parser.add_argument("--target-data", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    input_rows = read_jsonl(args.records)
    records = []
    for row in input_rows:
        if "file" in row and "path" in row:
            records.append(row)
            continue
        nested_records = row.get("records") or []
        if not nested_records:
            raise ValueError(f"record row has no patch locations: {row.get('id')!r}")
        for nested in nested_records:
            records.append(
                {
                    "record_id": nested.get("record_id"),
                    "file": nested["file"],
                    "path": nested["path"],
                    "source": row["source"],
                }
            )
    by_file = defaultdict(list)
    for record in records:
        by_file[Path(record["file"]).name].append(record)

    operations = []
    files = []
    unique_targets = set()
    previous_aliases = 0

    for file_name in sorted(by_file):
        clean_path = args.clean_data / file_name
        previous_paths = [directory / file_name for directory in args.previous_data]
        target_path = args.target_data / file_name
        if not (
            clean_path.is_file()
            and all(path.is_file() for path in previous_paths)
            and target_path.is_file()
        ):
            raise FileNotFoundError(file_name)

        clean = read_json(clean_path)
        previous_documents = [read_json(path) for path in previous_paths]
        target = read_json(target_path)
        file_operations = 0

        for record in by_file[file_name]:
            parts = record["path"]
            source_value = path_get(clean, parts)
            previous_values = [path_get(previous, parts) for previous in previous_documents]
            target_value = path_get(target, parts)
            if source_value != record["source"]:
                raise ValueError(
                    f"record/source mismatch: {file_name} {parts!r}"
                )
            if not all(
                isinstance(value, str)
                for value in (source_value, target_value, *previous_values)
            ):
                raise TypeError(f"non-string translation path: {file_name} {parts!r}")

            operation = {
                "file": f"www/data/{file_name}",
                "path": parts,
                "sourceSha256": string_sha256(source_value),
                "target": target_value,
            }
            accepted_previous_hashes = sorted(
                {
                    string_sha256(value)
                    for value in previous_values
                    if value not in {source_value, target_value}
                }
            )
            if accepted_previous_hashes:
                operation["acceptedPreviousSha256s"] = accepted_previous_hashes
                if len(accepted_previous_hashes) == 1:
                    operation["acceptedPreviousSha256"] = accepted_previous_hashes[0]
                previous_aliases += len(accepted_previous_hashes)

            operations.append(operation)
            unique_targets.add(target_value)
            file_operations += 1

        files.append(
            {
                "path": f"www/data/{file_name}",
                "sourceSha256": file_sha256(clean_path),
                "previousSha256": file_sha256(previous_paths[0]),
                "previousSha256s": sorted({file_sha256(path) for path in previous_paths}),
                "targetSha256": file_sha256(target_path),
                "operationCount": file_operations,
            }
        )

    payload = {
        "format": "mishas-incident-field-patch-v1",
        "game": "Misha's incident",
        "language": "ko",
        "sourcePolicy": "SHA-256 only; no original game text or complete game JSON files",
        "operationCount": len(operations),
        "uniqueTargetCount": len(unique_targets),
        "previousAliasCount": previous_aliases,
        "files": files,
        "operations": operations,
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
        newline="\n",
    )
    print(
        json.dumps(
            {
                "output": str(args.output),
                "files": len(files),
                "operations": len(operations),
                "uniqueTargets": len(unique_targets),
                "previousAliases": previous_aliases,
                "bytes": args.output.stat().st_size,
                "sha256": file_sha256(args.output),
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
