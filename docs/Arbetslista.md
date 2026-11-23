# Arbetslista för Full rulle i Sjöstaden

Listan innehåller 100 jobb. En tom ruta är öppen. En punkt bockas av när beteendet är verifierat. Delresultat och beroenden står vid respektive punkt.

## Att kunna spela själv

- [x] 01. Säg igen. En högtalarknapp i telefonen läser upp nästa uppdragssteg på valt språk, även efter att pratbubblan försvunnit. Verifierat i Godot 4.7 dev med 49 instruktioner på sju språk (343 Piper-klipp).
- [x] 02. Fortsätt där jag slutade. Huvudmenyn återställer plats, fordon och uppdragssteg efter avslut. Verifierat i Godot för promenad, butik, sparkcykel, vägfordon, grävmaskin, motorbåt, färja och spårvagn. Testerna omfattar 24 steg med åtta uppdragsfordon samt buss, taxi, bärgning, sophämtning, glassförsäljning och återlämning av katten och skon. En ofullständig sparpunkt hindrar inte nystart.
- [x] 03. Frivilligt trafikfritt övningsområde. Välj Övningskör i huvudmenyn. Gas, broms, backning, urstigning, återställning och återinträde har verifierats i Godot.
- [x] 04. Bildstöd för nästa handling i telefonen. Varje aktiv instruktion har en bild, även när två uppdrag till fots pågår samtidigt. Bussens bilder för på- och avstigning har kontrollerats längs hela rutten.
- [x] 05. Valbar textstorlek för pratbubblor, telefon och butiker utan avklippta knappar. Pratbubblor kan förstoras 40 procent i språkinställningarna. Text och bakgrund följs åt och valet har verifierats efter omstart. Butikernas textstorlek har också verifierats vid köp. Även telefonens rubriker, meddelanden och knappar följer valet. Telefonlayouten har kontrollerats på alla sju språk.
- [x] 06. Valbar längre lästid för pratbubblor under Inställningar → Språk. Kattuppdragets svenska replik fick 10,4 sekunder mot normalt 5,2. Sparat val verifierat efter omstart.
- [x] 07. Separata volymreglage för tal, radio och motorer. Kontrollerade i Godot med radion avstängd, tal på 35 procent och motorer på 80 procent efter omstart.
- [x] 08. Mjuk och justerbar dämpning av radion under tal. Separat radiokompressor med 500 ms återgång. Reglagets ytterlägen, mellanläge och sparade val verifierade i Godot.
- [x] 09. Lugnt läge under Grafik ger stadiga varningsljus, sänker trafik och motorer med 10 dB och håller korvkioskens neon stadigt tänd. Sparat val och återställning av ljudnivån verifierade i Godot.
- [ ] 10. Tangentbindningar som spelaren kan ändra. Radion och nästa låt har valbara tangenter under Ljud. Gång och körning kan växlas mellan WASD och 8, 4, 5, 6 med uppdaterade hjälprader. Sifferstyrningen har provkörts i Godot med samtliga 26 vägfordon, grävmaskinen, motorbåten och spårvagnen. Återgång till WASD verifierad. För återställning kan spelaren välja R eller Backspace. Valet och telefonens hjälprad verifierades efter omstart på övningsbanan. Hopp till fots kan bindas till E eller 0. Hopphöjd och svensk hjälprad verifierades med 0 efter omstart. Kamerahöjden till fots kan styras med 9 och 3. Båda riktningarna och svensk hjälprad verifierades efter omstart. Telefonen kan öppnas och stängas med T eller F2. F2 och svensk knapptext har provats före och efter omstart. Avsluta kan bindas till F8 eller F10. F8 öppnade bekräftelsen efter omladdning med den sparade inställningen. F3 kan aktiveras som extra tangent för att kliva i och ur fordon. Båda riktningarna har provats efter omladdning. F4 kan också användas för tutan. Standardläget och tutning efter omladdning med F4 aktiverat har provats i Godot. F6 kan läggas till för byte av kameravy. Standardläget, F6 efter omstart och återgång med C verifierades i Godot. F7 kan aktiveras för paus och fortsätt. Båda lägena verifierades efter omladdning. Elsparkcykeln kan fällas ut och ihop med U eller F9. F9 och båda hjälpraderna verifierades efter omladdning. Löpning kan bindas till Ctrl. Svensk gånghjälp och meddelandet efter vila visar Ctrl efter omstart. Insert kan aktiveras som extra tangent vid uppdragsmål. Taxiresan verifierades med hämtning via mellanslag och betalning via Insert efter omstart. Svensk körhjälp och uppmaningen vid avstigning visar vald tangent. Övriga spelkontroller återstår.

