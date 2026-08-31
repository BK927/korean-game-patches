# KUKULA runtime screen observation

- **Captured with:** Computer Use window observation (`get_window_state`)
- **Target:** `KUKULA.exe` / `KUKULA - NW.js`
- **Direct launch result:** the NW.js canvas rendered, then showed the modal `please run steam !`.
- **Korean rendering observed:** the modal action button was rendered as `확인`, with no tofu/□ glyphs.
- **Accessibility observation:** the modal exposed the text `please run steam !` and a `확인` button; the game canvas exposed `gcCanvas`.
- **Not reached:** title menu, language selector, Settings, and first dialogue. The Steam API guard blocked the direct launch before those screens.
- **Input safety:** the modal/button input and Steam library search each failed to produce a known state after re-observation, so further coordinate/index input was stopped as required by the Computer Use recovery guidance.
- **Steam-context attempts:** Steam was already running; AppID launch via `-applaunch 2848420`, `steam://run/2848420`, and `steam://rungameid/2848420` produced no KUKULA target window during the observation window.

The screenshots from the observations were displayed by the Computer Use tool. The tool guidance does not permit decoding or persisting its screenshot payloads, so this text record is the durable evidence artifact; no fabricated screenshot file is included.
