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
- [ ] 10. Tangentbindningar som spelaren kan ändra. Radion och nästa låt har valbara tangenter under Ljud. Gång och körning kan växlas mellan WASD och 8, 4, 5, 6 med uppdaterade hjälprader. Sifferstyrningen har provkörts i Godot med samtliga 26 vägfordon, grävmaskinen, motorbåten och spårvagnen. Återgång till WASD verifierad. För återställning kan spelaren välja R eller Backspace. Valet och telefonens hjälprad verifierades efter omstart på övningsbanan. Hopp till fots kan bindas till E eller 0. Hopphöjd och svensk hjälprad verifierades med 0 efter omstart. Kamerahöjden till fots kan styras med 9 och 3. Båda riktningarna och svensk hjälprad verifierades efter omstart. Telefonen kan öppnas och stängas med T eller F2. F2 och svensk knapptext har provats före och efter omstart. Avsluta kan bindas till F8 eller F10. F8 öppnade bekräftelsen efter omladdning med den sparade inställningen. F3 kan aktiveras som extra tangent för att kliva i och ur fordon. Båda riktningarna har provats efter omladdning. Övriga spelkontroller återstår.

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
- [x] 23. Klipp en avgränsad picknickäng och visa när arbetet är färdigt.
- [x] 24. Sorteringsrunda med kärl märkta med både bild och färg.
- [x] 25. Visa hur verkstaden lagar den bärgade bilen.
- [x] 26. Barnvänligt brandbilsuppdrag med slang och vatten.
- [x] 27. Leverera en synlig matkasse i shoppingmopedens korg.
- [x] 28. Matcha kundens bildbeställning mot glassbilens meny.
- [x] 29. Valbara ledtrådar med ljud eller föremål i katt- och skouppdragen.
- [x] 30. Varsitt uppdrag för schäfern och den tama komodovaranen.

## Modeller, människor och stadsliv

- [ ] 31. Betygsätt modeller mot jämförbara bilder av silhuett, proportioner, material, interiör och funktion.
  - Midsommarstång, jämförd med de tre inskickade fotografierna och en Godot-rendering från marknivå. Silhuett 96, proportioner 94, material/färg 90, detaljer 93, årstidsfunktion 100. Interiör ej tillämplig. Medel 95/100 efter att tvärslån och girlanderna fått nedhängande kvistar. Närbilden visar nu sågtandade blad och vikt mittnerv. Kransens kvistar och blommor är fortfarande mer regelbundna än på fotografiet.
- [x] 32. Granska Axel och Alma från sidan under en hel gångcykel och rätta anatomiska avvikelser. Sidovyer av båda figurerna vid åtta jämnt fördelade faser finns i [gångstudien](player-walk-side.png). Godots gångtest verifierar hälisättning, tåfrånskjut och kontakter under gång och löpning. Armarnas pendelplan följer nu bröstkorgens vridning genom hela steget.
- [x] 33. Kontrollera och förbättra handgrepp om ratt, styre, hundkoppel och kasse.
- [x] 34. Animera shoppingmopedens sidoinsteg, kroppsvridning och fötter in under styret.
- [x] 35. Låt hundkopplet slacka och sträckas gradvis när avståndet ändras.
- [x] 36. Ge komodovaranen låg gång, växelvisa steg och följande svans i svängar.
- [x] 37. Visa bussens passagerare och förändringen i kupén vid hållplatserna.
- [x] 38. Lägg till en kioskförsäljare som räcker fram den beställda rätten.
- [x] 39. Låt spelaren bära, använda eller ställa fram varor från klädbutiken.
- [ ] 40. Ge kvarteren egna landmärken som är lätta att känna igen. Verkstadskvarteret har fått en avsmalnande, rödvit fabriksskorsten som når 13 meter över marken. Sikt i mörker har kontrollerats med renderade vyer från vägen väster om verkstaden och från bron österut. Sjöstadsskolan har fått ett fasadur över entrén som följer spelets dygn. Synligheten har kontrollerats från busslinje 74.

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
- [ ] 48. Publicera provstartade Windows- och Mac-paket med direkta nedladdningslänkar. Windows x64, Mac Intel och Mac Apple Silicon har publicerats som ZIP-filer med direktlänkar i README. SHA-256 verifierad för varje arkiv. Provstart i Windows och macOS återstår.
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
- [ ] 58. Låt en sidolucka rullas upp när slangen hämtas och stängas när utrustningen lagts tillbaka.
- [ ] 59. Gör en körbar port på brandstationen som öppnas för brandbilen och väntar tills hela bilen passerat.
- [ ] 60. Ordna en markerad uppställningsplats där brandbilen kan backa in efter avslutat uppdrag.

## Boule och strandpromenad

