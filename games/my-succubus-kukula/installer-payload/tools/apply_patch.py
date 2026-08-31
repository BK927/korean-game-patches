from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
from collections import OrderedDict
from datetime import datetime
from pathlib import Path
from urllib.parse import quote, unquote
from uuid import uuid4


HERE = Path(__file__).resolve().parent.parent
DEFAULT_PATCH = HERE / "kukula-recovery.patch.json"
DEFAULT_ROOT = Path(r"D:\SteamLibrary\steamapps\common\KUKULA")
BEGIN_MARKER = "// Codex Korean patch override: begin"
END_MARKER = "// Codex Korean patch override: end"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def stable_json(data, newline="\n") -> bytes:
    text = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    if newline != "\n":
        text = text.replace("\n", newline)
    return text.encode("utf-8")


def load_pairs_bytes(data: bytes):
    duplicates = []

    def hook(pairs):
        out = OrderedDict()
        for key, value in pairs:
            if key in out:
                duplicates.append(key)
            out[key] = value
        return out

    return json.loads(data.decode("utf-8-sig"), object_pairs_hook=hook), duplicates


def backup(path: Path):
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    out = path.with_name(path.name + ".codex-kukula-recovery-" + stamp + ".bak")
    if out.exists():
        out = path.with_name(path.name + ".codex-kukula-recovery-" + stamp + "-" + uuid4().hex[:8] + ".bak")
    shutil.copy2(path, out)
    return out


def write_checked(path: Path, data: bytes, expected: str, do_write: bool, make_backup: bool):
    actual = sha256(data)
    if actual != expected:
        raise ValueError("computed result hash does not match patch manifest for %s: actual=%s expected=%s" % (path, actual, expected))
    if do_write:
        saved_backup = str(backup(path)) if make_backup else None
        temporary = path.with_name("." + path.name + "." + uuid4().hex + ".tmp")
        try:
            temporary.write_bytes(data)
            if sha256(temporary.read_bytes()) != expected:
                raise ValueError("temporary write hash mismatch for " + str(path))
            temporary.replace(path)
        finally:
            if temporary.exists():
                temporary.unlink()
        return saved_backup
    return None


def apply_json_file(path: Path, spec, reverse: bool, do_write: bool, make_backup: bool):
    before = path.read_bytes()
    expected_before = spec["result_sha256"] if reverse else spec["base_sha256"]
    expected_after = spec["base_sha256"] if reverse else spec["result_sha256"]
    if sha256(before) != expected_before:
        raise ValueError("base hash mismatch for " + str(path) + ": expected " + expected_before)
    data, duplicates = load_pairs_bytes(before)
    if duplicates:
        raise ValueError("duplicate JSON keys in " + str(path) + ": " + ", ".join(duplicates))
    operations = list(reversed(spec["operations"])) if reverse else spec["operations"]
    for op in operations:
        if op.get("op") != "update":
            raise ValueError("unsupported JSON operation: " + str(op))
        key = op["key"]
        expected = op["new"] if reverse else op["old"]
        replacement = op["old"] if reverse else op["new"]
        if key not in data:
            raise ValueError("JSON key missing: " + key)
        if data[key] != expected:
            raise ValueError("JSON value mismatch for key " + key)
        data[key] = replacement
    newline = spec.get("base_newline", "\n") if reverse else spec.get("result_newline", "\n")
    after = stable_json(data, newline=newline)
    saved_backup = write_checked(path, after, expected_after, do_write, make_backup)
    return {
        "path": str(path),
        "before_sha256": sha256(before),
        "after_sha256": sha256(after),
        "operations": len(operations),
        "backup": saved_backup,
        "written": do_write,
    }


def extract_script(raw_text: str):
    begin = quote(BEGIN_MARKER, safe="")
    end = quote(END_MARKER, safe="")
    start = raw_text.find(begin)
    end_pos = raw_text.find(end, start)
    if start < 0 or end_pos < 0:
        raise ValueError("script.js override markers not found")
    stop = end_pos + len(end)
    encoded = raw_text[start:stop]
    decoded = unquote(encoded)
    marker = "GameLang.en_lang = "
    map_start = decoded.find(marker)
    if map_start < 0:
        raise ValueError("GameLang.en_lang not found")
    map_start += len(marker)
    map_end = decoded.find("};", map_start)
    if map_end < 0:
        raise ValueError("GameLang.en_lang closing brace not found")
    map_end += 1
    map_text = decoded[map_start:map_end]
    parse_text = re.sub(r",\s*}$", "}", map_text, count=1)
    values, duplicates = load_pairs_bytes(parse_text.encode("utf-8"))
    if duplicates:
        raise ValueError("duplicate keys in embedded map: " + ", ".join(duplicates))
    return start, stop, decoded, map_start, map_end, values


def render_map(values):
    lines = ["{"]
    for key, value in values.items():
        lines.append("  %s: %s," % (json.dumps(key, ensure_ascii=False), json.dumps(value, ensure_ascii=False)))
    lines.append("}")
    return "\n".join(lines)


