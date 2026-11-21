# Lokalt projektminne för Axels spel

## Spelbart i huvudscenen

- Godot 4, 3D, engelska och svenska. Axel och Alma kan väljas i menyn. Spelfigur och intjänade mynt sparas lokalt.
- Ambulans, polisbil, brandbil, svart BMW X5 M60i och taxi. Fordonsbyte till fots, muspedaler, rattindikator, horn, sirener och bromsspår. BMW har även förarvy.
- Sjöstadsinspirerat vägnät med kanaler, broar, småbåtar, kajhus, parkering vid depån, bibliotek, bageri, vårdcentral och brandstation.
- Trafik, cyklister, utryckningar, långsamma A-traktorer, hälsande fotgängare, signaler vid centrala korsningen, dag/natt och gatlampor. Manuellt/automatiskt väder och årstider.
- Telefonen (T) tar emot uppdrag och kvitton på engelska eller svenska och visar de fyra senaste meddelandena under spelomgången.
- Tre uppdragssteg, vägvisande pilar och återkommande taxikörningar. 10 mynt per räddningssteg och 15 per avslutad taxiresa.
- Tvärbanan kan följas som passagerare eller köras på en slinga med tre hållplatser. Dörrskylten säger ”Vi åker inte till Ekerö”.
- Körbar motorbåt i södra bassängen, färjan Lotten i linjetrafik, polishelikopter på patrull.

- Fyra butiker på Stationsalléns södra sida har gångbara entréer. Kanelbulle, saft, glass, korv med bröd, pizza och godis kan köpas för sparade mynt.

- Körbar rödgul flakbärgare med vinschmodell. Hämta en rykande bil eller en bil som tappat ett hjul, kör den på flaket till verkstaden och få 20 mynt.

- Polisstation vid huvudgatan och sjukhus med akutentré öster om norra bron. Brandstationens portar och övriga samhällsbyggnaders entréer vetter mot gatan.

- En granne med barnvagn och en äldre person med rullator promenerar i olika takt längs huvudgatans trottoarer. Båda tillbehören finns som redigerbara Blender-modeller.

- Två låga gröna raggarbilar med vitt tak kör mjukt vinglande inom körfältet och stannar i kö.

- Gångbar träbrygga med pollare och rep mellan Lottens två angöringar. Fyra trappsteg kopplar varje ände till västra kajen.

## Återstående önskemål

- Godstransporter med synlig last och kvittens vid leverans.
- Förfina fordonsformer, särskilt BMW-fronten, brandbilen, polisbilen, Tvärbanan och sittande förare. Förbättra vatten- och fönsterreflektioner, arkitektur och strandpromenad utifrån bildreferenser.
- Utöka gång- och trafiksignaler från centrala korsningen till övriga passager. Speltesta framkomlighet, dialog, läsbarhet, ljudnivå och bildfrekvens i hela staden.
- Följ upp önskemålet om Blender MCP och verifiera faktisk anslutning innan det räknas som klart.

## Källor och verifiering

README.md innehåller engelska spelinstruktioner. Blender-källor finns i source_blender/, byggskript i tools/. Lokala referensbilder ligger i .local-memory/references/ med sina ursprungliga filnamn. Bärgarbildens filnamn börjar med codex-clipboard-56557bc1. Dessa foton ingår inte i Git-repot.

Spelprojektet publiceras i det privata GitHub-repot yeager/axels-emergency-vehicles. Kör Gitleaks före push. Kontrollera alltid aktuella scener, källor och körning när en punkt uppdateras.

- Förbandsväskan följer räddningsuppdraget från vårdaren till spelaren och lämnas på kajen efter leverans.

- Båda övergångsställena över tvärgatan i centrum har gångsignaler. Fotgängare väntar vid kanten på rött och går färdigt om signalen växlar under passagen.

- I Tvärbanans förar- och passagerarläge visar HUD nästa hållplats, vagnens hastighet och nedräkning vid hållplatsen på valt språk.

- Främre vagnens dubbeldörr öppnas mot den korta plattformen vid varje stopp. Dörrbladen glider igen före avgång i både passagerar- och förarläge.

