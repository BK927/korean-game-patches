# My succubus Kukula — unofficial Korean recovery patch

Package version: `0.2.0-rc1`

This is a field-only patch for the Steam AppID `2848420` installation named
`KUKULA`. It updates the existing Korean language JSON and the encoded Korean
story map in `script.js`; it does not contain either original full game file.

## Install

1. Close KUKULA and keep Steam open.
2. Keep the package beside the game or in another writable folder. Do not edit
   the game files by hand.
3. From the package directory, run the supplied helper against the exact
   installation:

   ```text
   python installer-payload\tools\apply_patch.py --root "D:\SteamLibrary\steamapps\common\KUKULA" --patch installer-payload\kukula-recovery.patch.json --apply
   ```

   The helper checks the base SHA-256 hashes before writing and creates a
   timestamped backup beside each target. It validates both targets before the
   first write, uses atomic replacement, and restores already-written files if
   a later write fails.
4. Verify the installation:

   ```text
   python installer-payload\verify_applied.py --root "D:\SteamLibrary\steamapps\common\KUKULA" --patch installer-payload\kukula-recovery.patch.json
   ```

The patch targets `asset/language/한국어.json` and `script.js` under the Steam
install directory. The language selection used by the existing patch is
English; the Korean fields are displayed through that route.

## Rollback

With the patched files still present, run:

```text
python installer-payload\tools\apply_patch.py --root "D:\SteamLibrary\steamapps\common\KUKULA" --patch installer-payload\kukula-recovery.patch.json --reverse --apply
```

The helper checks the result hash before reversing. If another update changed
the files, stop and use Steam's file-integrity verification or restore the
timestamped backups manually after checking their hashes.

## QA status

Static applied-patch QA is **PASS**: 1,391 language keys, 330 story-map keys,
zero empty/duplicate/CJK values, zero control-token mismatches, and a passing
rollback dry-run. Direct runtime observation reached the NW.js canvas and
rendered the Korean `확인` button without tofu glyphs. Full menu, language
selector, Settings, and first-dialogue checks require launching from Steam's
Library Play button; the automated session could not obtain that Steam API
context, so those checks are recorded as **PARTIAL / BLOCKED**, not claimed as
passed.

See `qa/` for machine-readable results and `docs/` for the glossary. Use this
package only with a legally obtained game installation and retain the backups.