def apply_script_file(path: Path, spec, reverse: bool, do_write: bool, make_backup: bool):
    before = path.read_bytes()
    expected_before = spec["result_sha256"] if reverse else spec["base_sha256"]
    expected_after = spec["base_sha256"] if reverse else spec["result_sha256"]
    if sha256(before) != expected_before:
        raise ValueError("base hash mismatch for " + str(path) + ": expected " + expected_before)
    raw_text = before.decode("utf-8")
    start, stop, decoded, map_start, map_end, values = extract_script(raw_text)
    map_hash = sha256(stable_json(values))
    expected_map = spec["result_map_sha256"] if reverse else spec["base_map_sha256"]
    if map_hash != expected_map:
        raise ValueError("embedded map hash mismatch for " + str(path))
    operations = list(reversed(spec["operations"])) if reverse else spec["operations"]
    for op in operations:
        if op["op"] == "update":
            key = op["key"]
            expected = op["new"] if reverse else op["old"]
            replacement = op["old"] if reverse else op["new"]
            if key not in values or values[key] != expected:
                raise ValueError("embedded map value mismatch for key " + key)
            values[key] = replacement
        elif op["op"] == "insert_after":
            key = op["key"]
            if reverse:
                if key not in values or values[key] != op["new"]:
                    raise ValueError("inserted map value mismatch for key " + key)
                del values[key]
            else:
                if key in values:
                    raise ValueError("embedded map key already exists: " + key)
                after_key = op["after"]
                if after_key not in values:
                    raise ValueError("insert anchor missing: " + after_key)
                ordered = OrderedDict()
                for existing_key, value in values.items():
                    ordered[existing_key] = value
                    if existing_key == after_key:
                        ordered[key] = op["new"]
                values = ordered
        else:
            raise ValueError("unsupported script operation: " + str(op))
    new_map = render_map(values)
    new_decoded = decoded[:map_start] + new_map + decoded[map_end:]
    new_encoded = quote(new_decoded, safe="")
    after = (raw_text[:start] + new_encoded + raw_text[stop:]).encode("utf-8")
    saved_backup = write_checked(path, after, expected_after, do_write, make_backup)
    return {
        "path": str(path),
        "before_sha256": sha256(before),
        "after_sha256": sha256(after),
        "operations": len(operations),
        "map_count": len(values),
        "backup": saved_backup,
        "written": do_write,
    }


def main():
    parser = argparse.ArgumentParser(description="Apply or roll back the KUKULA field-only Korean patch")
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT, help="KUKULA install root")
    parser.add_argument("--patch", type=Path, default=DEFAULT_PATCH, help="patch manifest")
    parser.add_argument("--reverse", action="store_true", help="roll back the patch")
    parser.add_argument("--apply", action="store_true", help="write files; without this flag only validate")
    parser.add_argument("--dry-run", action="store_true", help="validate without writing (default)")
    parser.add_argument("--no-backup", action="store_true", help="do not make timestamped backups when applying")
    args = parser.parse_args()
    patch = json.loads(args.patch.read_text(encoding="utf-8"))
    do_write = bool(args.apply) and not args.dry_run
    specs = list(reversed(patch["files"])) if args.reverse else patch["files"]

    def run_spec(spec, write, make_backup):
        path = args.root / Path(spec["path"])
        if not path.exists():
            raise SystemExit("target file not found: " + str(path))
        if spec["kind"] == "json-field-update":
            return apply_json_file(path, spec, args.reverse, write, make_backup)
        if spec["kind"] == "encoded-language-map-field-update":
            return apply_script_file(path, spec, args.reverse, write, make_backup)
        raise SystemExit("unsupported patch kind: " + spec["kind"])

    # Validate every source and compute every result before the first write so a
    # late base-hash mismatch cannot leave a half-applied installation.
    preflight = [run_spec(spec, False, False) for spec in specs]
    if not do_write:
        print(json.dumps({"status": "PASS", "mode": "dry-run", "reverse": args.reverse, "files": preflight}, ensure_ascii=False, indent=2))
        return

    results = []
    try:
        for spec in specs:
            results.append(run_spec(spec, True, not args.no_backup))
    except Exception as apply_error:
        rollback_errors = []
        for result in reversed(results):
            backup_path = result.get("backup")
            if not backup_path:
                rollback_errors.append("no backup available for " + result["path"])
                continue
            target = Path(result["path"])
            try:
                shutil.copy2(Path(backup_path), target)
                restored = sha256(target.read_bytes())
                if restored != result["before_sha256"]:
                    raise ValueError("restored hash mismatch: " + restored)
            except Exception as rollback_error:
                rollback_errors.append(result["path"] + ": " + str(rollback_error))
        if rollback_errors:
            raise RuntimeError(str(apply_error) + "; automatic rollback also failed: " + "; ".join(rollback_errors)) from apply_error
        raise RuntimeError(str(apply_error) + "; already written files were restored from verified backups") from apply_error

    print(json.dumps({"status": "PASS", "mode": "apply", "reverse": args.reverse, "preflight": "PASS", "files": results}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