## Hitta, köra och komma ombord

- [x] 11. Fordonsgalleri med fem bildkategorier och Alla fordon. Alla 29 fordonsbilder verifierade i exakt en kategori vardera och tillgängliga igen under Alla fordon.
- [x] 12. Markera och hitta favoritfordon med stjärnor. Sparade favoriter, filtrering, avmarkering och start av motorbåten verifierade i Godot.
- [x] 13. Gul, tresidig stoppmarkering vid sophämtning, taxiresor och bärgning. Placering och riktning kontrollerade för tre sopbilsstopp, tio taxisteg och fyra bärgningssteg.
- [x] 14. Två vägvalssymboler inför korsningar längs den aktuella körrutten. Vänster, höger, U-sväng och två svängar i följd kontrollerade på navigatorns avrundade körfält i Godot.
- [x] 15. Översiktskarta med gatunät, spelarposition och fem klickbara landmärken under friåkning. Kartval, återgång från paus, ruttpilar och avslutad vägledning vid ankomst verifierade i Godot.
- [x] 16. Mjuka kollisioner mellan spelarfordonet och rörlig vägtrafik. Båda massorna, spelarens last och fordonens hastigheter och riktningar påverkar stöten. Påkörning bakifrån, olika massor, mötande riktning och assisterade stopp verifierade.
- [x] 17. Tydlig tröskel och markering vid den användbara spårvagnsdörren.
- [x] 18. Traktorns förarvy med C. Kontrollerad i spelvyn för Axel och Alma med sikt över huven och båda framskärmarna.
- [x] 19. Valbar arbetskamera där skoptänderna och marken syns samtidigt.
- [x] 20. Användbara förarvyer i buss och sopbil med sikt mot hållplats respektive kärl.

## Uppdrag med synliga resultat

- [x] 21. Grävmaskinen kan ta sand ur en hög och tippa den i en grop eller på ett flak.
- [x] 22. Ploga vägen till skolan och visa den öppnade passagen.
- [x] 23. Klipp en avgränsad picknickäng och visa när arbetet är färdigt. Åkgräsklipparen stannade innanför samtliga fyra spelgränser vid körning framåt och bakåt, både i staden och på övningsbanan. När den parkerades längs varje kant gick det att kliva av mot insidan och sedan kliva på igen.
- [x] 24. Sorteringsrunda med kärl märkta med både bild och färg.
- [x] 25. Visa hur verkstaden lagar den bärgade bilen.
- [x] 26. Barnvänligt brandbilsuppdrag med slang och vatten.
- [x] 27. Leverera en synlig matkasse i shoppingmopedens korg.
- [x] 28. Matcha kundens bildbeställning mot glassbilens meny.
- [x] 29. Valbara ledtrådar med ljud eller föremål i katt- och skouppdragen.
- [x] 30. Varsitt uppdrag för schäfern och den tama komodovaranen.

## Modeller, människor och stadsliv

- [ ] 31. Betygsätt modeller mot jämförbara bilder av silhuett, proportioner, material, interiör och funktion.
  - Trafikljus, jämfört med spelarens foto och två närbilder i Godot. Silhuett 90, proportioner 86, färg/material 83, exteriöra detaljer 75, funktion 100. Interiör ej tillämplig. Bedömt medel 87/100. De tre linserna och skärmarna känns igen även snett från sidan. Efter den första bedömningen fick varje lucka kant, två gångjärn och ett låsbeslag. De cylindriska gångjärnen syns längs luckornas kant i en sned gatuvy. Det tända glaset har fått en ljus kärna strax nedanför mitten, kontrollerad från samma kameravinkel i alla tre signalfaser.
  - Midsommarstång, jämförd med de tre inskickade fotografierna och en Godot-rendering från marknivå. Silhuett 96, proportioner 94, material/färg 90, detaljer 93, årstidsfunktion 100. Interiör ej tillämplig. Medel 95/100 efter att tvärslån och girlanderna fått nedhängande kvistar. Närbilden visar nu sågtandade blad och vikt mittnerv. Kransens kvistar och blommor är fortfarande mer regelbundna än på fotografiet.
