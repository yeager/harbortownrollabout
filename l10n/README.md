# Lägg till ett språk

Kopiera `messages.pot` till en PO-fil i den här katalogen, till exempel `fi.po`. Sätt språkhuvudet till `Language: fi\n`, översätt varje `msgstr` och skriv språkets eget namn under `LANGUAGE_SELF_NAME`. Behåll platshållare som `%s` och `%d`. Godot läser katalogerna vid spelstart och visar språken i inställningarna. Engelska är källspråket. Lägg nya speltexter i katalogerna och mallen med samma engelska nyckel.

## Bilder och ljud

- En språkknapp kan få en bild i `branding/language-fi.svg`. Logotypen kan läggas i `branding/rollabout-fi.png`. Saknas den visas spelets översatta titel som text.
- Repliker använder `audio/voices/fi_<replik>.wav` med samma filnamn efter språkprefixet som de engelska rösterna. Pratbubblan fungerar även utan inspelning.
- Radiolåtar använder `audio/radio/Låtnamn (FI).mp3`. Engelska låtar kan även ha filnamn utan språkkod. Regionala språk som `sv_FI` kan använda egna resurser och därefter grundspråkets.
- Exportera med alla projektresurser så att även dynamiskt upptäckta kataloger och media följer med.

Kontrollera formatsträngarna med `msgfmt --check-format -o /dev/null l10n/fi.po`.

### Ljud som ingår i spelet

| Språk | Inspelade repliker | Radiolåtar |
| --- | ---: | ---: |
| Svenska | 8 | 12 |
| Engelska | 8 | 8 |
| Spanska, tyska, franska, norskt bokmål och finska | 8 per språk | 0 |

På de fem nya språken läser Piper-röster upp replikerna som visas i pratbubblorna. Radioknappens verktygstips visar när låtar saknas på det valda språket.

De syntetiserade rösterna använder Piper-modellerna Thorsten (tyska), DaveFX (spanska), Harri (finska), Talesyntese (norska) och SIWIS (franska), alla i medium-version. Den franska rösten bygger på SIWIS French Speech Synthesis Database med licensen [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). [SIWIS-dataset](https://datashare.is.ed.ac.uk/handle/10283/2353) · [Pipers röstmodeller](https://huggingface.co/rhasspy/piper-voices)
