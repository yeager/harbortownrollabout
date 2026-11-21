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

- Motorbåtens röda babordslanterna och gröna styrbordslanterna följer dygnsljuset. Båda sidor kontrollerades i renderade nattbilder och släckningen verifierades i dagsläge.

- Båtföraren har en orange flytväst med ryggstycke, två framstycken, reflexdetaljer och spänne. Västen följer figurens storlek och kontrollerades från båda sidor i Godot.

- Start- och pausmenyn visar instruktioner för vald båttur eller spårvagnsroll. Bilväljaren och bilens ljudprov visas endast i vägaktiviteterna. Aktivitetsskiften och båtturens pausknapp är testade i Godot.

- Upplästa hälsningar följer spelets huvudvolym. Vid ljud av stoppas pågående tal och nya hälsningar visas som text. ”Hej!” verifierades i svenskt, ljudlöst läge i Godot.

- Tvärbanans förarläge visar gas och broms nere till höger. Muspedaler fungerar även när spelaren byter från promenad i pausmenyn. Test i Godot bekräftar acceleration med vänster knapp och bromsprioritet när båda hålls nere.

- Tvärbanans främre hytt har en separat Blendermodell med rundad blå nos, lutande vindruta, strålkastare och destinationsskylt. Fronten granskades i en renderad trekvartsvy vid hållplatsen.

- Tvärbanan har kontaktledning och stolpar längs slingan samt strömavtagare på mittvagnen. Taket granskades i Godot och ett körtest passerade fyra stationsstopp med dörröppning och stängning.

- Alla tre spårvagnshållplatser har dubbelsidiga namnskyltar under taket, bänk och markerad plattformskant.

- Tvärbanans status visar avstånd i meter längs rälsen till nästa hållplats tillsammans med namn och fart, på svenska och engelska.

- Vid bärgningen på östra kajen ligger det lossnade hjulet bredvid bilen tills den hämtas. Alla fyra uppdragssteg provades i Godot.

- Parkerade uppdragsfordon kan inte utlösa hämtning medan spelaren åker båt eller tvärbana. Bärgning testad vid samma mål i fem färdlägen.

- Vid räddningsmål visar manuellt körläge först att spelaren ska stanna och sedan vilken knapp som hjälper. Testat att mellanslag i fart inte tvärstoppar bilen och att hjälp efter stopp genomför uppdragssteget.

- Uppdragstelefonens räknare följer de fyra sparade meddelandena och nollställs när inkorgen blir synlig efter paus. Testat i Godot.

- Aktivitetsmenyn visar Taxikörningar eller Bärgningsuppdrag när respektive fordon väljs. Svenska texterna testades genom att växla mellan taxi, bärgningsbil och ambulans.

- Startmenyn beskriver första resan för taxi och bärgningsbil. De svenska beskrivningarna kontrollerades vid fordonsbyte i Godot.

- Avlämnade taxipassagerare syns på trottoaren vid resmålet fram till nästa hämtning. Tre hela taxiresor testades med rätt avlämningsplats och 15 mynt per resa.

- Spelarens bil och AI-trafiken tar hänsyn till synliga taxipassagerare och väntande sjukvårdare. Godot-test visade att en trafikbil stannade för en passagerare i körfältet och körde vidare när vägen blev fri.

- Trafiken räknar den havererade bilens längd och bredd vid inbromsning. I ett körfältstest i Godot stannade bilen bakom hindret och fortsatte när körfältet blev fritt.

- En rödorange varningstriangel med självlysande reflexram står vid båda haverierna och plockas bort när bilen lastas. Synligheten kontrollerades genom alla fyra bärgningssteg.

- Verkstadens fasad mot bärgningsmålet har två sektionsportar med fönster och en skylt med namnet Sjöstadens bilverkstad.

- Verkstadens två garageportar har varmvita nedåtriktade armaturer som följer skymningen. I Godot kontrollerades båda lampornas ljusstyrka och synlighet vid natt och dag.

- Efter avlämningen står en bil utanför verkstadsporten fram till nästa hämtning. Spelarens bil och gångväg tar hänsyn till den parkerade bilen.

- AI-trafiken anpassar fart och avstånd till hur våt och snötäckt vägen är. Samma trafikbil provades på torr, våt och snötäckt väg samt vid en passagerare i körfältet.

- Mark på båda kanalstränderna samt trottoarerna vid huvudgatorna följer nu samma successiva snötäcke och väta som körbanan. Materialvärdena kontrollerades vid fyra snönivåer i Godot.

