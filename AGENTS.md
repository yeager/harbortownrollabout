# Harbor Town Rollabout

Read [PROJECTMEMORY.md](PROJECTMEMORY.md) for past decisions and [the work list](docs/Arbetslista.md) for outstanding tasks. Check current code before relying on a historical note. Update the work list when an item is verified.

## Working on the game

Use Godot 4.7 dev5. Open `project.godot` and press F5 to play. Keep player-facing instructions in [README.md](README.md). The public executable and app name is `harbortown`.

Use the existing language catalogs for player-facing text. Follow [the localization guide](l10n/README.md) and run `sh tools/check_localizations.sh` after changing translations.

To verify a change, run the relevant scenario from the project root, for example `godot --headless --script res://tests/weather_transition.gd`. Give tests a fresh `XDG_DATA_HOME` under the local cache so they cannot overwrite a player's saved game. Check visual changes in the running game.

## Before publishing

Review the staged diff and file list. Run `gitleaks protect --staged --redact` before committing. Before pushing, scan the outgoing history with `gitleaks detect --redact` and inspect the files included in any release archive. Keep credentials, private keys, tokens, passwords, signing identities, private configuration and original family photos out of Git, packages, issue reports, logs and external services. Use the approved game artwork for public images.

If a scan finds a possible secret, stop publication and investigate locally. Report its location with the value redacted. If a real credential was already exposed, notify the owner so it can be revoked or rotated.
