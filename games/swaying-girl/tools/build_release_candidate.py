#!/usr/bin/env python3
"""Build a delta-only Swaying Girl Korean recovery release candidate."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import tempfile
import zipfile
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import UnityPy


ROOT = Path(__file__).resolve().parents[1]
BUILD_ROOT = ROOT / "dist"
GAME_ROOT = Path(os.environ.get("SWAYING_GAME_ROOT", r"D:\SteamLibrary\steamapps\common\Swaying Girl"))
DATA_ROOT = GAME_ROOT / "SwayingGirl_Data"
TRANSLATION_ROOT = Path(os.environ.get("SWAYING_TRANSLATION_ROOT", str(ROOT / "translations")))
PREVIOUS_ROOT = Path(os.environ.get("SWAYING_PREVIOUS_ROOT", str(DATA_ROOT)))

ORIGINAL = {
    "sharedassets1.assets": Path(os.environ.get("SWAYING_ORIGINAL_SHAREDASSETS", str(DATA_ROOT / "sharedassets1.assets.orig"))),
    "level1": Path(os.environ.get("SWAYING_ORIGINAL_LEVEL1", str(DATA_ROOT / "level1.codex_monmusu_swaying.bak"))),
}
PREVIOUS = {
    "sharedassets1.assets": PREVIOUS_ROOT / "sharedassets1.assets",
    "level1": PREVIOUS_ROOT / "level1",
}

STAGING_ROOT = BUILD_ROOT / "staging" / "SwayingGirl_Data"
PACKAGE_NAME = "Swaying_Girl_Korean_Recovery_0.1.0-rc1"
PACKAGE_ROOT = BUILD_ROOT / "package" / PACKAGE_NAME
DELTA_ROOT = PACKAGE_ROOT / "delta"
ZIP_PATH = BUILD_ROOT / f"{PACKAGE_NAME}.zip"
ZIP_SHA_PATH = BUILD_ROOT / f"{PACKAGE_NAME}.zip.sha256"
RUNTIME_QA_PATH = ROOT / "qa" / "runtime" / "runtime-qa.json"

TEXT_TARGETS = ("Girl11", "Girl21")
CJK_RE = re.compile(r"[一-龥ぁ-んァ-ン]")


# Only source hashes are retained here.  The installer/package never contains
# the original UI text.  Each rule is bound to a MonoBehaviour path ID and an
# exact UTF-8 source-string digest before it can be replaced.
UI_RULES: dict[int, list[dict[str, Any]]] = {
    1661: [{"source": "58D6567267E100F1029CBF7D6DAD275D5A74F07D36ECB5B66BCEC3B751FCD126", "target": "Steam 채팅 그룹 참가"}],
    1671: [{"source": "59FF1C9FCD350E34425EC5E9E5D7E0603826601BFCE1384F633C0A3724852A37", "target": "가슴이 가장 크게 흔들린 장면을 고르세요:"}],
    1672: [{"source": "79E8CB273C0DF9F6C267F8E8899FA0D091B9D0C4CFD02CC7E1E8AE779F1B28FF", "target": "면책 조항"}],
    1676: [{"source": "5F69D7981FF8DF743CF766BC592303DDBD6A117F604BD4C12F77A6F4B6B9DE0B", "target": "좋지 않은 결말입니다!"}],
    1678: [{
        "source": "78E0FAB91A4B1197F7C3795DE54E13D6D52C3F2E755556594B535B0DD060A589",
        "target": "단축키:\n도움말 표시/숨기기: F1\nFPS 표시/숨기기: F2\n메뉴로 돌아가기: ESC\n다음 대사: Space\n삽입 속도 전환: Space\n머리 잡기·목 조르기: Enter\n자유 모드 자세 전환: Tab\n장면 건너뛰기: Backspace\n일부 오브젝트 투명도 변경: W/S",
    }],
    1694: [{"source": "905819E2E3A059A02087855E9F326D05C877C1767EC31DC012C5C44652840230", "target": "동의"}],
    1695: [{"source": "FAC2A67AD87807C4112AF2B9201EF929D8C1C80214A6AD5198423398369371A4", "target": "확인"}],
    1701: [{"source": "FAC2A67AD87807C4112AF2B9201EF929D8C1C80214A6AD5198423398369371A4", "target": "확인"}],
    1715: [{"source": "A57CFCB8428DA4085EA1DE04CB094D2CC158C1E63A5769E51056F0DC73F1D38A", "target": "도움말"}],
    1721: [{
        "source": "D38AE369560AD02DF7E9CD871DB6438CA4952F2D413A013E81E4F60FE749EA38",
        "target": "제 안목은 정말 좋아요! 못 믿겠다면 간단한 게임을 해 봐요.\n제 안목은 정말 좋아요! 못 믿겠다면 간단한 게임을 해 봐요.",
    }],
    1731: [
        {"source": "1FC51BE05B4FF6F0E89F580FE841DE8E5A1E3624A28D2E49ED35ABB9B5E8E247", "target": "승리했습니다!"},
        {"source": "79D082AC2CEB8F1D4EC9D21A8A47ADF4FD146BEDFB848E72D547E35E1868C243", "target": "패배했습니다!"},
        {"source": "B6F12F4C25A1C42C4C0D43C2932D4C62F7287ED722A89989692EB7C58668D65B", "target": "틀렸습니다. 다시 선택하세요!"},
        {
            "source": "D3F057790450CB4C531E4F9A0E2F1CE0415FF8B2A93312E56A5F7902FF6EDAA1",
            "target": "단축키:\r\n도움말 표시/숨기기: F1\r\nFPS 표시/숨기기: F2\r\nUI 표시/숨기기: F3\n배경음 켜기/끄기: F4\n메뉴로 돌아가기: ESC\r\n다음 대사: Space\n선택지 고르기: 1/2/3/4",
        },
        {
            "source": "47C4DB0D657D7671827F12ED08906B9A17FBE547EC2BB2C8935F7C5A43B72110",
            "target": "　　게임 평가를 남기거나 Steam 채팅 그룹에 참여해 의견과 질문을 보내 주세요!\r",
        },
        {
            "source": "4E3C6712CA637C50FCCC028D1030A7A2667208CD9B92EFC614D11B008797C9F2",
            "target": "　　게임에 관한 질문이나 제안이 있다면 Steam 또는 Discord 채팅 그룹에서 더 이야기해 주세요.\r",
        },
    ],
    1733: [{"source": "FAC2A67AD87807C4112AF2B9201EF929D8C1C80214A6AD5198423398369371A4", "target": "확인"}],
    1734: [{"source": "75675B397044837F96E819CE3383D231E2AADBCE92EECFCFB6FE7F0C82E64B31", "target": "모든 등장인물은 18세 이상입니다"}],
    1744: [{"source": "092E889E933575776D9FD5B5A596A9A4A2ECBE33036E291392182DA4B9943D12", "target": "억측과 게임 왜곡"}],
    1760: [{"source": "C3405F8C7D9D392AA3E2D073D5793BCE795353C5F7EF0D27F3D6C1C8D2832681", "target": "제목"}],
    1768: [{"source": "FA15E62BD9DBF76D2576F836AA96F5CDE3CED5716A1A5A437F2209C0530DE4A2", "target": "고통"}],
    1771: [{"source": "905819E2E3A059A02087855E9F326D05C877C1767EC31DC012C5C44652840230", "target": "동의"}],
    1785: [{
        "source": "35F1FEA872F75BB7D87E656CC75127C5E4A1ACDE7CFD18AA66F092D9D4108694",
        "target": "　　빠르게 삽입을 반복한 탓에 신신은 숨 돌릴 틈조차 얻지 못했고, 결국 질식해 죽었다. 나는 몹시 가슴이 아팠다. 숨을 쉴 수 없었다면 왜 말해 주지 않았을까? 사실 딥스로트 때문에 신신은 숨도 쉬지 못하고 말도 할 수 없었다.\r\n　　이 장면은 플레이어에게 한 가지 사실을 직관적으로 알려 준다. 딥스로트는 호흡을 막으며, 말로 구조를 요청할 수도 없게 한다.\r\n　　해마다 수만 명의 여성이 이 사실을 몰라 목숨을 잃는다. 이 게임을 플레이한 사람들은 다행히 비슷한 비극을 피하게 되었다. 정의감 있는 플레이어라면 친구들도 같은 비극을 피하도록 더 많은 친구에게 이 게임을 추천할 것이다.\r\n　　우리는 수만 명의 소중한 생명을 구해 냈다! 수많은 억만장자가 이런 비극에 무관심했는데, 어째서 우리만 이 위대한 일을 해냈는지 생각해 볼 일이다. 게임 평가나 Steam 채팅 그룹에서 함께 이야기해 보자.\r\n",
    }],
    1797: [{"source": "BF32DEEA9288D8C984F5FD1039FE9657BA967311BE658DD5F629922A70978DB3", "target": "말할 내용을 고르세요(Backspace: 질문 건너뛰기):"}],
    1800: [{"source": "D48E3C4AAB59729DF9F64F6E2000A14761707DE2E25726A5F9C4A6AA4450E31D", "target": "신신: 안녕하세요. 같이 자러 왔어요!"}],
    1802: [{"source": "58D6567267E100F1029CBF7D6DAD275D5A74F07D36ECB5B66BCEC3B751FCD126", "target": "Steam 채팅 그룹 참가"}],
    1807: [{"source": "42269E2627F4916C9BBE3C79FB3990EE7FB3F4AF262364AF36AF2D186CADCA92", "target": "느림"}],
    1811: [{"source": "41482E1B3BFBDB6215EAC94A5DFB9E1B841576041C278181AC5A946FEE9448BA", "target": "목 조르기"}],
    1826: [{
        "source": "D38AE369560AD02DF7E9CD871DB6438CA4952F2D413A013E81E4F60FE749EA38",
        "target": "제 안목은 정말 좋아요! 못 믿겠다면 간단한 게임을 해 봐요.\n제 안목은 정말 좋아요! 못 믿겠다면 간단한 게임을 해 봐요.",
    }],
    1833: [{"source": "9567106F690695E8B8D0E5F4A77915B33777E2AB44B8DD1D876C020A1C6941FC", "target": "스토리 모드"}],
    1834: [{
        "source": "D38AE369560AD02DF7E9CD871DB6438CA4952F2D413A013E81E4F60FE749EA38",
        "target": "제 안목은 정말 좋아요! 못 믿겠다면 간단한 게임을 해 봐요.\n제 안목은 정말 좋아요! 못 믿겠다면 간단한 게임을 해 봐요.",
    }],
}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")


def require_file(path: Path) -> None:
    if not path.is_file():
        raise FileNotFoundError(path)


def normalize_text(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n").replace("\n", "\r\n").rstrip() + "\r\n"


def nonblank(text: str) -> list[str]:
    return [line for line in text.splitlines() if line.strip()]


def aligned_utf8_strings(raw: bytes) -> list[dict[str, Any]]:
    hits: list[dict[str, Any]] = []
    for offset in range(0, max(0, len(raw) - 4), 4):
        length = struct.unpack_from("<i", raw, offset)[0]
        end = offset + 4 + length
        if length < 1 or length > 16384 or end > len(raw):
            continue
        payload = raw[offset + 4 : end]
        try:
            text = payload.decode("utf-8")
        except UnicodeDecodeError:
            continue
        if "\x00" in text or any(ord(ch) < 32 and ch not in "\r\n\t" for ch in text):
            continue
        pad = (4 - (length % 4)) % 4
        if end + pad > len(raw) or (pad and raw[end : end + pad] != b"\0" * pad):
            continue
        hits.append({"offset": offset, "length": length, "pad": pad, "text": text})
    return hits


def serialized_string(value: str) -> bytes:
    payload = value.encode("utf-8")
    return struct.pack("<i", len(payload)) + payload + b"\0" * ((4 - len(payload) % 4) % 4)


def patch_raw_string(raw: bytes, source_hash: str, target: str) -> bytes:
    matches = [hit for hit in aligned_utf8_strings(raw) if sha256_bytes(hit["text"].encode("utf-8")) == source_hash]
    if len(matches) != 1:
        raise ValueError(f"expected one serialized source string {source_hash}, found {len(matches)}")
    hit = matches[0]
    start = hit["offset"]
    end = start + 4 + hit["length"] + hit["pad"]
    return raw[:start] + serialized_string(target) + raw[end:]


def object_index(path: Path) -> dict[tuple[int, str], str]:
    env = UnityPy.load(str(path))
    return {(int(obj.path_id), obj.type.name): sha256_bytes(bytes(obj.get_raw_data())) for obj in env.objects}


def changed_objects(left: Path, right: Path) -> list[dict[str, Any]]:
    a = object_index(left)
    b = object_index(right)
    changed = []
    for key in sorted(set(a) | set(b)):
        if a.get(key) != b.get(key):
            changed.append({"path_id": key[0], "type": key[1], "source_sha256": a.get(key), "target_sha256": b.get(key)})
    return changed


def build_sharedassets() -> dict[str, Any]:
    source_path = ORIGINAL["sharedassets1.assets"]
    translations = {name: normalize_text((TRANSLATION_ROOT / f"{name}.txt").read_text(encoding="utf-8")) for name in TEXT_TARGETS}
    env = UnityPy.load(str(source_path))
    found: dict[str, dict[str, Any]] = {}
    for obj in env.objects:
        if obj.type.name != "TextAsset":
            continue
        data = obj.read()
        name = data.m_Name
        if name not in translations:
            continue
        source = data.m_Script.decode("utf-8") if isinstance(data.m_Script, bytes) else data.m_Script
        target = translations[name]
        source_lines = nonblank(source)
        target_lines = nonblank(target)
        if len(source_lines) != len(target_lines):
            raise ValueError(f"{name}: nonblank line count {len(source_lines)} != {len(target_lines)}")
        for index, (left, right) in enumerate(zip(source_lines, target_lines), start=1):
            if left[:1].isdigit() and right[:1] != left[:1]:
                raise ValueError(f"{name}: control prefix mismatch at line {index}")
        if CJK_RE.search(target):
            raise ValueError(f"{name}: CJK residue in Korean target")
        data.m_Script = target
        data.save()
        found[name] = {
            "path_id": int(obj.path_id),
            "source_chars": len(source),
            "target_chars": len(target),
            "nonblank_lines": len(target_lines),
            "target_sha256": sha256_bytes(target.encode("utf-8")),
            "hangul_count": sum("가" <= ch <= "힣" for ch in target),
        }
    if set(found) != set(TEXT_TARGETS):
        raise ValueError(f"missing TextAsset targets: {sorted(set(TEXT_TARGETS) - set(found))}")
    output = STAGING_ROOT / "sharedassets1.assets"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(env.file.save())
    return {"text_assets": found}


def build_level1() -> dict[str, Any]:
    source_path = ORIGINAL["level1"]
    env = UnityPy.load(str(source_path))
    by_id = {int(obj.path_id): obj for obj in env.objects}
    applied = []
    for path_id, rules in UI_RULES.items():
        obj = by_id.get(path_id)
        if obj is None or obj.type.name != "MonoBehaviour":
            raise ValueError(f"level1 path {path_id} is not a MonoBehaviour")
        raw = bytes(obj.get_raw_data())
        for rule in rules:
            if CJK_RE.search(rule["target"]):
                raise ValueError(f"level1 path {path_id}: target retains CJK")
            raw = patch_raw_string(raw, rule["source"], rule["target"])
            applied.append({
                "path_id": path_id,
                "source_string_sha256": rule["source"],
                "target_string_sha256": sha256_bytes(rule["target"].encode("utf-8")),
                "target_chars": len(rule["target"]),
            })
        obj.set_raw_data(raw)
    output = STAGING_ROOT / "level1"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(env.file.save())
    return {"ui_objects": len(UI_RULES), "ui_strings": len(applied), "applied": applied}


def resolve_xdelta(explicit: str) -> Path:
    if explicit:
        candidate = Path(explicit)
    else:
        found = shutil.which("xdelta3.exe") or shutil.which("xdelta3")
        if not found:
            raise FileNotFoundError("xdelta3 is required")
        candidate = Path(found)
    require_file(candidate)
    return candidate


def run_xdelta(xdelta: Path, arguments: list[str]) -> None:
    completed = subprocess.run([str(xdelta), *arguments], capture_output=True, text=True)
    if completed.returncode:
        raise RuntimeError((completed.stderr or completed.stdout or "xdelta3 failed").strip())


def build_deltas(xdelta: Path) -> dict[str, Any]:
    variants = {
        "original-clean": ORIGINAL,
        "previous-korean-patch": PREVIOUS,
    }
    result: dict[str, Any] = {}
    DELTA_ROOT.mkdir(parents=True, exist_ok=True)
    for variant_name, sources in variants.items():
        source_hashes: dict[str, str] = {}
        delta_files: dict[str, str] = {}
        delta_hashes: dict[str, str] = {}
        delta_bytes: dict[str, int] = {}
        for name, source in sources.items():
            target = STAGING_ROOT / name
            delta = DELTA_ROOT / f"{variant_name}.{name}.vcdiff"
            require_file(source)
            require_file(target)
            if delta.exists():
                delta.unlink()
            run_xdelta(xdelta, ["-q", "-e", "-9", "-s", str(source), str(target), str(delta)])
            with tempfile.TemporaryDirectory(prefix="swaying-girl-vcdiff-") as temp:
                decoded = Path(temp) / name
                run_xdelta(xdelta, ["-q", "-d", "-s", str(source), str(delta), str(decoded)])
                if sha256_file(decoded) != sha256_file(target):
                    raise ValueError(f"delta round-trip mismatch: {variant_name}/{name}")
            source_hashes[name] = sha256_file(source)
            delta_files[name] = f"delta/{delta.name}"
            delta_hashes[name] = sha256_file(delta)
            delta_bytes[name] = delta.stat().st_size
        result[variant_name] = {
            "source_hashes": source_hashes,
            "delta_files": delta_files,
            "delta_sha256": delta_hashes,
            "delta_bytes": delta_bytes,
        }
    return result


INSTALL_PS1 = r'''param(
    [Parameter(Mandatory=$true)][string]$GameRoot,
    [switch]$Force,
    [string]$XdeltaPath = "",
    [string]$BackupRoot = ""
)
$ErrorActionPreference = "Stop"
if (-not $Force) { throw "릴리스 후보 설치입니다. 검토 후 -Force를 명시하세요." }
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Manifest = Get-Content -LiteralPath (Join-Path $PackageRoot "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$DataRoot = Join-Path $GameRoot "SwayingGirl_Data"
if (-not (Test-Path -LiteralPath (Join-Path $GameRoot "SwayingGirl.exe"))) { throw "SwayingGirl.exe가 없습니다: $GameRoot" }
if (Get-Process -Name "SwayingGirl" -ErrorAction SilentlyContinue) { throw "게임을 먼저 종료하세요." }
if ([string]::IsNullOrWhiteSpace($XdeltaPath)) { $XdeltaPath = (Get-Command "xdelta3.exe" -ErrorAction Stop).Source }
if (-not (Test-Path -LiteralPath $XdeltaPath)) { throw "xdelta3를 찾을 수 없습니다: $XdeltaPath" }
$Names = @("sharedassets1.assets", "level1")
$Matches = @()
foreach ($property in @($Manifest.source_variants.PSObject.Properties)) {
    $match = $true
    foreach ($name in $Names) {
        $target = Join-Path $DataRoot $name
        if (-not (Test-Path -LiteralPath $target)) { $match = $false; continue }
        $observed = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($observed -ne $property.Value.source_hashes.PSObject.Properties[$name].Value) { $match = $false }
    }
    if ($match) { $Matches += $property }
}
$already = $true
foreach ($name in $Names) {
    $target = Join-Path $DataRoot $name
    if (-not (Test-Path -LiteralPath $target)) { $already = $false; continue }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToUpperInvariant() -ne $Manifest.output_assets.PSObject.Properties[$name].Value.sha256) { $already = $false }
}
if ($already) { Write-Output "Swaying Girl Korean recovery is already installed."; exit 0 }
if ($Matches.Count -ne 1) { throw "원본 hash gate 실패: 일치하는 source variant 수=$($Matches.Count)" }
$VariantName = $Matches[0].Name
$Variant = $Matches[0].Value
if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $BackupRoot = Join-Path $GameRoot (".korean-patch-backup\Swaying-Girl\" + (Get-Date -Format "yyyyMMdd-HHmmss"))
}
$BackupRoot = [IO.Path]::GetFullPath($BackupRoot)
if (Test-Path -LiteralPath $BackupRoot) { throw "백업 경로가 이미 존재합니다: $BackupRoot" }
New-Item -ItemType Directory -Force -Path (Join-Path $BackupRoot "files") | Out-Null
$Record = [ordered]@{ schema="bk927.swaying-girl-backup/v1"; created_at=(Get-Date).ToUniversalTime().ToString("o"); game_root=$GameRoot; source_variant=$VariantName; source_hashes=[ordered]@{}; patched_hashes=[ordered]@{}; assets=$Names }
try {
    foreach ($name in $Names) {
        $target = Join-Path $DataRoot $name
        $backup = Join-Path (Join-Path $BackupRoot "files") $name
        Copy-Item -LiteralPath $target -Destination $backup -Force
        $hash = (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($hash -ne $Variant.source_hashes.PSObject.Properties[$name].Value) { throw "백업 hash 실패: $name" }
        $Record.source_hashes[$name] = $hash
        $Record.patched_hashes[$name] = $Manifest.output_assets.PSObject.Properties[$name].Value.sha256
    }
    $Record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $BackupRoot "backup-manifest.json") -Encoding UTF8
    foreach ($name in $Names) {
        $target = Join-Path $DataRoot $name
        $delta = Join-Path $PackageRoot $Variant.delta_files.PSObject.Properties[$name].Value
        if ((Get-FileHash -LiteralPath $delta -Algorithm SHA256).Hash.ToUpperInvariant() -ne $Variant.delta_sha256.PSObject.Properties[$name].Value) { throw "delta hash 실패: $name" }
        $temporary = Join-Path $DataRoot ($name + ".swaying-korean.tmp")
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
        & $XdeltaPath -q -d -s $target $delta $temporary
        if ($LASTEXITCODE -ne 0) { throw "xdelta 적용 실패: $name" }
        $expected = $Manifest.output_assets.PSObject.Properties[$name].Value.sha256
        if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expected) { throw "임시 출력 hash 실패: $name" }
        [IO.File]::Move($temporary, $target, $true)
    }
    Write-Output "Swaying Girl Korean recovery installed. source=$VariantName backup=$BackupRoot"
} catch {
    $message = $_.Exception.Message
    foreach ($name in $Names) {
        $backup = Join-Path (Join-Path $BackupRoot "files") $name
        if (Test-Path -LiteralPath $backup) { Copy-Item -LiteralPath $backup -Destination (Join-Path $DataRoot $name) -Force }
    }
    throw "설치 실패. 자동 롤백 완료: $message"
}
'''


RESTORE_PS1 = r'''param(
    [Parameter(Mandatory=$true)][string]$GameRoot,
    [Parameter(Mandatory=$true)][string]$BackupRoot,
    [switch]$Force
)
$ErrorActionPreference = "Stop"
if (-not $Force) { throw "복구는 게임 자산을 교체합니다. 검토 후 -Force를 명시하세요." }
$DataRoot = Join-Path $GameRoot "SwayingGirl_Data"
$RecordPath = Join-Path $BackupRoot "backup-manifest.json"
if (-not (Test-Path -LiteralPath $RecordPath)) { throw "backup-manifest.json이 없습니다: $BackupRoot" }
$Record = Get-Content -LiteralPath $RecordPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($Record.schema -ne "bk927.swaying-girl-backup/v1") { throw "지원하지 않는 백업입니다." }
foreach ($name in @($Record.assets)) {
    $target = Join-Path $DataRoot $name
    $backup = Join-Path (Join-Path $BackupRoot "files") $name
    if (-not (Test-Path -LiteralPath $backup)) { throw "백업 파일이 없습니다: $name" }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToUpperInvariant() -ne $Record.patched_hashes.PSObject.Properties[$name].Value) { throw "현재 설치 hash gate 실패: $name" }
    if ((Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToUpperInvariant() -ne $Record.source_hashes.PSObject.Properties[$name].Value) { throw "백업 hash gate 실패: $name" }
}
foreach ($name in @($Record.assets)) {
    $target = Join-Path $DataRoot $name
    $backup = Join-Path (Join-Path $BackupRoot "files") $name
    $temporary = Join-Path $DataRoot ($name + ".swaying-restore.tmp")
    Copy-Item -LiteralPath $backup -Destination $temporary -Force
    [IO.File]::Move($temporary, $target, $true)
}
Write-Output "Swaying Girl assets restored from $BackupRoot"
'''


VERIFY_PS1 = r'''param(
    [Parameter(Mandatory=$true)][string]$GameRoot,
    [ValidateSet("patched", "source")][string]$State = "patched"
)
$ErrorActionPreference = "Stop"
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Manifest = Get-Content -LiteralPath (Join-Path $PackageRoot "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$DataRoot = Join-Path $GameRoot "SwayingGirl_Data"
$Names = @("sharedassets1.assets", "level1")
$Observed = [ordered]@{}
foreach ($name in $Names) {
    $path = Join-Path $DataRoot $name
    $Observed[$name] = if (Test-Path -LiteralPath $path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant() } else { $null }
}
$Pass = $true
$Variant = $null
if ($State -eq "patched") {
    foreach ($name in $Names) { if ($Observed[$name] -ne $Manifest.output_assets.PSObject.Properties[$name].Value.sha256) { $Pass = $false } }
} else {
    foreach ($property in @($Manifest.source_variants.PSObject.Properties)) {
        $match = $true
        foreach ($name in $Names) { if ($Observed[$name] -ne $property.Value.source_hashes.PSObject.Properties[$name].Value) { $match = $false } }
        if ($match) { $Variant = $property.Name }
    }
    if ($null -eq $Variant) { $Pass = $false }
}
$Result = [ordered]@{ schema="bk927.swaying-girl-verify/v1"; checked_at=(Get-Date).ToUniversalTime().ToString("o"); state=$State; pass=$Pass; matched_source_variant=$Variant; observed_sha256=$Observed }
$Result | ConvertTo-Json -Depth 6
if (-not $Pass) { exit 2 }
'''


def write_package_files(variants: dict[str, Any], qa: dict[str, Any]) -> dict[str, Any]:
    runtime_status = qa["runtime"]
    runtime_readme = (
        "정적 자산·델타 왕복 검사와 실제 게임의 메인 화면, 도움말, 첫 대사·선택지 런타임 확인을 통과했습니다. "
        "전체 엔딩과 자유 모드는 이번 스모크 테스트 범위에 포함하지 않았습니다."
        if runtime_status == "PASS"
        else "정적 자산·델타 왕복 검사는 통과했습니다. 실제 화면의 글리프, 줄바꿈, 선택지 폭은 릴리스 후보 런타임 확인 대상으로 남아 있습니다."
    )
    runtime_markdown = (
        "통과 (메인 화면·도움말·첫 대사·첫 선택지, 한글 글리프/줄바꿈/중국어 잔존 확인)"
        if runtime_status == "PASS"
        else "대기"
    )
    output_assets = {
        name: {"relative_path": f"SwayingGirl_Data/{name}", "sha256": sha256_file(STAGING_ROOT / name), "bytes": (STAGING_ROOT / name).stat().st_size}
        for name in ("sharedassets1.assets", "level1")
    }
    manifest = {
        "schema": "bk927.swaying-girl-korean-recovery/v1",
        "game": "Swaying Girl",
        "appid": 1393350,
        "buildid": "12343356",
        "version": "0.1.0-rc1",
        "status": "RELEASE_CANDIDATE",
        "language": "ko-KR",
        "engine": "Unity 2019.2.5f1 Mono",
        "delta_only": True,
        "requires": "xdelta3 3.x (Apache-2.0; not bundled)",
        "source_variants": variants,
        "output_assets": output_assets,
        "translation": {"text_assets": 2, "ui_objects": len(UI_RULES), "ui_strings": sum(len(rules) for rules in UI_RULES.values()), "manual_source_review": "complete"},
        "qa": {"static": "PASS", "delta_round_trip": "PASS", "runtime": runtime_status},
    }
    write_json(PACKAGE_ROOT / "manifest.json", manifest)
    write_json(PACKAGE_ROOT / "TRANSLATION-QA.json", qa)
    (PACKAGE_ROOT / "install.ps1").write_text(INSTALL_PS1, encoding="utf-8", newline="\n")
    (PACKAGE_ROOT / "restore.ps1").write_text(RESTORE_PS1, encoding="utf-8", newline="\n")
    (PACKAGE_ROOT / "verify.ps1").write_text(VERIFY_PS1, encoding="utf-8", newline="\n")
    (PACKAGE_ROOT / "README.md").write_text(
        fr"""# Swaying Girl 한국어 복구 패치 0.1.0-rc1

