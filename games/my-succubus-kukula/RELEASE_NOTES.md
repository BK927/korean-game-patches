# Release notes — 0.2.0-rc1

## Changes

- Applied 91 reviewed Korean UI/technical terminology corrections in the
  existing 1,391-key Korean language file.
- Applied 16 story-map updates/insertions in the existing encoded Korean map,
  including the missing `end_1_8` entry; the recovered map has 330 keys.
- Preserved bracket/control tokens and the existing field-patch architecture.
- Added an all-target preflight, atomic writes, automatic verified rollback,
  portable result verifier, reverse operation, glossary, QA reports, and
  legal/package documentation.

## Verification

- Base hashes matched before the real installation write.
- Result hashes, JSON structure, key counts, duplicates, empty values, CJK
  residuals, control tokens, and reverse dry-run all passed after apply.
- Timestamped original backups remain beside both changed game files.
- Runtime observation reached the NW.js renderer and displayed Korean `확인`
  on the Steam API warning modal with no tofu glyphs. Full gameplay UI QA is
  pending a Steam Library Play launch in an interactive Steam context; this is
  explicitly marked partial in `qa/runtime-qa-record.*`.

## Package scope

The installer payload is a field patch and helper scripts only. No original
full game asset is included.