- [x] 32. Granska Axel och Alma från sidan under en hel gångcykel och rätta anatomiska avvikelser. Sidovyer av båda figurerna vid åtta jämnt fördelade faser finns i [gångstudien](player-walk-side.png). Godots gångtest verifierar hälisättning, tåfrånskjut och kontakter under gång och löpning. Armarnas pendelplan följer nu bröstkorgens vridning genom hela steget.
- [x] 33. Kontrollera och förbättra handgrepp om ratt, styre, hundkoppel och kasse.
- [x] 34. Animera shoppingmopedens sidoinsteg, kroppsvridning och fötter in under styret.
- [x] 35. Låt hundkopplet slacka och sträckas gradvis när avståndet ändras.
- [x] 36. Ge komodovaranen låg gång, växelvisa steg och följande svans i svängar.
- [x] 37. Visa bussens passagerare och förändringen i kupén vid hållplatserna.
- [x] 38. Lägg till en kioskförsäljare som räcker fram den beställda rätten.
- [x] 39. Låt spelaren bära, använda eller ställa fram varor från klädbutiken.
- [ ] 40. Ge kvarteren egna landmärken som är lätta att känna igen. Verkstadskvarteret har fått en avsmalnande, rödvit fabriksskorsten som når 13 meter över marken. Sikt i mörker har kontrollerats med renderade vyer från vägen väster om verkstaden och från bron österut. Sjöstadsskolan har fått ett fasadur över entrén som följer spelets dygn. Synligheten har kontrollerats från busslinje 74. Brandstationens utstickande brandsymbol kan ses från båda körriktningarna vid bageriet, verifierat i två renderade gatuvyer. Vid mjölleveransens mål hänger en kaffekopp med fat över bageriets entré. Den syns från båda håll vid övergångsstället. Stadskartan visar både bageriets lastplats och åskådarbänken vid kanalens boulebana. Aktivt mål markeras i kartan och platslistan även efter omladdning. Alla åtta kartnålars träffytor har kontrollerats på svenska. Vid boulebanan behålls målet när bilen parkeras och vägvisningen slutar när bänken går att använda till fots.

## Radio, sparande och utgåvor

- [ ] 41. Slutför 20 svenska och 20 engelska radioinspelningar. 12 svenska och 8 engelska filer finns. Suno angav kvotförnyelse 22 december 2026.
  - Saknade svenska inspelningar: En sväng med en svamp, Plaskoteket, Popcorn under huven, Godnatt, lilla rondell, Min sko vill spela trummor, Gurka på gitarr, Bubbelgumplanet, Rävens saxofon.
  - Saknade engelska inspelningar: Bass in My Flask, The Banjo Hen, The Moon Wants Mash, Hiccup Digger, Mitten on the Tram, The Ice Cream Crew, Hot Dog in a Hat, The Toot Quartet, A Blanket for a Bridge, The Cat’s Elevator Jazz, Rain on My Tin Roof, Dish Brush Encore.
