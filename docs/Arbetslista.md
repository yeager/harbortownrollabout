# Arbetslista för Full rulle i Sjöstaden

De 50 förbättringarna från genomgången. En tom ruta är öppen. En punkt bockas av när beteendet är verifierat. Delresultat och beroenden står vid respektive punkt.

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
- [ ] 10. Tangentbindningar som spelaren kan ändra. Radion och nästa låt har valbara tangenter under Ljud. Gång och körning kan växlas mellan WASD och 8, 4, 5, 6 med uppdaterade hjälprader. Sifferstyrningen har provkörts i Godot med samtliga 26 vägfordon, grävmaskinen, motorbåten och spårvagnen. Återgång till WASD verifierad. För återställning kan spelaren välja R eller Backspace. Valet och telefonens hjälprad verifierades efter omstart på övningsbanan. Hopp till fots kan bindas till E eller 0. Hopphöjd och svensk hjälprad verifierades med 0 efter omstart. Kamerahöjden till fots kan styras med 9 och 3. Båda riktningarna och svensk hjälprad verifierades efter omstart. Övriga spelkontroller återstår.

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
- [ ] 32. Granska Axel och Alma från sidan under en hel gångcykel och rätta anatomiska avvikelser.
- [x] 33. Kontrollera och förbättra handgrepp om ratt, styre, hundkoppel och kasse.
- [x] 34. Animera shoppingmopedens sidoinsteg, kroppsvridning och fötter in under styret.
- [x] 35. Låt hundkopplet slacka och sträckas gradvis när avståndet ändras.
- [x] 36. Ge komodovaranen låg gång, växelvisa steg och följande svans i svängar.
- [x] 37. Visa bussens passagerare och förändringen i kupén vid hållplatserna.
- [x] 38. Lägg till en kioskförsäljare som räcker fram den beställda rätten.
- [x] 39. Låt spelaren bära, använda eller ställa fram varor från klädbutiken.
- [ ] 40. Ge kvarteren egna landmärken som är lätta att känna igen. Verkstadskvarteret har fått en avsmalnande, rödvit fabriksskorsten som når 13 meter över marken. Sikt i mörker har kontrollerats med renderade vyer från vägen väster om verkstaden och från bron österut.

## Radio, sparande och utgåvor

- [ ] 41. Slutför 20 svenska och 20 engelska radioinspelningar. 12 svenska och 8 engelska filer finns. Suno angav kvotförnyelse 22 december 2026.
- [ ] 42. Lägg till lokala stationsrop och musik för spanska, tyska, franska, norska och finska.
- [x] 43. Visa en tydlig låtbild och titel när radion byter låt.
- [ ] 44. Visa påskägg, uppdragsminnen och inköp som bilder i en samling. Alla butiksvaror har en produktbild vid köp och i köplistan. Telefonen visar en stjärnrad med en fast plats för var och en av stadens åtta gömda stjärnor.
- [ ] 45. Erbjud gemensamma eller separata spelarprofiler, plånböcker och samlingar.
- [x] 46. Visa med bilder vad som gav poäng och mynt efter uppdraget.
- [ ] 47. Bygg och provstarta Linux-paket på en äldre stödd distribution än dagens glibc 2.44-krav.
- [ ] 48. Publicera provstartade Windows- och Mac-paket med direkta nedladdningslänkar. Senaste byggjobbet stoppades av GitHubs betalnings- eller utgiftsgräns.
- [x] 49. Mät bildtider under en reproducerbar färd förbi macken med kvällsljus, trafik och regn. Mätt med `tools/station_frame_times.gd` i Godot 4.7 dev, Compatibility, Radeon Renoir, 1920 × 1080. Efter uppvärmning mättes 240 bilder över 48 meter med tio trafikfordon. Median 40,14 ms, 95:e percentilen 51,09 ms och längst 76,77 ms. Den körningen avslutades normalt. Vissa upprepningar kraschade, även vid avslut.
- [ ] 50. Speltesta med barn utan muntlig vägledning. Observera val av favoritbil, korvköp och återgång till bilen. Kräver en medverkande familj.
