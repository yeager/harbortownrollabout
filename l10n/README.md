# Språk i spelet

Spelet följer systemspråket vid första start. Om språket saknar stöd används engelska. Öppna **Inställningar**, välj fliken med jordgloben och tryck på språkets namn. Du kan välja Deutsch, English, Español, Français, Norsk bokmål, Suomi eller Svenska. Valet gäller direkt och sparas till nästa gång du spelar. Välj **Systemspråk** för att följa enhetens språk igen.

## Lägg till ett språk

Skapa en ny översättningsfil från projektroten med GNU gettext. Följande exempel lägger till polska. Byt ut `pl` mot språkkoden för det nya språket.

```sh
msginit --no-translator --locale=pl --input=l10n/messages.pot --output-file=l10n/pl.po
```

`msginit` väljer språkets pluralregel och skapar ett översättningsfält för varje form. Fyll i varje `msgstr`, även de numrerade fälten för exempelvis mynt och poäng. Behåll platshållare som `%s` och `%d`. Under `LANGUAGE_SELF_NAME` skriver du språkets namn på det egna språket. Det namnet visas på språkknappen.

Lägg också till spelets översatta titel som `GenericName[pl]` och en kort beskrivning som `Comment[pl]` i `packaging/linux/harbortown.desktop`. Språkkontrollen jämför programmenyns titel med spelets och kontrollerar att beskrivningen finns.

Godot läser katalogerna vid spelstart. Engelska är källspråket. Lägg nya speltexter i katalogerna och mallen med samma engelska nyckel.

## Bilder och ljud

- En språkknapp kan få en bild i `branding/language-pl.svg`. Översätt speltiteln under `Harbor Town Rollabout` och lägg logotypen med samma titel i `branding/rollabout-pl.png`. Startskärmen och huvudmenyn använder samma bild. För en regional variant försöker spelet först läsa variantens logotyp, sedan grundspråkets och sist den engelska.
- Repliker använder `audio/voices/pl_<replik>.wav` med samma filnamn efter språkprefixet som de engelska rösterna. Pratbubblan fungerar även utan inspelning.
- Radiolåtar använder `audio/radio/Låtnamn (PL).mp3`. Engelska låtar kan även ha filnamn utan språkkod. Regionala språk som `sv_FI` kan använda egna resurser och därefter grundspråkets.
- Exportera med alla projektresurser så att även dynamiskt upptäckta kataloger och media följer med.

Kör `tools/check_localizations.sh` från projektroten för att kontrollera alla språk. Kontrollen hittar saknade översättningar i förhållande till mallen, fel i markerade formatsträngar och saknade spellogotyper.

### Ljud som ingår i spelet

| Språk | Inspelade repliker per språk | Fullängdslåtar per språk | Stationsrop med musik per språk |
| --- | ---: | ---: | ---: |
| Svenska | 16 | 12 | 0 |
| Engelska | 16 | 8 | 0 |
| Spanska, tyska, franska, norskt bokmål och finska | 16 | 0 | 1 |

De 16 replikerna omfattar hälsningar, småprat och uppdragen med den borttappade skon och katten. Tomtens ”Ho ho ho” är en gemensam inspelning utöver de språkvisa replikerna.

Om både den regionala och grundspråkets låtlista saknas spelar radion engelska låtar. Stationsrop räknas inte som låtar. Vi söker hela låtar på dessa språk. [Så kan du bidra](../CONTRIBUTE.md).

De syntetiserade rösterna använder Piper-modellerna Thorsten (tyska), DaveFX (spanska), Harri (finska), Talesyntese (norska) och SIWIS (franska), alla i medium-version. Den franska rösten bygger på SIWIS French Speech Synthesis Database med licensen [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). [SIWIS-dataset](https://datashare.is.ed.ac.uk/handle/10283/2353) · [Pipers röstmodeller](https://huggingface.co/rhasspy/piper-voices)