- [ ] 42. Lägg till lokala stationsrop och musik för spanska, tyska, franska, norska och finska. Fem inspelade Piper-stationsrop med instrumental signatur finns och spelas vid språkbyte. Sångbara versioner av ”Bas i min termos” finns i sångboken på alla fem språken. Inspelningar av fullängdslåtar återstår.
- [x] 43. Visa en tydlig låtbild och titel när radion byter låt.
- [x] 44. Visa påskägg, uppdragsminnen och inköp som bilder i en samling. Alla butiksvaror har en produktbild vid köp och i köplistan. Telefonen visar en stjärnrad med en fast plats för var och en av stadens åtta gömda stjärnor. Belönade uppdragsmoment ger sparade bildminnen i telefonen. Telefonen visar också en bild per köpt vara, även efter att den ätits upp.
- [x] 45. Gemensamma framsteg är förvalda. Separata spelarprofiler kan väljas i huvudmenyn. Byte mellan Axel, Alma och gemensam plånbok samt samling har verifierats efter omstart. Via huvudmenyn återupptog båda förarna rätt fordon på rätt plats efter omladdning i ett separat regressionstest.
- [x] 46. Visa med bilder vad som gav poäng och mynt efter uppdraget.
- [x] 47. Linuxpaketen provstartades utan grafik med den officiella Godot 4.7-dev5-mallen. Installerad DEB och uppackad tar.gz startade på Ubuntu 22.04 (glibc 2.35) och installerad RPM på Fedora 43 (glibc 2.42).
- [ ] 48. Publicera provstartade Windows- och Mac-paket med direkta nedladdningslänkar. Windows x64, Mac Intel och Mac Apple Silicon har publicerats som ZIP-filer med direktlänkar i README. SHA-256 verifierad för varje arkiv. DMG för Intel och Apple Silicon har också publicerats. Filsystem, appinnehåll, processorarkitektur och publicerade kontrollsummor har verifierats på Linux. Inno Setup-installationen med sju språk har byggts och installerats med svenska valt under Wine. Installerade spelfiler matchar Windows-arkivet och spelet startade med OpenGL under Wine. Provstart i Windows och macOS återstår.
- [x] 49. Mät bildtider under en reproducerbar färd förbi macken med kvällsljus, trafik och regn. Mätt med `tools/station_frame_times.gd` i Godot 4.7 dev, Compatibility, Radeon Renoir, 1920 × 1080. Efter uppvärmning mättes 240 bilder över 48 meter med tio trafikfordon. Median 40,14 ms, 95:e percentilen 51,09 ms och längst 76,77 ms. Den körningen avslutades normalt. Vissa upprepningar kraschade, även vid avslut.
- [ ] 50. Speltesta med barn utan muntlig vägledning. Observera val av favoritbil, korvköp och återgång till bilen. Kräver en medverkande familj.

## Brandbilen och stationen

- [x] 51. Forma dubbelhyttens nedre fönsterkant efter sidobilden. Jämför båda dörrarna från passagerarsidan i spelet.
- [x] 52. Bygg in dörrhandtagen i fördjupningar och låt springan mellan dörrarna synas genom reflexmönstret.
- [x] 53. Forma frontens luftintag så att de smalnar av mot hörnen. Ta en jämförelsebild rakt framifrån.
- [x] 54. Dela backspeglarna i huvudspegel och vidvinkelspegel med varsin spegelyta. Kontrollera silhuetten från sidan.
- [x] 55. Modellera blåljusrampens genomskinliga kåpa och separata lysdioder. Granska rampen både släckt och tänd.
- [x] 56. Ge utrustningsluckorna lås, grepp och ändskenor. Kontrollera att de sitter på själva luckorna i närbild.
- [x] 57. Passa in de bakre fotstegen och dragkroken under jalusierna efter bakifrånbilden.
- [x] 58. Brandbilens främre sidolucka rullas upp när slangövningen startar. Slangrullen syns bakom luckan och luckan stängs när övningen är färdig. Öppning, återställning och utseende verifierade i Godot.
- [x] 59. Brandstationens mittport rullas upp när brandbilen närmar sig och hålls öppen tills hela bilen passerat. Inkörning och backning ut på fri infart verifierades med fordonsfysiken i Godot.
- [x] 60. Efter sista branduppdraget kan spelaren välja att återvända till plats 711. Rutan har vita linjer och fordonsnumret på marken. Ett träd som blockerade infarten flyttades och tio meters backning provkördes i Godot. Vägvisningen avslutas när hela brandbilen står inom linjerna med fronten mot utfarten.

## Boule och strandpromenad

