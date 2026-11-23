# Lägg till ett språk

Skapa en ny katalog från projektroten med GNU gettext. Följande exempel lägger till polska. Byt ut `pl` mot språkkoden för det nya språket.

```sh
msginit --no-translator --locale=pl --input=l10n/messages.pot --output-file=l10n/pl.po
```

`msginit` väljer språkets pluralregel och skapar ett översättningsfält för varje form. Fyll i varje `msgstr`, även de numrerade fälten för exempelvis mynt och poäng. Behåll platshållare som `%s` och `%d`. Under `LANGUAGE_SELF_NAME` skriver du språkets namn på det egna språket. Det namnet visas på språkknappen.

Godot läser katalogerna vid spelstart. Engelska är källspråket. Lägg nya speltexter i katalogerna och mallen med samma engelska nyckel.

## Bilder och ljud

- En språkknapp kan få en bild i `branding/language-fi.svg`. Logotypen kan läggas i `branding/rollabout-fi.png`. Om bilden saknas och språket använder den engelska titeln visas den engelska logotypen. Övriga titlar visas som text tills en egen logotyp finns.
- Repliker använder `audio/voices/fi_<replik>.wav` med samma filnamn efter språkprefixet som de engelska rösterna. Pratbubblan fungerar även utan inspelning.
- Radiolåtar använder `audio/radio/Låtnamn (FI).mp3`. Engelska låtar kan även ha filnamn utan språkkod. Regionala språk som `sv_FI` kan använda egna resurser och därefter grundspråkets.
- Exportera med alla projektresurser så att även dynamiskt upptäckta kataloger och media följer med.

Kör `tools/check_localizations.sh` från projektroten för att kontrollera alla språk. Kontrollen hittar saknade översättningar i förhållande till mallen och fel i markerade formatsträngar.

### Ljud som ingår i spelet

| Språk | Inspelade repliker | Radiolåtar |
| --- | ---: | ---: |
| Svenska | 8 | 12 |
| Engelska | 8 | 8 |
| Spanska, tyska, franska, norskt bokmål och finska | 8 per språk | 0 |

På de fem nya språken läser Piper-röster upp replikerna som visas i pratbubblorna. När låtar saknas på det valda språket visar den inaktiva radioknappen en översättning av ”Inga låtar än”.

De syntetiserade rösterna använder Piper-modellerna Thorsten (tyska), DaveFX (spanska), Harri (finska), Talesyntese (norska) och SIWIS (franska), alla i medium-version. Den franska rösten bygger på SIWIS French Speech Synthesis Database med licensen [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). [SIWIS-dataset](https://datashare.is.ed.ac.uk/handle/10283/2353) · [Pipers röstmodeller](https://huggingface.co/rhasspy/piper-voices)