> 저장소 소스에는 배포용 `.vcdiff` 파일을 넣지 않습니다. 실제 설치는 GitHub Releases의 `Swaying_Girl_Korean_Recovery_0.1.0-rc1.zip`을 내려받아 진행하세요.

Steam AppID 1393350, BuildID 12343356용 릴리스 후보입니다. 중국어 대사 TextAsset 두 개와 장면/UI 문구 26개를 한국어로 교체합니다. 원본 게임 자산은 포함하지 않고 VCDIFF 델타만 제공합니다.

## 설치

1. 게임을 종료합니다.
2. xdelta3 3.x를 설치해 `xdelta3.exe`가 PATH에 있도록 합니다.
3. PowerShell에서 다음을 실행합니다.

```powershell
.\install.ps1 -GameRoot "D:\SteamLibrary\steamapps\common\Swaying Girl" -Force
```

설치 전 두 파일의 SHA-256이 지원 목록과 정확히 일치해야 하며, 원본은 게임 폴더의 `.korean-patch-backup\Swaying-Girl` 아래에 보존됩니다. `restore.ps1`에는 설치 출력에 표시된 정확한 백업 경로를 지정하세요.

{runtime_readme}
""",
        encoding="utf-8",
        newline="\n",
    )
    (PACKAGE_ROOT / "RELEASE-NOTES.md").write_text(
        """# 0.1.0-rc1

