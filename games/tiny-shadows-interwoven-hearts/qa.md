# Tiny Shadows Interwoven Hearts — recovery QA

Generated (UTC): `2026-08-31T03:06:10.391304+00:00`

## Result

- Game build: `1.28`; Ren’Py runtime: `8.6.0.26032101+nightly`.
- Latest `scripts.rpa`: `D35526EE841CA44E1ED5DBA14F54E64C299DE82CE91DB6E365D50C8CD43EBC15` (824025 bytes).
- Candidate dialogue literals: `2637`; payload `.rpy`: `9`.
- Unexpected CJK residue: `0` lines; expected Japanese credit lines: `1`.
- Token mismatches: `0`; nonempty translation omissions: `0`; duplicate labels: `0`.
- Ren’Py lint exit: `0`; compiled candidate sidecars in roundtrip tree: `9`.
- Installed-game write guard: `PASS` (source archive and loose-script hashes unchanged).

## Rebase and route checks

The candidate uses the current archive's label/branch structure, including the new `start` menu and `extra1` postscript route. The old loose role file is replaced by the current unified `scripts/roles/role.rpy` + `syq.rpy`; stale content-role and compiled sidecars are handled only by known-hash removal entries.

- Start menu: `{'start_menu_has_korean_base_option': True, 'start_menu_has_korean_postscript_option': True, 'start_menu_routes_to_extra1': True, 'end_routes_to_extra1': True, 'gallery_unlock_action_present': True, 'disabled_gallery_action_absent': True}`
- External calls/jumps (provided by the game's own runtime/archive): `achievement, disable_user_interaction, enable_user_interaction, splashscreen`

## Runtime QA

The embedded Ren’Py runtime linted the output-only candidate tree and exited 0. Warnings are inherited asset/runtime conditions: missing image files in the reduced QA asset set, original init-priority/define style warnings, and orphan Japanese translation entries. No duplicate-label or unknown-format error remains. A final install on the user's complete Steam build then verified the Korean main menu, settings, first scene background, Korean font, and two-line dialogue wrapping; restore returned every target to its original state with zero hash mismatches.

Audio audit: the old loose patch contains `650` numeric voice commands, of which `650` do not match the current hashed `audio.rpa` inventory (1494 voice entries; sample paths are retained in the JSON report). The rebased candidate carries `0` voice commands.

## Meaning samples

| File/line | Source context | Korean candidate |
|---|---|---|
| `scripts/content/script.rpy:8` | 本篇 | 본편 |
| `scripts/content/script.rpy:661` | 996？ | 996? |
| `scripts/content/script.rpy:1199` | ……哎？ | ……어? |
| `scripts/content/part2.rpy:8` | 我一瞬间宕机在了原地。 | 나는 순간적으로 그 자리에 얼어붙고 말았다. |
| `scripts/content/part2.rpy:684` | 于是我老老实实地洗完澡之后，像一具安静的尸体一样躺在了备用床褥打的地铺上。 | 샤워를 마친 나는 여분의 침구를 깐 바닥에 조용히 시체처럼 누웠다. |
| `scripts/content/part2.rpy:1355` | ——但是这一次，却一点都不痛。 | ——하지만 이번에는 전혀 아프지 않았다. |
| `scripts/content/part3.rpy:9` | 周末的早上，顶着黑眼圈的我长舒一口气，终于合上了电脑。 | 주말 아침, 다크서클이 퀭한 나는 안도의 한숨을 내쉬며 드디어 노트북을 덮었다. |
| `scripts/content/part3.rpy:432` | ……………… | ……………… |
| `scripts/content/part3.rpy:827` | ——不知道为什么，光是说了这么几句话，就感觉更累了。 | ——왜인지 모르겠지만, 겨우 몇 마디 나눴을 뿐인데 더 피곤해진 기분이다. |
| `scripts/content/part4.rpy:7` | 吃完饭后，瞄到了隔壁的同事还在不时地向我投来目光，一副欲言又止的模样。 | 식사를 마치고 슬쩍 보니 옆자리 동료가 여전히 뭔가를 말하고 싶어 입이 근질근질한 표정으로 나를 힐끗거리고 있었다. |
| `scripts/content/part4.rpy:874` | 她再也没有来过这里，也没有去过线下的任何活动。 | 그녀는 다시는 이곳에 오지 않았고, 어떤 오프라인 활동에도 참여하지 않았다. |
| `scripts/content/part4.rpy:1878` | 夕阳下，我们的影子交织在一起，慢慢走远，直到再也分不清彼此。 | 노을 속에서 우리의 그림자는 서로 얽힌 채 천천히 멀어져 갔고, 마침내 서로의 경계조차 알아볼 수 없게 되었다. |
| `scripts/content/extra1.rpy:7` | 周日的上午，秋天的阳光温吞吞地洒在人行道上。 | 일요일 오전, 가을 햇살이 보도 위에 포근하게 내려앉았다. |
| `scripts/content/extra1.rpy:316` | ——怎么说呢。 | ——뭐랄까. |

## Distribution safety

The release contains only the nine translated `.rpy` payload files, `manifest.json`, PowerShell install/restore helpers, documentation, and QA reports. It contains no `.rpa`, `.rpyc`, executable, DLL, image, audio, font, or Ren’Py runtime. The installer requires a caller-supplied game root, validates every existing target against the manifest, backs up before changing, verifies temporary copies, and rolls back on failure. Restore refuses modified installed targets and verifies backups before replacement.

ZIP: `C:\Users\dead4\Documents\Codex\2026-08-16\d-steamlibrary-steamapps-common-tkpunk-ui\library-audit\work\tiny-shadows-recovery\Tiny_Shadows_Interwoven_Hearts_Korean_Recovery_Delta.zip`; SHA-256 sidecar: `C:\Users\dead4\Documents\Codex\2026-08-16\d-steamlibrary-steamapps-common-tkpunk-ui\library-audit\work\tiny-shadows-recovery\Tiny_Shadows_Interwoven_Hearts_Korean_Recovery_Delta.zip.sha256`.

See the adjacent JSON report for exact hashes, source/candidate counts, token signatures, route/label checks, lint output paths, and the game-write guard.