- [x] 61. Låt spelaren tacka ja till en omgång boule och ta plats i kastringen. F vid kastringen anmäler spelaren till nästa kast. Anmälan, avbokning, placering i ringen, kast och återgång till gång har provats i Godot.
- [x] 62. Låt spelaren sikta på lillen och välja mellan ett kort, ett mellanlångt och ett långt kast med bilder. Reglaget styr siktet i sidled. Tre bildknappar visar kastbågarna. Med siktet 60 cm åt höger stannade kloten 1,5 m före, i höjd med respektive 1,5 m bakom lillen. Kastvalet har även kontrollerats i renderad spelvy.
- [x] 63. Andra spelarens klot kan träffa det första snett och sätta det i rullning. I Godot flyttades det träffade klotet 28 cm och båda stannade med 35 cm mellan centrum. Kontrollerat med tidssteg på både 1/60 och 1/10 sekund.
- [x] 64. Efter tredje kastet visas en gul ring i fem sekunder runt klotet närmast lillen. Kontrollerat med en hel omgång, 0,1 mm skillnad och delad förstaplats vid exakt lika avstånd.
- [x] 65. Efter resultatvisningen går de tre boulespelarna i tur och ordning fram till sina klot, böjer knäna, plockar upp kloten och bär tillbaka dem till kastringens väntplatser. Två omgångar i följd med alla sex kast och hämtningar kontrolleras i tests/boule_rounds.gd.
- [x] 66. Kontakt mellan två rullande eller stillaliggande bouleklot ger ett kort metalliskt klick vid träffpunkten. Grusljudet spelas vid nedslaget. Uppspelningen av klicket verifierades under andra spelarens kast.
- [x] 67. Ge boulebanan en sittbänk där spelaren kan sätta sig, följa omgången och resa sig igen. Provad i Godot med ett helt kast från bänken och uppstigning på fri mark.
- [x] 68. Båda färjelägena har dubbelsidiga vägvisare under Lottens hållplatsskylt. Ett räfflat klot, en gul lille och en pil visar vägen mot närmaste bro på vägen till boulebanan. Pilarnas riktning är kontrollerad från båda sidor.
- [x] 69. Gör ett uppdrag där en granne behöver hjälp att hitta sin termos efter boulematchen. Efter matchen ber spelaren i grön jacka om hjälp via telefonen. Hämtning vid bänken, överlämning och en engångsbelöning har verifierats i Godot.
- [x] 70. Låt spelaren lämna tillbaka ett upphittat paraply vid färjeläget och se ägaren fälla upp det när det regnar. Hämtning, överlämning samt utfällning i regn och hopfällning vid uppehåll har verifierats i Godot.

## Leveranser och stadens butiker

- [x] 71. Ge bageriet en morgonleverans av mjöl. Visa säckarna först på flaket och sedan vid bageriets dörr.
- [x] 72. Låt bageriet skicka en tårtkartong till ett kalas. Mottagaren ska öppna kartongen vid leverans.
- [x] 73. Lägg till ett cykelbud som ber spelaren hämta en förväxlad leverans hos rätt butik.
- [x] 74. Låt spelaren välja en avslutad fraktkörning i telefonen och läsa leveranskvittot igen.
- [x] 75. Gör ett tvåstoppsuppdrag med olika last till varje mottagare. Den andra lasten ska ligga kvar vid första stoppet.
- [x] 76. Låt lastens tyngdpunkt ändras när en tung låda lossas från ena sidan. Provkör samma kurva före och efter.
- [x] 77. Låt spelaren köra tomma glasslådor från kiosken tillbaka till glassbilens depå.
- [x] 78. Ge pizzerians disk en beställningslapp med bilder av ingredienser som spelaren kan matcha. Fem illustrerade lappar visas både vid disken och i köpmenyn. Alla fem matchningar samt ett vanligt köp kontrollerades i Godot.
- [x] 79. Låt godisbutikens kund välja en påse med två sorter och visa båda sorterna när påsen lämnas över. Båda sorterna syns på påsen vid kassan. Dubbelt val av samma sort, för få mynt och lyckat köp kontrollerades i Godot.
- [x] 80. Lägg till en borttappad samlarfigur som kan återlämnas i klädbutiken mot ett tack i en pratbubbla.

## Trafik, fordon och resor

- [x] 81. En sittande resenär sträcker sig efter stoppknappen inför avstigningen. Skylten ”Stannar” tänds fram i bussen när handen når knappen och släcks vid avstigning. Förloppet provades på linje 74 i Godot.
- [x] 82. Visa nästa hållplats inne i bussen när linje 74 lämnar en hållplats.
- [x] 83. Mittvagnen har en blåmarkerad barnvagnsplats mitt emot dörren. Spelets barnvagn ryms på ytan. Fri bredd och höjd från perrongen genom den öppna dörren till platsen kontrollerades mot vagnens geometri i Godot.
- [x] 84. Vid främsta dörren väntar en resenär åt sidan tills den avstigande har lämnat dörröppningen. Bytet provades på samtliga hållplatser och vid återkomst till den första.
- [x] 85. Tre sekunder före Lottens avgång tänds en grön lampa ovanför påstigningsskylten och två toner hörs en gång vid det aktuella färjeläget. Båda avgångarna verifieras i tests/ferry_passenger.gd.
- [x] 86. En orangevit vindstrut på kajen följer samma vindriktning som regnet och snön. Riktningen kontrollerades under 40 simulerade sekunder och modellen granskades i spelet.
- [x] 87. Båda cyklisternas trampor roterar med färdsträckan. Knäna böjs och skorna följer varsin pedal ett helt varv. Kontakten med tramporna kontrollerades i 100 steg per cyklist i Godot.
- [x] 88. Shoppingmopedens vindrutetorkare följer det välvda glaset vid nederbörd och återgår till viloläget när det blir torrt. Kontrollerat i 120 steg över ett helt svep och med en närbild i spelet.
- [x] 89. Låt spelaren spola av leran på ett fordon vid macken och se den rena lacken växa fram.
- [x] 90. Låt ett trafikfordon lämna lucka åt en buss som blinkar ut från hållplatsen. Prova även med kö bakom bussen.