- Vädret påverkar även stenläggningen vid kajhusen och strandpromenaden. Våt granit mörknar och blir blankare, medan snö samlas först tydligare i fogarna.

- Regndroppar skapar expanderande ringar i kanalens ytreflexer. Effekten följer den flytande nederbörden och tonas ned på avstånd. Kontroll i Godot omfattade regn, slask, snö och uppehåll.

- Regn och snö dämpar direkt solljus och skuggornas kontrast i takt med molntäcket. Testat vid tre nederbördsnivåer med fast dagläge.

- Himlens reflektionskarta dämpar starka högdagrar och får en svalare ton i mulet väder. Godot startades med den ändrade himmelsshadern utan kompileringsfel.

- Sparat manuellt väder gäller redan när en ny spelsession öppnas, inklusive väglag och nederbörd. Testat med sparat snöväder följt av gradvis töväder efter byte till sol.

- När snön smälter blir marken blöt av smältvatten. I Godot provades övergången snö–sol tills snön var borta och vägbanan sedan torkade.

- Nederbördspartiklarna döljs i butiksvyn och syns igen utanför. Entré och utgång provades vid samtliga fyra butiker.

- Kafé Bullen har en plåt med sex modellerade kanelbullar på disken. Varje bulle har en kanelspiral som följer den välvda ytan.

- Pizzerian visar en margherita på träbräda vid disken, med gräddad kant, tomatsås och mozzarella.

- När pengarna inte räcker visar butiken beloppet som saknas och hur spelaren tjänar mynt. Svenska besked och köp med exakt pris provades i kaféet.

- Vid inträde i en butik får första varan tangentbordsfokus. Ett köp av en kanelbulle med Enter verifierades med Godots inmatningssystem.

- Butiksmenyn visar hur man väljer vara med Tabb och köper med Enter. I kiosken provades ett köp av korv med bröd med dessa två tangenter.

- Kiosktestets intermittenta avslutsvarning identifierades i Godots verbose-logg som ambulansens AudioStreamWAV och dess uppspelare. Fem upprepningar med 250 ms mellan frigjord scen och testprocessens avslut genomförde köpet utan resursvarning. Normal spelavslutning är inte undersökt i detta test.

- Tre separata grafiska Godot-processer under X11 fick fönsterhanterarens normala stängningsmeddelande medan ambulanssirenen spelade. Alla tre avslutades med kod 0 utan resursvarning i den utförliga loggen.

- Butikskvittot visar vara och betalt belopp på svenska och engelska. Svenskt kvitto för en kanelbulle kontrollerades mot tre dragna mynt.

- Bärgarens bakre hjullyft har två modellerade hjulstöd med gångjärnstappar och infångningsarmar. Blender-källan och spelmodellen uppdaterades och importerades i Godot.

- Bromshjälp för personer, framförvarande trafik och rödljus använder bilens uppmätta längd framåt respektive bakåt. Bärgarens nya hjulstöd ingår i bakmåttet även när den parkeras.

- Trädkollisioner använder främre stötfångarens mått vid körning framåt och bakre utrustningens mått vid backning. Test med bärgaren stannade med mindre än en centimeters frigång åt båda håll.

- Parkerade fordons kollisionsytor utgår från modellens faktiska ytterkanter. Till fots provades frigången framför och bakom bärgaren i tre olika riktningar.

- Depån har en separat asfalterad ruta för bärgaren och en avslutande linje vid taxiplatsen. Godot-testet kontrollerade att hela bärgarens fotavtryck ryms på asfalten efter spelstart.

- Dörrmarkören visar fordonets namn och F för att kliva in. Svensk uppmaning och byte från promenad till bärgare verifierades i Godot.

- Vid urstigning hamnar spelaren längs samma dörrlinje som används vid instigning. Testat att bärgaren kräver stopp och att spelaren direkt kan nå samma dörr igen.

- Urstigning vid färjelägets trappa använder trappstegets höjd direkt. Verifierat med en parkerad ambulans vid västra kajen.

- Förbandsleveransen kvitteras med plats och ersättning både i telefonen och på slutskärmen. Tre genomförda steg verifierades med Alma och svenska texter.

- Språkbyte på slutskärmen verifierades svenska–engelska–svenska genom språkvalets signal i Godot. Leveranskvittot översattes direkt, Almas namn behölls och belöningen betalades endast en gång.

- En hamnvärd i orange jacka väntar vid småbåtshamnen under förbandsleveransen och håller väskan efter överlämningen. Detta och kvittot provades genom alla tre uppdragsstegen.