- Tvärbanans förare kan ringa en dubbel klang med H eller skärmknappen. Lyssnaren följer främre vagnen i båda spårvagnslägena.

- I BMW:ns förarvy går det att se åt sidorna och uppåt/nedåt genom att dra med mittenknappen. Förarvyn centreras när man väljer den på nytt.

- BMW:ns två främre vindrutetorkare följer nederbörden. De sveper snabbare vid kraftigare nederbörd och avslutar svepet i parkerat läge när det klarnar.

- Förarvyn renderades i Godot med parkerade och uppfällda torkare. Svepet ökades till cirka 73 grader efter bildkontrollen.

- Spelarambulansens fyra takmoduler lyser nu upp närliggande ytor. Godot-test och bild från följekameran bekräftar ljusen i fast läge och testet kontrollerar båda blinkfaserna.

- De tre utryckningsfordonen i trafiken har blått ljusspill och omväxlande blåljusgrupper. Trafikens inställning för fast eller avstängt blåljus styr även ljusspillet.

- Trafikens sirenton följer både ljudkällans och lyssnarens rörelse. Godot-testet verifierade tonhöjningen när båten och spårvagnen närmar sig, sänkningen när båten backar bort och grundtonen när båda står still.

- Telefonen anger plats och fel vid bärgning, bekräftar lastningen och visar belöningen inför verkstadsresan. Lastning och betalning syns även kort på skärmen.

- Vid återgång från manuellt till automatiskt väder börjar prognosens femminuterstid om. Automatiska årstider utgår från vald årstid och behåller den i en halvtimmes speltid. Nederbörd som passar årstiden fortsätter vid bytet.

- Hård bromsning i snö lämnar bredare grå spår och dämpat däckljud. Slask ger mörkare spår än torr snö. Varje spårsegment behåller färgen från väglaget när det skapades.

- I butikerna visar ”Dina köp” hur många exemplar av varje vara som har köpts. Listan delas mellan butikerna och läser från de lokalt sparade köpen.

- Butiksmenyn har mörk bakgrund och rullning för längre inköpslistor. I ett spelfönster på 800 × 480 verifierades båda kioskknapparnas placering och ett köp med samtliga sex varor i listan.

- Från depån leder en skyltad gångväg över Stationsallén till kaféet. Trottoaren fortsätter längs kioskens, pizzerians och godisbutikens entréer.

- Övergångsstället mellan depån och butikerna på Stationsallén har gångsignaler, trafikljus och stopplinjer i båda körriktningarna. Bilens bromshjälp följer signalen.

- Bromshjälpen tar hänsyn till rörelsen under nästa bildruta och tänder bromsljusen när den begränsar farten. Vid test på Stationsallén bromsade bilen från 8 m/s till stillastående före linjen och körde vidare med bibehållen gas vid grönt.

- När bilen stannar vid signalens stopplinje visas ”Väntar på grönt ljus”. Texten ligger kvar om spelaren släpper gasen och försvinner när signalen ger fri passage.

- Färjan Lottens salongsfönster får varmt sken när staden mörknar. Nattläget granskades i en renderad Godot-bild från kajen och dagsläget kontrollerades utan fönstersken.

- Kanalvattnet speglar Lottens upplysta sidofönster i skymning och natt. Vågorna bryter upp skenet utifrån kamerans och färjans position. Nattvyn från kajen är visuellt kontrollerad i Godot.

- Motorbåtens kölvatten utgår från aktern och ändrar längd och ljushet med farten. Riktningen växlar vid backning. Framåtkörning kontrollerades i renderad Godot-vy och parametrarna testades vid stopp, backning och framfart.

- Motorbåten saktar in mjukt mot farområdets gräns. Med gas och roder kan spelaren svänga tillbaka även från stillastående. Infart och återstart vid norra bojlinjen är testade i Godot.

- Motorbåtens utombordare har ett styrfäste i Blendermodellen. Motorkåpa, växelhus och propellernav svänger tillsammans i Godot och centreras när styrningen släpps.

- Motorbåten har nu en sittande förare bakom styrpulpeten som följer spelarvalet Axel eller Alma. Alma kontrollerades i renderad Godot-vy under båtkörning.