## Tillgänglighet och speltest

- [x] 91. Under Körning kan spelaren välja gatunamn vid nästa svängpil. Kontrollerat för svängen från Depågatan till Stationsallén och efter omstart.
- [x] 92. Visa en bild av rätt dörr när spelaren står mellan två möjliga butiksentréer.
- [x] 93. Visa stopp i förarhjälpen. Fordonssignalerna har tre runda linser i fast ordning: rött för stopp, orange för sakta in och grönt för kör.
- [x] 94. Låt spelaren provlyssna på en kort replik direkt när talvolymen ändras i inställningarna.
- [x] 95. En radiobild på knappen ”Slå på radion” visar var radion startas från förarplatsen. Kontrollerat med en renderad svensk knapp och med radiotestet som startar uppspelningen genom knappen.
- [x] 96. Prova hela vägen från startmenyn till ett köp och tillbaka med enbart tangentbord. Rätta de fokussteg som fastnar. Start, urstigning, Tab och Skift+Tab runt pizzamenyn samt köp med Enter har verifierats i Godot. Med simulerade WASD-tryckningar gick spelaren från startbilen genom pizzerians dörr, köpte pizza med 100 testmynt och gick tillbaka och steg in med F.
- [x] 97. Kontrollera att alla sju språk ryms på leveranskvittot i liten fönsterstorlek och med stor text.
- [x] 98. Låt pausmenyn visa det senaste uppdragssteget med samma bild som i telefonen.
- [x] 99. Mät bildtider på kajen medan färjan passerar och tre personer spelar boule. Jämför dag och natt från samma plats. Godot 4.7 dev5, OpenGL Compatibility med llvmpipe, 800 × 600, kamera (98, 3, 83) riktad mot (91, 1, 60). Efter fyra uppvärmningsbilder mättes 30 bildintervall per läge under den första spelarens kast medan Lotten gick från södra kajen. Dag: median 5,00 s, 95:e percentil 5,27 s. Natt: 4,85 s respektive 5,16 s. Avser mjukvarurendering.
  - På AMD Radeon Graphics (Renoir) med Vulkan Mobile, 1920 × 1080 och V-sync mättes 105 verkliga bildintervall per ljusläge från samma kamera. Simuleringen stegade 0,2 sekunder per steg för att alla tre spelarna skulle hinna kasta under färjans överfart. Dag: median 54,5 ms, 95:e percentil 64,2 ms. Natt: median 60,2 ms, 95:e percentil 67,1 ms.
- [ ] 100. Spela igenom en leverans från början till slut med musik och trafik igång. Anteckna exakt var en replik blir svår att höra och justera mixen där. Däckskrik, sopbilens kärllyft och färjans ombordstigningssignal går nu genom talstyrd dämpning. Verifierat med testsignal i Godot. Flakbilen har provkörts från torget till bageriet med svensk radio och tio trafikfordon. Lastning, väntan vid rödljus och mottagningskvitto fungerade. Vid torget låg radions toppnivå minst 16 dB under talets vid de uppmätta talproven under vägbeskrivningen. Vid en ny inspelning låg radions topp över talets under ett kort parti ungefär en sekund in i vägbeskrivningen. Radion hålls nu nere genom hela telefonrepliken med upp till 8 dB extra dämpning. En ny provkörning gav mottagningskvitto med den justerade mixen. En lyssningsbedömning återstår.
