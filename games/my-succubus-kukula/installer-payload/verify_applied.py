from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path


sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
DEFAULT_GAME_ROOT = Path(r"D:\SteamLibrary\steamapps\common\KUKULA")
DEFAULT_PATCH_PATH = HERE / "kukula-recovery.patch.json"

sys.path.insert(0, str(HERE / "tools"))
from apply_patch import extract_script, load_pairs_bytes, sha256  # noqa: E402


HAN_RE = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff]")
TOKEN_RE = re.compile(r"\[@[^\]]+\]|\[[^\]]+\]|%[A-Za-z0-9_]+")


def cjk_keys(data):
    return [key for key, value in data.items() if HAN_RE.search(str(value))]


def duplicate_keys(keys):
    seen = set()
    duplicates = []
    for key in keys:
        if key in seen and key not in duplicates:
            duplicates.append(key)
        seen.add(key)
    return duplicates


def main():
    parser = argparse.ArgumentParser(description="Verify an applied KUKULA Korean field patch")
    parser.add_argument("--root", type=Path, default=DEFAULT_GAME_ROOT, help="KUKULA install root")
    parser.add_argument("--patch", type=Path, default=DEFAULT_PATCH_PATH, help="patch manifest")
    args = parser.parse_args()
    game_root = args.root.resolve()
    patch_path = args.patch.resolve()
    patch = json.loads(patch_path.read_text(encoding="utf-8"))
    lang_spec = next(spec for spec in patch["files"] if spec["kind"] == "json-field-update")
    script_spec = next(spec for spec in patch["files"] if spec["kind"] == "encoded-language-map-field-update")
    lang_path = game_root / Path(lang_spec["path"])
    script_path = game_root / Path(script_spec["path"])
    failures = []

    lang_bytes = lang_path.read_bytes()
    script_bytes = script_path.read_bytes()
    lang_hash = sha256(lang_bytes)
    script_hash = sha256(script_bytes)
    if lang_hash != lang_spec["result_sha256"]:
        failures.append("installed Korean JSON does not match result hash")
    if script_hash != script_spec["result_sha256"]:
        failures.append("installed script.js does not match result hash")
    if lang_bytes.startswith(b"\xef\xbb\xbf"):
        failures.append("installed Korean JSON has UTF-8 BOM")

    lang_data, lang_dupes = load_pairs_bytes(lang_bytes)
    lang_empty = [key for key, value in lang_data.items() if str(value).strip() == ""]
    lang_cjk = cjk_keys(lang_data)
    if lang_dupes:
        failures.append("duplicate Korean JSON keys")
    if lang_empty:
        failures.append("empty Korean JSON values")
    if lang_cjk:
        failures.append("CJK remains in Korean JSON values")

    script_raw = script_bytes.decode("utf-8")
    _, _, _, _, _, script_data = extract_script(script_raw)
    script_keys = list(script_data.keys())
    script_dupes = duplicate_keys(script_keys)
    expected_keys = [op["key"] for op in script_spec["operations"] if op["op"] == "insert_after"]
    script_missing = [key for key in expected_keys if key not in script_data]
    script_cjk = cjk_keys(script_data)
    if script_dupes:
        failures.append("duplicate embedded script map keys")
    if script_missing:
        failures.append("missing embedded script map keys: " + ", ".join(script_missing))
    if script_cjk:
        failures.append("CJK remains in embedded Korean story values")
    if len(script_data) != script_spec["result_map_count"]:
        failures.append("embedded script map count mismatch")

    token_mismatches = []
    for spec in patch["files"]:
        for op in spec["operations"]:
            if op["op"] != "update":
                continue
            if sorted(TOKEN_RE.findall(str(op["old"]))) != sorted(TOKEN_RE.findall(str(op["new"]))):
                token_mismatches.append(op["key"])
    if token_mismatches:
        failures.append("control-token mismatch in patch operations")

    # Reverse dry-run checks that the installed result can be rolled back
    # without writing anything.  The timestamped backups made during apply
    # remain the primary recovery copies beside the game files.
    rollback_preview = {}
    try:
        from apply_patch import apply_json_file, apply_script_file  # noqa: E402

        rollback_preview["language"] = apply_json_file(lang_path, lang_spec, True, False, False)
        rollback_preview["script"] = apply_script_file(script_path, script_spec, True, False, False)
        rollback_preview["status"] = "PASS"
    except Exception as exc:
        rollback_preview["status"] = "FAIL"
        rollback_preview["error"] = str(exc)
        failures.append("reverse dry-run failed: " + str(exc))

    backup_info = []
    for target in (lang_path, script_path):
        candidates = sorted(
            target.parent.glob(target.name + ".codex-kukula-recovery-*.bak"),
            key=lambda item: item.stat().st_mtime,
            reverse=True,
        )
        if not candidates:
            failures.append("no apply backup found beside: " + str(target))
            backup_info.append({"target": str(target), "backups": []})
            continue
        backup_info.append({
            "target": str(target),
            "backups": [
                {
                    "path": str(path),
                    "sha256": sha256(path.read_bytes()),
                    "size": path.stat().st_size,
                    "modified": datetime.fromtimestamp(path.stat().st_mtime).astimezone().isoformat(),
                }
                for path in candidates
            ],
        })

    semantic_samples = []
    for key in ("显示模式", "材质", "环境声效", "我", "星之瞳"):
        semantic_samples.append({"file": lang_spec["path"], "source_key": key, "korean": lang_data.get(key)})
    for key in ("end_1_8", "end_7_2", "true_end_31", "true_end_75", "true_end_79"):
        semantic_samples.append({"file": script_spec["path"], "source_key": key, "korean": script_data.get(key)})

    report = {
        "status": "PASS" if not failures else "FAIL",
        "checked_at_local": datetime.now().astimezone().isoformat(),
        "game": patch["game"],
        "installed": True,
        "translation_model_used": False,
        "targets": {
            "language": {
                "path": str(lang_path),
                "sha256": lang_hash,
                "expected_sha256": lang_spec["result_sha256"],
                "key_count": len(lang_data),
                "duplicate_keys": lang_dupes,
                "empty_values": lang_empty,
                "cjk_residual": lang_cjk,
                "bom": lang_bytes.startswith(b"\xef\xbb\xbf"),
            },
            "script": {
                "path": str(script_path),
                "sha256": script_hash,
                "expected_sha256": script_spec["result_sha256"],
                "key_count": len(script_data),
                "expected_key_count": script_spec["result_map_count"],
                "duplicate_keys": script_dupes,
                "missing_keys": script_missing,
                "cjk_residual": script_cjk,
                "end_1_8": script_data.get("end_1_8"),
            },
        },
        "control_tokens": {"mismatches": token_mismatches, "pattern": TOKEN_RE.pattern},
        "rollback_dry_run": rollback_preview,
        "apply_backups": backup_info,
        "semantic_samples": semantic_samples,
        "failures": failures,
        "game_files_modified_by_verifier": False,
    }
    out = HERE / "runtime-apply-qa.json"
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    (HERE / "runtime-apply-qa.md").write_text(
        "# KUKULA applied-patch verification\n\n"
        f"- Status: **{report['status']}**\n"
        f"- Installed targets: `한국어.json` {len(lang_data)} keys; `script.js` map {len(script_data)} keys.\n"
        f"- Hashes: language `{lang_hash}`; script `{script_hash}`.\n"
        f"- Empty/duplicate/CJK values: {len(lang_empty)}/{len(lang_dupes)}/{len(lang_cjk) + len(script_cjk)}.\n"
        f"- Control-token mismatches: {len(token_mismatches)}; rollback dry-run: **{rollback_preview['status']}**.\n"
        "- Apply backups are retained beside the two game files; no game files were modified by this verifier.\n"
        "- Detailed evidence: `runtime-apply-qa.json`.\n",
        encoding="utf-8",
        newline="\n",
    )
    print(json.dumps({
        "status": report["status"],
        "failures": failures,
        "language_keys": len(lang_data),
        "script_keys": len(script_data),
        "language_cjk": len(lang_cjk),
        "script_cjk": len(script_cjk),
        "rollback_dry_run": rollback_preview["status"],
        "backups": backup_info,
    }, ensure_ascii=False, indent=2))
    raise SystemExit(0 if report["status"] == "PASS" else 1)


if __name__ == "__main__":
    main()