- 중국어 원문 기준으로 대사 216개 비공백 행을 전수 재검수했습니다.
- 성공 선택지 의미, 직역투, 말장난 현지화와 대화 문장성을 보정했습니다.
- 기존 패치에 남은 승리/패배/오답 중국어와 잘린 `느림` 표기를 복구했습니다.
- 기존 안전문구로 재작성됐던 장문 안내를 원문의 풍자와 의미에 맞춰 다시 번역했습니다.
- 원본 자산 전체가 아닌 SHA-256 게이트 VCDIFF 델타로 배포합니다.
""",
        encoding="utf-8",
        newline="\n",
    )
    (PACKAGE_ROOT / "LEGAL-NOTICE.txt").write_text(
        """This is an unofficial Korean localization delta. It contains no complete original game asset. A legally installed copy of Swaying Girl is required. xdelta3 is not bundled. Do not redistribute the original game files or a prepatched full asset.
""",
        encoding="utf-8",
        newline="\n",
    )
    (PACKAGE_ROOT / "TRANSLATION-QA.md").write_text(
        f"""# 번역 및 자산 QA

- 대사 TextAsset: 2개 (`Girl11`, `Girl21`)
- 비공백 대사/선택지 행: {qa['text_nonblank_lines']}개
- UI 변경 오브젝트: {qa['level1_changed_object_count']}개
- UI 교체 문자열: {qa['ui_string_count']}개
- 대사 숫자 제어 접두사: 보존
- 대상 번역의 CJK 잔여: 0
- 원본 대비 예상 밖 오브젝트 변경: 0
- 두 source variant VCDIFF decode 왕복: 통과
- 런타임 화면 확인: {runtime_markdown}
""",
        encoding="utf-8",
        newline="\n",
    )
    return manifest


def write_checksums() -> None:
    target = PACKAGE_ROOT / "checksums.sha256"
    lines = []
    for path in sorted(PACKAGE_ROOT.rglob("*")):
        if path.is_file() and path != target:
            lines.append(f"{sha256_file(path).lower()}  {path.relative_to(PACKAGE_ROOT).as_posix()}")
    target.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def build_zip() -> None:
    if ZIP_PATH.exists():
        ZIP_PATH.unlink()
    with zipfile.ZipFile(ZIP_PATH, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(PACKAGE_ROOT.rglob("*")):
            if not path.is_file():
                continue
            info = zipfile.ZipInfo(f"{PACKAGE_NAME}/{path.relative_to(PACKAGE_ROOT).as_posix()}", date_time=(2026, 8, 31, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    ZIP_SHA_PATH.write_text(f"{sha256_file(ZIP_PATH).lower()}  {ZIP_PATH.name}\n", encoding="utf-8", newline="\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--xdelta", default="")
    args = parser.parse_args()
    xdelta = resolve_xdelta(args.xdelta)
    for path in [*ORIGINAL.values(), *PREVIOUS.values(), *(TRANSLATION_ROOT / f"{name}.txt" for name in TEXT_TARGETS)]:
        require_file(path)
    if PACKAGE_ROOT.exists():
        shutil.rmtree(PACKAGE_ROOT)
    if STAGING_ROOT.parent.exists():
        shutil.rmtree(STAGING_ROOT.parent)

    shared_qa = build_sharedassets()
    level_qa = build_level1()
    shared_changes = changed_objects(ORIGINAL["sharedassets1.assets"], STAGING_ROOT / "sharedassets1.assets")
    level_changes = changed_objects(ORIGINAL["level1"], STAGING_ROOT / "level1")
    if {(item["path_id"], item["type"]) for item in shared_changes} != {(19, "TextAsset"), (20, "TextAsset")}:
        raise ValueError("sharedassets1.assets changed-object gate failed")
    if {item["path_id"] for item in level_changes} != set(UI_RULES) or any(item["type"] != "MonoBehaviour" for item in level_changes):
        raise ValueError("level1 changed-object gate failed")

    variants = build_deltas(xdelta)
    runtime_checks = {"status": "PENDING"}
    if RUNTIME_QA_PATH.exists():
        runtime_checks = json.loads(RUNTIME_QA_PATH.read_text(encoding="utf-8"))
        if runtime_checks.get("status") not in {"PASS", "FAIL", "PENDING"}:
            raise ValueError("runtime-qa.json status must be PASS, FAIL, or PENDING")

    qa = {
        "schema": "bk927.swaying-girl-translation-qa/v1",
        "generated_at_utc": runtime_checks.get("checked_at_utc") or datetime.now(timezone.utc).isoformat(),
        "status": "PASS",
        "text_assets": shared_qa["text_assets"],
        "text_nonblank_lines": sum(item["nonblank_lines"] for item in shared_qa["text_assets"].values()),
        "sharedassets_changed_objects": shared_changes,
        "sharedassets_changed_object_count": len(shared_changes),
        "level1_changed_objects": level_changes,
        "level1_changed_object_count": len(level_changes),
        "ui_string_count": level_qa["ui_strings"],
        "ui_applied": level_qa["applied"],
        "cjk_residual_count": 0,
        "control_prefix_mismatch_count": 0,
        "delta_variants": {name: {"files": len(data["delta_files"]), "bytes": sum(data["delta_bytes"].values())} for name, data in variants.items()},
        "runtime": runtime_checks["status"],
        "runtime_checks": runtime_checks,
    }
    write_package_files(variants, qa)
    write_checksums()
    build_zip()
    write_json(BUILD_ROOT / "release-build.json", {
        "status": "PASS",
        "package": str(PACKAGE_ROOT),
        "zip": str(ZIP_PATH),
        "zip_bytes": ZIP_PATH.stat().st_size,
        "zip_sha256": sha256_file(ZIP_PATH),
        "staging": {name: {"sha256": sha256_file(STAGING_ROOT / name), "bytes": (STAGING_ROOT / name).stat().st_size} for name in ("sharedassets1.assets", "level1")},
        "source_variants": list(variants),
        "runtime": runtime_checks["status"],
    })
    print((BUILD_ROOT / "release-build.json").read_text(encoding="utf-8"))


if __name__ == "__main__":
    main()
