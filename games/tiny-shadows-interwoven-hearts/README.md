# Tiny Shadows Interwoven Hearts — Korean recovery delta

This package is a localization delta for the Steam build identified in `manifest.json`.
It does not contain the original game, `scripts.rpa`, any images/audio, the executable, or the Ren'Py runtime. Keep a legitimate Steam installation available.

## Install

1. Exit the game.
2. From PowerShell, run:

   `./install.ps1 -GameRoot 'D:\SteamLibrary\steamapps\common\小小的身影，重叠的内心'`

The installer accepts either the Steam game directory shown above or its `game` subdirectory. It validates every payload and existing legacy file hash before writing. It removes stale loose resource declarations (`background.rpy`/`.rpyc` and `bgm.rpy`/`.rpyc`) only when their known hashes match, so the current archive's `.webp` assets are not shadowed by an older patch. It stores verified backups in a timestamped directory beside `game/` (outside Ren'Py's script scan) and records state in `game/.tiny-shadows-korean-recovery-state.json`.

## Restore

Run the matching helper while the game is closed:

`./restore.ps1 -GameRoot 'D:\SteamLibrary\steamapps\common\小小的身影，重叠的内心'`

Restore refuses to overwrite files changed after installation. It verifies backups, copies through temporary files, verifies again, and then replaces the target. The backup is retained for manual inspection.

The package targets Ren'Py 8.6.0.26032101 and game build 1.28. The latest `scripts.rpa` is required from the user's own installation; it is never redistributed here.