- [ ] 61. Låt spelaren tacka ja till en omgång boule och ta plats i kastringen.
- [ ] 62. Låt spelaren sikta på lillen och välja mellan ett kort, ett mellanlångt och ett långt kast med bilder.
- [ ] 63. Låt ett kastat klot kunna knuffa ett annat klot. Kontrollera var båda stannar efter träffen.
- [ ] 64. Visa vilket klot som ligger närmast lillen efter omgången, även när två ligger nästan lika nära.
- [ ] 65. Animera hur boulespelarna hämtar sina klot innan nästa omgång börjar.
- [ ] 66. Lägg till ett distinkt metalliskt klick när två bouleklot träffar varandra.
- [ ] 67. Ge boulebanan en sittbänk där spelaren kan sätta sig, följa omgången och resa sig igen.
- [ ] 68. Sätt upp vägvisare från färjelägena till boulebanan med en bild av ett klot och lillen.
- [ ] 69. Gör ett uppdrag där en granne behöver hjälp att hitta sin termos efter boulematchen.
- [ ] 70. Låt spelaren lämna tillbaka ett upphittat paraply vid färjeläget och se ägaren fälla upp det när det regnar.

## Leveranser och stadens butiker

- [ ] 71. Ge bageriet en morgonleverans av mjöl. Visa säckarna först på flaket och sedan vid bageriets dörr.
- [ ] 72. Låt bageriet skicka en tårtkartong till ett kalas. Mottagaren ska öppna kartongen vid leverans.
- [ ] 73. Lägg till ett cykelbud som ber spelaren hämta en förväxlad leverans hos rätt butik.
- [x] 74. Låt spelaren välja en avslutad fraktkörning i telefonen och läsa leveranskvittot igen.
- [x] 75. Gör ett tvåstoppsuppdrag med olika last till varje mottagare. Den andra lasten ska ligga kvar vid första stoppet.
- [x] 76. Låt lastens tyngdpunkt ändras när en tung låda lossas från ena sidan. Provkör samma kurva före och efter.
- [ ] 77. Låt spelaren köra tomma glasslådor från kiosken tillbaka till glassbilens depå.
- [ ] 78. Ge pizzerians disk en beställningslapp med bilder av ingredienser som spelaren kan matcha.
- [ ] 79. Låt godisbutikens kund välja en påse med två sorter och visa båda sorterna när påsen lämnas över.
- [ ] 80. Lägg till en borttappad samlarfigur som kan återlämnas i klädbutiken mot ett tack i en pratbubbla.

## Trafik, fordon och resor

- [ ] 81. Låt en bussresenär trycka på stoppknappen och tänd en synlig stoppskylt fram i bussen.
- [x] 82. Visa nästa hållplats inne i bussen när linje 74 lämnar en hållplats.
- [ ] 83. Markera platsen för barnvagnar inne i Tvärbanan och prova att en barnvagn kan komma dit från perrongen.
- [ ] 84. Låt fotgängare invänta avstigande vid spårvagnsdörren innan de själva går ombord.
- [ ] 85. Ge färjan en ombordstigningssignal som både syns och hörs innan avgång.
- [ ] 86. Sätt ut en vindstrut på kajen och låt den vrida sig när vindriktningen ändras.
- [ ] 87. Gör cykelns trampor rörliga och låt fötterna följa dem ett helt varv vid trampning.
- [x] 88. Shoppingmopedens vindrutetorkare följer det välvda glaset vid nederbörd och återgår till viloläget när det blir torrt. Kontrollerat i 120 steg över ett helt svep och med en närbild i spelet.
- [ ] 89. Låt spelaren spola av leran på ett fordon vid macken och se den rena lacken växa fram.
- [ ] 90. Låt ett trafikfordon lämna lucka åt en buss som blinkar ut från hållplatsen. Prova även med kö bakom bussen.

## Tillgänglighet och speltest

- [ ] 91. Lägg till ett val att visa uppdragspilen med både riktning och gatunamn inför nästa sväng.
- [ ] 92. Visa en bild av rätt dörr när spelaren står mellan två möjliga butiksentréer.
- [x] 93. Visa stopp i förarhjälpen. Fordonssignalerna har tre runda linser i fast ordning: rött för stopp, orange för sakta in och grönt för kör.
- [x] 94. Låt spelaren provlyssna på en kort replik direkt när talvolymen ändras i inställningarna.
- [x] 95. En radiobild på knappen ”Slå på radion” visar var radion startas från förarplatsen. Kontrollerat med en renderad svensk knapp och med radiotestet som startar uppspelningen genom knappen.
- [ ] 96. Prova hela vägen från startmenyn till ett köp och tillbaka med enbart tangentbord. Rätta de fokussteg som fastnar.
- [x] 97. Kontrollera att alla sju språk ryms på leveranskvittot i liten fönsterstorlek och med stor text.
- [x] 98. Låt pausmenyn visa det senaste uppdragssteget med samma bild som i telefonen.
- [ ] 99. Mät bildtider på kajen medan färjan passerar och tre personer spelar boule. Jämför dag och natt från samma plats.
- [ ] 100. Spela igenom en leverans från början till slut med musik och trafik igång. Anteckna exakt var en replik blir svår att höra och justera mixen där.