- Grannen i turkos jacka står vid första hjälpmålet på torget med handen höjd och sänker armen efter hjälpen. Båda tillstånden verifierades genom räddningsuppdraget.
- Även uppdragspersoner kan nu hälsa när Axel eller Alma kommer fram till fots. Godot startkontrollerades utan grafik.
- BMW X5 har en sittande förare som följer spelarvalet. Testat med Alma i Godot vid byte mellan följkamera och förarvy. Placeringen återstår att granska visuellt.
- BMW-förarens händer följer rattkransen. Båda figurernas handpositioner kontrollerades i Godot vid neutralläge och fullt rattutslag i båda riktningarna.
- Axel och Alma har böjda armbågar i BMW:n. Båda poserna granskades i renderade närbilder med karossen dold. Handpositionerna testades även med fullt rattutslag.
- Förarens profil och fotgängarnas ansikten har modellerad näsa och öron. Både Axel och Alma kontrollerades i renderade bilder genom BMW:ns sidoruta med karossen synlig.
- Havererade bilar visar gula varningsblinkers fram och bak. Båda hämtplatserna, transport på flaket och tre ljuslägen verifierades i Godot.
- Bärgaren visar separata instruktioner för att stanna, lasta och lasta av. Svenska texter testades vid alla fyra uppdragsstegen med automatisk och manuell lastning.
- Taxins stopp visar när passageraren ska hämtas eller släppas av, med svensk och engelsk text. Tre taxiresor testades genom sex stopp, med automatisk och manuell hjälp och totalt 45 intjänade mynt.
- Väntande taxipassagerare står vända mot taxins stoppunkt och håller upp handen. Riktning och gest testades på torget, vid kliniken och vid småbåtshamnen.
- Avsläppta passagerare placeras på gångytans uppmätta höjd och vänder sig mot taxins stoppunkt. Samtliga tre avlämningar verifierades i Godot.
- Vid taxikörning och bärgning visar markeringen vägen tillbaka till det parkerade uppdragsfordonet till fots. Återinträde och byte till båt eller Tvärbana verifierades i Godot.
- Till fots visar returmarkören dörren som användes vid urstigning. Testat i Godot med blockerad högerdörr på taxi och bärgare, inklusive återinträde på vänster sida.
- Trafiken börjar bromsa när spelaren är på väg in i körfältet inom 1,4 sekunder. Stillastående och rörelse bort från körfältet jämfördes med rörelse mot körfältet i Godot.
- Bilar tutar på en långsam A-traktor endast om den begränsar avståndet framåt. Test i båda riktningarna med en fotgängare emellan och därefter fem sekunders följekörning gav minst 4,3 meters lucka.
- Raggarbil och A-traktor har egna syntetiserade tutor. Cyklisternas ringklocka och de två nya ljudens koppling till trafikfordonen verifierades i Godot.
- Paus avbryter tutor, däckljud och uppläst hälsning samt tystar trafiksirener direkt. Paus och återgång med samtidiga fordonsljud testades i Godot.
- Paus fryser återstående lästid för tillfälliga meddelanden. Taxins bekräftelse vid upphämtning testades med 60 sekunders simulerad paus och återupptagen nedräkning.
- Pausmenyn visar den aktuella uppdragstexten från telefonen. Sex uppdragssteg verifierades på svenska och engelska, utan dubbla telefonmeddelanden.
- Förbättrad textkontrast på ljusa knappar vid tangentbordsfokus, muspekare och tryck. Rendering vid 800 × 500 verifierade fokuserad fortsättknapp och två synliga rader för bärgningsuppdraget på svenska och engelska.
- Sjöstadsskolan med putsfasad och koppartak modellerades i Blender. Skoltaxi hämtar och lämnar elever och busslinje 502 trafikerar fyra hållplatser. Båda uppdragsserierna samt utbetalning testades i Godot.
- BMW M3 E30, Volvo 240, Saab 96, Tesla Model S och stadsbuss finns i fordonsval och depå. Egna Blenderkällor, tutor och lågmält eldrivljud ingår. Fordonsradio med egen instrumental slinga startas med J.
- Compatibility, Mobile och Forward+ renderade buss och skola på datorns Radeon. play.sh kan starta alla tre och välja AMD FSR 2.2 i Forward+. Ingen mätning av bildfrekvens eller verifiering på annan hårdvara ännu.
- Linje 502 visar nästa hållplats på bussens frontskylt. Verifierat över fyra stopp, ett nytt varv och fri körning.
- Alla fyra hållplatsstolpar visar linjenummer och hållplatsnamn på två motsatta skyltfronter, riktade längs respektive gata. Kontrollerat i Godot.

