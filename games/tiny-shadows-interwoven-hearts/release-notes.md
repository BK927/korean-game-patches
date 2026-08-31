# Release notes — Korean recovery delta

Build: 2026-08-31 staging recovery
Game build: 1.28
Ren'Py runtime: 8.6.0.26032101+nightly
Source archive: the user's own `game/scripts.rpa`, updated 2026-08-01; see `manifest.json` for its SHA-256.

## Payload

- Rebased `script`, `part2`, `part3`, `part4`, and `end` on the current archive source.
- Added the current build's `extra1` postscript (288 dialogue literals).
- Rebased unified `scripts/roles/role.rpy` and `syq.rpy` so the new route uses current character/layered-image definitions.
- Updated the Korean main-menu overlay; the gallery button remains gated by the game's unlock flag.
- Removes stale legacy loose role, resource declarations, and compiled script files only when their known old-patch hashes match; this prevents old `.jpg` background declarations from shadowing the current archive's `.webp` assets.
- No voice files are added; the old loose patch's broken `audio/voice/*.ogg` references are not carried into the candidate.

## QA

The candidate was linted with the game's embedded Ren'Py 8.6 runtime in an output-only staging tree. Lint exits 0. Asset-not-loadable and inherited original warnings are recorded in the QA report; they are not introduced by the translation delta. The only CJK characters remaining in translated source are the Japanese credit name `祈里マリヱ`.

The final package was also installed on the complete Steam build, where the Korean main menu, settings, first story scene, current `.webp` background, Korean glyph rendering, and dialogue wrapping were visually verified. The matching restore completed with zero source hash mismatches and no new payload files left behind. The compact quick-menu labels (`AUTO`, `SKIP`, `SAVE`, `LOAD`, `LOG`, `SYS.`) remain in the original English as a known RC scope item.
