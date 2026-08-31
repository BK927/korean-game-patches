# KUKULA runtime QA record

- Status: **PARTIAL / BLOCKED by Steam API context**
- Direct NW.js launch reached the game canvas and displayed the Korean `확인` button on the `please run steam !` modal.
- No tofu/□ glyphs were observed in that rendered Korean button.
- The title menu, language selector, Settings, and first dialogue could not be reached because the game requires Steam launch context.
- Steam was already running. AppID launch was attempted through `-applaunch` and both common Steam URI forms, but no KUKULA window appeared for observation.
- Two UI input attempts returned unknown state after re-observation, so further GUI input was stopped per Computer Use recovery guidance.
- Runtime log snapshot: `runtime-evidence/debug.log.snapshot.txt` (`Settings version is not 1`; timestamp predates this run).
- Durable screen record: `runtime-evidence/direct-launch-screen-observation.md`.

The static applied-patch verification remains **PASS**. A future QA pass should launch the game from the Steam Library Play button in the same interactive desktop session, then capture the title/language/Settings/first-dialogue states.
