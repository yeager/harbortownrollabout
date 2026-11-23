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
- [ ] 14. Förvarna med två symboler om nästa vägval vid komplicerade korsningar.
- [ ] 15. Översiktskarta med klickbara landmärken och vägledning under friåkning.
- [ ] 16. Mjuka kollisioner där båda fordonens massa och rörelseriktning påverkar utfallet.
- [ ] 17. Tydlig tröskel och markering vid den användbara spårvagnsdörren.
- [ ] 18. Kontrollera och förbättra traktorns sikt över huv och framhjul för båda förarna.
- [ ] 19. Valbar arbetskamera där skoptänderna och marken syns samtidigt.
- [ ] 20. Användbara förarvyer i buss och sopbil med sikt mot hållplats respektive kärl.

## Uppdrag med synliga resultat

- [ ] 21. Grävmaskinen kan ta sand ur en hög och tippa den i en grop eller på ett flak.
- [ ] 22. Ploga vägen till skolan och visa den öppnade passagen.
- [ ] 23. Klipp en avgränsad picknickäng och visa när arbetet är färdigt.
- [ ] 24. Sorteringsrunda med kärl märkta med både bild och färg.
- [ ] 25. Visa hur verkstaden lagar den bärgade bilen.
- [ ] 26. Barnvänligt brandbilsuppdrag med slang och vatten.
- [ ] 27. Leverera en synlig matkasse i shoppingmopedens korg.
- [ ] 28. Matcha kundens bildbeställning mot glassbilens meny.
- [ ] 29. Valbara ledtrådar med ljud eller föremål i katt- och skouppdragen.
- [ ] 30. Varsitt uppdrag för schäfern och den tama komodovaranen.

## Modeller, människor och stadsliv

- [ ] 31. Betygsätt modeller mot jämförbara bilder av silhuett, proportioner, material, interiör och funktion.
- [ ] 32. Granska Axel och Alma från sidan under en hel gångcykel och rätta anatomiska avvikelser.
- [ ] 33. Kontrollera och förbättra handgrepp om ratt, styre, hundkoppel och kasse.
- [ ] 34. Animera shoppingmopedens sidoinsteg, kroppsvridning och fötter in under styret.
- [ ] 35. Låt hundkopplet slacka och sträckas gradvis när avståndet ändras.
- [ ] 36. Ge komodovaranen låg gång, växelvisa steg och följande svans i svängar.
- [ ] 37. Visa bussens passagerare och förändringen i kupén vid hållplatserna.
- [ ] 38. Lägg till en kioskförsäljare som räcker fram den beställda rätten.
- [ ] 39. Låt spelaren bära, använda eller ställa fram varor från klädbutiken.
- [ ] 40. Ge kvarteren egna landmärken som är lätta att känna igen.

## Radio, sparande och utgåvor

- [ ] 41. Slutför 20 svenska och 20 engelska radioinspelningar. 12 svenska och 8 engelska filer finns. Suno angav kvotförnyelse 22 december 2026.
- [ ] 42. Lägg till lokala stationsrop och musik för spanska, tyska, franska, norska och finska.
- [ ] 43. Visa en tydlig låtbild och titel när radion byter låt.
- [ ] 44. Visa påskägg, uppdragsminnen och inköp som bilder i en samling.
- [ ] 45. Erbjud gemensamma eller separata spelarprofiler, plånböcker och samlingar.
- [ ] 46. Visa med bilder vad som gav poäng och mynt efter uppdraget.
- [ ] 47. Bygg och provstarta Linux-paket på en äldre stödd distribution än dagens glibc 2.44-krav.
- [ ] 48. Publicera provstartade Windows- och Mac-paket med direkta nedladdningslänkar. Senaste byggjobbet stoppades av GitHubs betalnings- eller utgiftsgräns.
- [ ] 49. Mät bildtider under en reproducerbar färd förbi macken med kvällsljus, trafik och regn.
- [ ] 50. Speltesta med barn utan muntlig vägledning. Observera val av favoritbil, korvköp och återgång till bilen. Kräver en medverkande familj.