Inställningar finns i en separat dialog med flikar. Renderaren väljs under Grafik och aktiveras vid nästa start. Verifierat byte från Compatibility till Forward+ med FSR2 på AMD.

Västra stadsdelen ansluter till vägnätet i tre korsningar. Spelgränsen är nu 690 × 151 m. Axel och Alma använder Blender-modellerade ansikten och jackor. Bänken med färgprover byter jackfärg och bryggvärden har en särskild replik. Fullfart har dubbel toppfart för vägfordon, lugn körning behåller 30 km/h.
Renderad närbild i Compatibility visade en glipa under huvudet. Hals, hår, ögon och mun justerades och kontrollerades i en ny spelrendering.
Snöskoter från Blender med band, skidor, fjädring och synlig förare. Provkörd i Godot med gas, broms och avstigning. Parkbänken har fyra ben. Axel har formade ärmar, byxben, händer och skor.
Snöskotern har nu en egen syntetiserad motorloop med hastighetsstyrd tonhöjd. Uppspelning och fordonsval verifierades i Godot.
Snöskoterns båda skidor och styre följer nu styrutslaget. Förarens handpositioner följer handtagen. Testat med styrinmatning i Godot.
Skoterns terrängfart följer snötäcket. Provkört på västra fältet med barmark, halvt och fullt snötäcke i båda körlägena.
Snöskoterns nattljus utgår från de två Blender-modellerade lyktglasen. Båda ljuskällornas positioner verifierades i Godot.
Nattljuset provrenderades i Godot Compatibility på västra huvudgatan med samma kamera och lyktorna tända respektive släckta. Båda ljuskäglorna tillsammans belyser asfalten framför skidorna.
Skoterföraren sitter nu grensle med böjda knän. Modellen har fotbrädor med grepp på båda sidor. Kontrollerat från sidan i Godot och provkört efter omimport.
Västra stadsdelens huvudgator och tvärgator har streckade mittlinjer. Alla 185 markeringar kontrollerade över vägbanan och utanför korsningarna i Godot.
Västra stadsdelen har 75 gatlyktor längs huvudgatorna och tvärgatorna. Verifierat i Godot att alla tänds på natten och släcks på dagen.
De tre västra huvudgatorna har 2,8 meter bred gångbana på båda sidor. Framkomlighet verifierad längs sex stråk och över mellanliggande tvärgator.
Fem grannar promenerar i västra kvarteren. Verifierade hälsning vid möte och vändning på trottoaren vid kvarterets slut i Godot.
Gångbanorna längs de västra tvärgatorna ansluter i nivå runt alla tio kvarter. Gånghöjd och framkomlighet kontrollerade runt varje kvarter i Godot.
Buss 502 hämtar nu även vid Västra torget och lämnar vid Västerängen. Godot-test genom alla sex hållplatsutbyten med destinationsskylt, belöning och återgång till torget.
Även medresenärerna vid busshållplatserna hälsar. Storlek och avstånd i gruppen återställs före placering vid byte från skoltaxi till buss. Testat vid västra hämtning och lämning.
Nattvy jämförd i Compatibility, Mobile och Forward+ på AMD. Natthimlens färger färgrymdskonverteras nu av Godot så Vulkan-lägena inte visar en ljus skymningshimmel vid midnatt.
I automatiskt dygnsläge vandrar ljusriktningen genom dagen, med lägre och varmare ljus vid gryning och skymning. Riktning, skugginställning och kontinuitet över dygnsskarven testade i Godot.
Kanalens vattenmaterial sprider ljus i regn och skum, med skarpare solblänk på lugnt vatten. Färjans fönsterspegling använder vågens reflekterade siktlinje. Kanalvy renderad med alla tre renderarna.
Lotten drar ett V-format kölvatten bakom den aktiva aktern. Styrkan följer överfartens hastighet och går till noll vid kaj. Båda riktningarna testade och överfarten granskad i Forward+.
Motorbåtens svall utgår från aktern vid framfart och från fören vid backning. Godot-test med tre kurser, båda färdriktningarna och stillastående.
Motorbåtens inbromsning mot östra kajgränsen verifierad i Godot med gasen nedtryckt från 9 m/s vid 30, 60 och 120 uppdateringar per sekund. Farten nådde noll vid gränsen och båten kunde backa loss vid alla tre frekvenser.
