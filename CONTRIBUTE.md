# Help make Harbor Town Rollabout

## Make a song for the radio

Do you sing in Spanish, German, French, Norwegian Bokmål or Finnish? Those stations have a recorded greeting and play English songs. We’d love a song in your language that children can sing along with while they drive. A chorus about a hot dog that lost its bun would fit right in. Choose a style you enjoy singing.

You can offer lyrics, a translation someone can sing, or a recording. Pick a tune from the [Swedish and English songbook](docs/Radiolatar.md) or write your own. Tell us the language, who wrote and performed it, how to credit them, and whether we can distribute the words and recording with the game. Please share only material you have permission to contribute.

If you’re adding a recording to the game yourself, put the MP3 in `audio/radio/` and add the language code at the end of its name. For example, `La fugue du cornichon (Live) (FR).mp3` appears on the French radio as **La fugue du cornichon (Live)**. Use ES for Spanish, DE for German, FR for French, NB for Norwegian Bokmål or FI for Finnish.

To hear your recording, open the project in Godot, let it import the MP3, then start the game. Choose the song’s language in Settings and enter a vehicle. If another song plays first, use **Next song** until yours comes on.

## Help the town speak your language

A single correction helps. If a button, a speech bubble or a driving instruction sounds odd in your language, tell us where you saw it, what it says and what you’d say instead. Short phrases that a child can understand when read aloud are especially helpful.

To edit a translation, open the file for [Deutsch](l10n/de.po), [español](l10n/es.po), [français](l10n/fr.po), [norsk bokmål](l10n/nb.po), [suomi](l10n/fi.po) or [svenska](l10n/sv.po). Keep placeholders such as `%s` and `%d` so the game can insert names and numbers. New languages are welcome. The [localization guide](l10n/README.md) covers menus, logos, voices and radio tracks.

## Take a test drive

Try boarding the tram from a platform or finding the pizzeria on foot. Could you tell where to go from the picture, sign or spoken instruction? Tell us which vehicle or character you chose, where you were and what happened. If a model looks wrong, a screenshot and a description of the detail you noticed help us find it.

## Get in touch

[Open an issue](https://github.com/yeager/harbortownrollabout/issues/new) with your idea or correction. A few lines in your own language are enough. If you already have a change ready, [open a pull request](https://github.com/yeager/harbortownrollabout/compare). Issues and attachments are public. Leave out passwords, API tokens, private recordings and identifying details about children.
