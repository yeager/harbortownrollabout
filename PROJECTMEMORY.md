# Harbor Town Rollabout project notes

## Playable in the main scene

- The 3D game runs on Godot 4.7 dev5 and supports English, Swedish, German, Spanish, French, Finnish and Norwegian Bokmål. Players choose Axel or Alma from the menu. The game saves their character choice and earned coins locally.
- Drive an ambulance, police car, fire truck, black SUV or taxi. Players can switch vehicles on foot and use mouse pedals, a steering indicator, horns and sirens. Hard braking leaves skid marks. The SUV also has a driver’s-eye view.
- The road network takes inspiration from Sjöstaden, with canals, bridges, small boats, waterfront houses, depot parking, a library, bakery, clinic and fire station.
- Traffic includes cyclists, emergency vehicles and slow A-tractors. Pedestrians greet the player. The central junction has traffic signals, and streetlights follow the day/night cycle. Weather and seasons support manual and automatic settings.
- Press T to open or close the phone. Players can choose F2 in Settings. The phone shows assignments and receipts in the selected language and keeps the 32 most recent messages.
- Three mission steps, roadside arrows and recurring taxi runs. 10 coins per rescue step and 15 per completed taxi ride.
- Players can ride or drive the Tvärbanan tram on a four-stop loop between the traffic lanes in the western district. The door sign reads “Vi åker inte till Ekerö” (“We don’t go to Ekerö”).
- Drive a motorboat in the southern basin, ride the scheduled Lotten ferry or watch the police helicopter on patrol.

- Four shops on the south side of Stationsallén have entrances players can walk through. Spend saved coins on cinnamon buns, berry cordial, ice cream, hot dogs, pizza and candy.

- The red-and-yellow flatbed tow truck has a modeled winch. Pick up a smoking car or one missing a wheel and carry it to the workshop for 20 coins.

- The hospital east of the north bridge has a covered ambulance intake that can be reached on foot or by vehicle. The interior ward is closed. The ambulance assignment picks up a patient at the square, drops them off in the intake, then continues to the marina with first-aid supplies. The patient handoff adds a receipt to the phone.
- A yellow and teal medical helicopter with skids and an enclosed tail rotor approaches the hospital, lands on its lit helipad, waits on the roof and takes off again.
- Drivers hold before a junction when its exit is blocked. Responding ambulances, police cars and fire engines can proceed on red when the crossing is clear. Automated road traffic pulls aside where there is sufficient space or waits before a conflicting crossing.

- A neighbor pushing a stroller and an older pedestrian using a rollator walk along the main street at different speeds. Both accessories have editable Blender models.

- Two low green cruisers with white roofs weave gently within their lanes and stop behind traffic.

- A wooden pier with bollards and ropes connects Lotten’s two landings. Four steps link each end to the western quay.

- The flatbed collects three flour sacks at the square in the morning. The sacks ride visibly on the bed and add 75 kg to the payload. Stop by the bakery to unload the sacks and receive a delivery receipt on the phone.

## Outstanding requests

- Refine vehicle shapes, especially the BMW front, the fire truck, the police car, the Tvärbanan and the sitting driver. Improve water and window reflections, architecture and boardwalk based on image references.
- Review any remaining unsignalized crossings and playtest routes, dialogue, readability, sound levels and frame rate throughout town.
- Verify the Blender MCP connection. Blender 5.3.0 opens the bus source file locally and reports 285 mesh objects. The MCP extension loads, but its bridge refuses to start while Blender’s online access is disabled.

## Sources and verification

- The pump price test verifies that all eight main pump displays collectively show petrol 95, petrol 98 and diesel. Each of the 24 nozzle prices matches the corresponding tower price in the currency and number format of all seven languages.

- The bumper contact test checks that all 26 selectable road vehicles have an assigned operating mass, that 75 kg of additional load reduces the drive response for each, and that lighter and heavier vehicles exchange speed differently in contact. The patrol helicopter has a 3,200 kg gameplay mass. Its bank is based on the lateral force needed to follow the patrol curve. Sampling 24 points in Godot gave 2.85° to 5.66°.

- After the route 74 glazing and canal checkpoint changes, Godot 4.7 dev5 verified six bus stops, all 26 road vehicles and three special gallery activities, separate Axel and Alma save profiles, and all 24 resumed mission steps across eight vehicles.

- The water-exit and excavator tests verify recovery onto land when a saved bus or excavator pose is inside the canal. The water-exit test also reloads the bus on both bridge decks and verifies that each valid position remains intact. The city perimeter test treats the motorboat parking bay as a parking area and verifies that its east edge joins the carriageway. It also verifies 32 junctions, 49 street segments and all four perimeter walls.

- The Godot 4.7 dev5 weather transition test verifies that switching from winter to summer removes the tractor plough, tyre tracks, footprints and visible snow. Fresh winter snowfall restores the plough and snow footsteps and covers the previously cleared strip. A forward drive from the tractor selected in the gallery clears snow in the path of the cutting edge while leaving snow outside the blade.

- On a 120-frame rainy station approach at 960 × 563, disabling streetlamp shadows reduced the median frame time to 40.20 ms versus 47.27 and 45.65 ms in the surrounding runs with shadows. Starting shadow fade at 14 m instead of 24 m measured 44.04 ms versus 46.26 and 44.49 ms. That smaller difference was within run-to-run variation, so the game retains the 24 m shadow fade.

- In a fixed 1920 × 1080 daytime view at the western junction (x = −330), Godot 4.7 dev5 Compatibility on Radeon measured a 49.15 ms median frame, with 49.23 ms on repeat. Disabling sun shadows alone measured 47.95 ms, disabling the main game update measured 40.65 ms, and disabling 3D measured 16.67 ms. In separate 45-frame runs, hiding street trees changed the median from 48.81 to 48.52 ms. Hiding the repeated western buildings changed it from 48.58 to 47.92 ms. Neither isolated test explains the slow view. Reducing the gameplay camera far plane to 220 m lowered the western view from 48.48 to 27.81 ms median, with 49.20 ms on a repeat at 4,000 m. The bridge and western intersection were reviewed at both distances. Buildings beyond 220 m disappear from the far horizon.

- Godot 4.7 dev5 verified the central pedestrian crossings and all six tram junctions. The longest sampled red was 9.0 s at the central road junction and 6.9 s at tram junctions. The driving school course also passed its acceleration, braking, reverse, recovery and boarding test.

- Godot 4.7 dev5 on Linux with the Compatibility renderer and Mesa reported two GLES texture allocations at exit (87,376 and 65,532 bytes). The normal quit confirmation reproduced this from the menu and during play. A standalone SceneTree with only a current Camera3D, three rendered frames and then quit reproduced both allocations without any game scene or assets. The same SceneTree without the camera exited cleanly. Retest that minimal case when changing engine versions.

README.md contains the English playing instructions. Blender sources are in `source_blender/` and build scripts in `tools/`. Local reference photos retain their original filenames under `.local-memory/references/`. The tow truck reference filename starts with `codex-clipboard-56557bc1`. These photos are excluded from Git.

The project was originally published in the private yeager/axels-emergency-vehicles repository. Run Gitleaks before pushing. Check the current scenes, source and running game before updating an entry.

- The medic hands the first-aid bag to the player during the rescue mission. The bag stays on the quay after delivery.

- Both crossings on the central side street have pedestrian signals. Pedestrians wait at the curb on red and finish crossing if the light changes.

- In Tvärbanan’s driver and passenger mode, HUD shows the next stop, wagon speed and countdown at the stop in selected language.

- The front wagon double door opens to the short platform at each stop. The door blades slide again before departure in both passenger and driver mode.

- The train driver can call a double connotation with the H or screen button. The listener follows the front wagon in both trams.

- In the BMW’s driver’s view, you can look at the sides and up/down by dragging the middle button. The driver’s view is centered when you choose it again.

- The BMW's two front windshield wipers follow the precipitation. They sweep faster at stronger precipitation and finish the swipe in parked mode when it clarifies.

- The driver’s view was rendered in Godot with parked and folded dryers. The swipe was increased to about 73 degrees after the image control.

- The four roof modules of the player ambulance now light up nearby surfaces. The Godot test and image from the companion camera confirms the lights in fixed mode and the test controls both blink phases.

- The three emergency vehicles in traffic have blue light spills and alternating blue light groups. Traffic setting for solid or suspended blue light also controls the light spill.

- The sirenton of the traffic follows both the movement of the sound source and the listener. The Godot test verified the pitch of the tone as the boat and tram approach, the sinking as the boat backs off and the keynote when both stand still.

- The phone specifies location and errors during salvation, confirms the loading and displays the reward for the workshop journey. The loading and payment are also visible on the screen.

- When returning from manual to automatic weather, the forecast’s five-minute time begins. Automatic seasons start from the season chosen and retain it for half an hour’s playing time. Precipitation that fits the season continues at the prey.

- Hard braking in snow leaves wider grey tracks and subdued tire sound. Slask provides darker tracks than dry snow. Each track segment retains the color from the road when it was created.

- In the stores, “Your purchase” shows how many copies of each item have been purchased. The list is shared between the stores and reads from the locally saved purchases.

- The store menu has dark background and scrolling for longer shopping lists. In a game window of 800 × 480, the location of both kiosk buttons and a purchase of all six items were verified in the list.

- From the depot leads a signed walkway across the Stations Allén to the cafe. The sidewalk continues along the kioskens, pizzerians and candy shop entrances.

- The transition point between the depot and the shops at Stationsallén has walking signals, traffic lights and stop lines in both directions. The brake help of the car follows the signal.

- The brake aid takes into account the movement under the next frame and lights the brake light when it limits the speed. When testing at Stationsallén, the car braked from 8 m/s to stagnant before the line and continued with retained gas at green.

- When the car stops at the signal stop line, “Wait for green light.” The lyrics remain if the player releases the gas and disappears when the signal gives free passage.

- The Lottens salon window shines warmly when the city is darkening. The night mode was reviewed in a rendered Godot image from the dock and the current situation was checked without the windowlight.

- The canal water reflects Lotten's illuminated side window in dusk and night. The waves break up the shape from the location of the camera and the ferry. The night view from the dock is visually controlled in Godot.

- The engine boat’s wake is based on the stern and changes the length and lightness with the speed. The direction changes when backing. Forward driving was checked in the rendered Godot view and the parameters were tested at stops, backings and advances.

- The motorboat slows softly towards the frontier. With gas and rods, the player can turn back even from stagnant. The entrance and reboot at the northern line is tested in Godot.

- The outboard motorboat has a steering bracket in the Blender model. Motor housing, gear houses and propeller hubs swing together in Godot and are centered when the control is released.

- The engine boat now has a seated driver behind the control pulp following the Axel or Alma player selection. Alma was controlled in the rendered Godot view during boating.

- The motorboat’s red bathing lanes and green steering board lanes follow the clock light. Both sides were checked in rendered nightshots and the extinguishing was verified at present.

- The boat driver has an orange floating vest with backpiece, two front pieces, reflex details and buckle. The West follows the size of the figure and was controlled from both sides of Godot.

- The start and pause menu shows instructions for selected boat ride or tram role. The car selector and the car’s sound sample are shown only in the road activities. The shifts of activity and the pause button of the boat trip are tested in Godot.

- Reading greetings follows the main volume of the game. When sounds are stopped, ongoing speech and new greetings are displayed as text: “Hello!” was verified in Swedish, soundless mode in Godot.

- Tram driver mode shows gas and brakes down to the right. Mouse pedals also work when the player switches from walking in the pause menu. Test in Godot confirms acceleration with the left button and brake priority when both are kept down.

- The front tram cab has a separate Blender model with rounded blue nose, sloping windscreen, headlights and destination sign. The front was reviewed in a rendered three-quart view at the stop.

- Overhead wires and poles follow the tram loop. The middle car carries a pantograph. A Godot roof inspection and driving test covered four stops with opening and closing doors.

- Tram stops have double-sided name signs under the roof, bench and marked platform quantity.

- The tram status display shows distance in meters along the rails to the next stop along with name and speed, in Swedish and English.

- At the salvage on the eastern dock, the unloaded wheel is next to the car until it is picked up. All four mission steps were tested in Godot.

- Parked assignment vehicles cannot trigger pick-up while the player rides a boat or cross-course. Wearing tested at the same goal in five modes.

- At rescue goals, manual driving mode first shows that the player should stop and then which button helps. Tested that space speeds do not cross-stop the car and that assistance after stopping performs the mission stage.

- The task phone counter follows the four saved messages and zeroes when the inbox becomes visible after pause. Tested in Godot.

- The task menu shows Tax drives or Wearing missions when the respective vehicles are selected. The Swedish texts were tested by switching between taxis, salvage cars and ambulance.

- The start menu describes the first trip for the taxi and salvage car. The Swedish descriptions were checked at vehicle change in Godot.

- Left taxi passengers are shown on the sidewalk at the destination until the next pick-up. Three full taxi trips were tested with the correct drop-off point and 15 coins per trip.

- The player’s car and the AI traffic take into account visible taxi passengers and waiting healthcare providers. The Godot test showed that a car stopped for a passenger in the lane and drove on when the road was free.

- Traffic counts the length and width of the crashed car when braking. In a lane test in Godot, the car stopped behind the obstacle and continued as the lane became free.

- A red orange warning triangle with a self-evident reflex frame stands at both breaks and is removed when the car is loaded. Visibility was controlled through all four salvation steps.

- The workshop’s facade against the salvage target has two sectional doors with windows and a sign named Sjöstaden’s car repair shop.

- The workshop’s two garage doors have hot-white downward luminaires that follow the twilight. In Godot, the brightness and visibility of both lights were checked at night and day.

- After the drop-off, a car stands outside the workshop gate until the next pick-up. The player’s car and walkway take into account the parked car.

- AI traffic adapts speed and distance to how wet and snow covered the road. The same car was tested on dry, wet and snow-covered roads as well as on a passenger in the lane.

- Mark on both channel beaches as well as the sidewalks at the main streets now follow the same gradual snow cover and wet as the lane. The material values were controlled at four snow levels in Godot.

- The weather also affects the stone layer at the docks and the promenade. Wet granite darkens and becomes blanker, while snow gathers first more clearly in the joints.

- Rain drops create expanding rings in the channel's surface flaxes. The effect follows the floating precipitation and tons down at a distance. Control in Godot included rain, slack, snow and stop.

- Rain and snow directly suppress sunlight and shadow contrast as the cloud cover. Tested at three precipitation levels with a fixed day mode.

- The reflection map of Heaven suppresses strong highlights and gets a cooler tone in the mulet weather. Godot was started with the changed skieshader without compilation errors.

- Saved manual weather already applies when a new game session is opened, including road law and precipitation. Tested with saved snow weather followed by gradually thawings after switching to sun.

- When the snow melts, the ground becomes wet of meltwater. In Godot, the transition was snow-sol until the snow was gone and the roadway then dried.

- The rainfall particles are hidden in the shop view and are visible again outside. Entrance and exit were tested at all four stores.

- Cafe Bullen has a sheet of six modeled cinnamon noises on the counter. Each noise has a cinnamon spiral that follows the vaulted surface.

- Pizzerian shows a margherita on the wooden board at the counter, with creamed edge, tomato sauce and mozzarella.

- When the money is not enough, the store shows the amount that is missing and how the player earns coins. Swedish announcements and purchases with the exact price were tested in the cafe.

- Upon entering a store, the first item gets the keyboard focus. A purchase of a cinnamon boulder with Enter was verified with Godot’s input system.

- The store menu shows how to choose to be with Tabb and buy with Enter. In the kiosk, a purchase of sausages with bread was tried with these two keys.

- The intermittent final warning of the Kiosktest was identified in Godot’s verbose log as the AudioStreamWAV of the ambulance and its playback. Five repetitions of 250 ms between the released stage and the end of the test process completed the purchase without a resource warning. Normal play closure is not investigated in this test.

- Three separate graphic Godot processes during the X11 received the window manager’s normal closing message while the ambulance sir played. All three ended with code 0 without resource alert in the detailed log.

- The store receipt shows the amount and paid in Swedish and English. The Swedish receipt for a cinnamon boulder was checked against three drawn coins.

- The tow truck’s rear wheel lift has two modeled wheel supports with hinges and capture arms. The Blender source and the game model were updated and imported in Godot.

- Emergency braking aid for persons, in front of traffic and red lights uses the measured length of the car forward and backwards. The tow truck’s new wheel support is included in the rear dimension even when parked.

- Tree collisions use the front bumper's measurements when driving forward and the rear equipment's dimensions when backing. The test with the wearer stopped with less than a centimeter’s release in both directions.

- Parked vehicle collision surfaces are based on the actual outer edges of the model. On foot, the release was tested in front of and behind the wearer in three different directions.

- The depot has a separate paved box for the wearer and a closing line at the taxi site. The Godot test checked that the entire wearer’s footprint is accommodated on the asphalt after the start of the game.

- The door marker shows the name of the vehicle and F to step in. Swedish calling and switching from walk to carrier was verified in Godot.

- In the event of departure, the player ends up on the same door line used when entering. Tested that the wearer requires a stop and that the player can reach the same door again.

- The descent at the stairs of the ferry mode uses the height of the stairs directly. Verified with a parked ambulance at the western dock.

- The unit delivery is set off with location and replacement both on the phone and on the end screen. Three stages were verified with Alma and Swedish texts.

- The end-screen language change was verified by the Swedish-English-Swedish language selection signal in Godot. The delivery receipt was translated directly, the name of Alma was retained and the reward was paid only once.

- A port host in the orange jacket awaits at the marina during the unit delivery and keeps the bag after the handover. This and the receipt were tested through all three mission steps.

- The neighbor in turquoise jacket stands at the first aid target in the square with the hand height and lowers the arm after the aid. Both permits were verified by the rescue mission.
- Assignees can now greet when Axel or Alma arrives on foot. Goodot was checked without graphics.
- The BMW X5 has a seated driver who follows the game selection. Tested with Alma in Godot when switching between the camera and the driver’s view. The placement remains to be reviewed visually.
- The BMW driver’s hands follow the steering wheel. The hand positions of both figures were checked in Godot in neutral mode and in full steering rash in both directions.
- Axel and Alma have curved elbows in the BMW. Both poses were examined in rendered close-ups with the body hidden. The hand positions were also tested with a full rash.
- The driver’s profile and the faces of the pedestrians have modeled nose and ears. Both Axel and Alma were controlled in rendered images through the BMW side surface with the body visible.
- Deserted cars show yellow warning blinkers back and forth. Both pick-up sites, shipping on the flat and three light modes were verified in Godot.
- The tow truck displays separate instructions to stay, load and load off. Swedish texts were tested at all four mission stages with automatic and manual loading.
- Taxin’s stop shows when the passenger is to be picked up or dropped off, with Swedish and English text. Three taxi trips were tested through six stops, with automatic and manual assistance and a total of 45 coins.
- The waiting taxi passengers are facing the stop point of the taxi and holding up their hand. Direction and gesture were tested at the square, at the clinic and at the marina.
- Released passengers are placed at the measured height of the pedestrian surface and turn to the stop point of the taxi. All three leaves were verified in Godot.
- In taxi driving and salvage, the marking will show the way back to the parked mission vehicle on foot. Re-entry and replacement to boat or Tvärbana was verified in Godot.
- On foot, the return marker shows the door that was used when descending. Tested in Godot with blocked right door on taxis and carriers, including re-entry on the left side.
- Traffic begins to slow when the player is entering the lane within 1.4 seconds. Silent and motion away from the lane was compared to motion towards the lane in Godot.
- Cars tilt on a slow A-tractor only if it limits the distance forward. Tests in both directions with a pedestrian between and then five seconds of follow-up drive gave at least 4.3 meters of gap.
- Raggar car and A-tractor have their own synthesized tutors. The ring watch of the cyclists and the connection of the two new sounds to the traffic vehicles were verified in Godot.
- Paus interrupts tutors, tire sounds and read greetings and silences traffic sirens directly. Pause and return with simultaneous vehicle sounds were tested in Godot.
- Paus freezes the remaining reading time for temporary messages. Taxins confirmation was tested with 60 seconds simulated break and resumed countdown.
- The pause menu shows the current mission text from the phone. Six mission steps were verified in Swedish and English, with no double phone messages.
- Improved text contrast on bright buttons at the keyboard focus, mouse pointers and pressure. Rendering at 800 × 500 verified focused continuation button and two visible rows for the salvage mission in Swedish and English.
- The seaside school with plaster façade and copper roofs was modeled in Blender. School taxis pick up and leave students and bus route 502 operates four stops. Both assignments and payouts were tested in Godot.
- The BMW M3 E30, Volvo 240, Saab 96, Tesla Model S and city bus are available in vehicle selection and depot. Own Blender sources, tutors and low-measured electrical sound are included. Vehicle radio with its own instrumental loop starts with J.
- Compatibility, Mobile and Forward+ rendered the bus and school on the computer’s Radeon. play.sh You can start all three and choose AMD FSR 2.2 in Forward+. No measurement of frame rate or verification on other hardware yet.
- Line 502 shows the next stop on the front sign of the bus. Verified over four stops, a new lap and free run.
- All four stop posts show line numbers and stop names on two opposite sign fronts, directed along the respective streets. Checked in Godot.

Settings are available in a separate dialogue with tabs. The renderer is selected under Graphics and activated at the next start. Verified switch from Compatibility to Forward+ with FSR2 on AMD.

The western district connects to the road network in three crossings. The game limit is now 690 × 151 m. Axel and Alma use Blender-modeled faces and jackets. The bench with color samples changes jack paint and brew values have a special replica. Full speed has double top speed for road vehicles, quiet driving retains 30 km/h.
Rended close-up in Compatibility showed a grind under the head. The neck, hair, eyes and mouth were adjusted and controlled in a new game.
Snowmobiles from Blender with bands, skis, suspension and visible drivers. Sample in Godot with gas, brakes and disembarkation. The park bench has four legs. Axel has shaped sleeves, trousers, hands and shoes.
The snowmobile now has its own synthesized motorloop with speed-controlled pitch. Playback and vehicle selection were verified in Godot.
The two skis and rule of the snowmobile now follow the ruling rash. The driver’s hand positions follow the handles. Tested with control in Godot.
The terrain speed of the Scooter follows the snow cover. Try the western field with bare ground, half and full snow cover in both driving modes.
The snowmobile night light is based on the two Blender-modeled lamp glasses. The positions of both light sources were verified in Godot.
The night light was tested in Godot Compatibility on the western main street with the same camera and the lamps on and off respectively. Both candles together illuminate the asphalt in front of the skis.
The scooter driver now sits branch with curved knees. The model has footboards with grip on both sides. Checked from the side of Godot and test drive after reimport.
The main streets and cross streets of the western district have stretched midlines. All 185 markings controlled across the roadway and beyond the crossings of Godot.
The western district has 75 street lamps along the main streets and cross streets. Verified in Godot that everyone is lit at night and extinguished in the day.
The three western main streets have 2.8 meters wide walkway on both sides. Accessibility verified along six strings and across intermediate cross streets.
Five neighbors walk in the western quarter. Verified greeting at meeting and turning on the pavement at the end of the neighborhood in Godot.
The walkways along the western cross streets connect on a level around all ten blocks. Walking height and prosperity checked around every quarter of Godot.
Bus 502 is now picking up at the West Square and leaving at Västerängen. Godot test through all six stop exchanges with destination sign, reward and return to the square.
The passengers at the bus stops also welcome. Size and distance of the group is restored before placement when switching from school taxis to bus. Tested at western pickup and leave.
Night view compared to Compatibility, Mobile and Forward+ on AMD. The color space of the night sky is now converted by Godot, so the volcano modes do not show a light dusk at midnight.
In automatic clock mode, the light direction wanders through the day, with lower and warmer lights at dawn and dusk. Direction, shadow setting and continuity over the circadian screw tested in Godot.
The canal’s water materials spread light in rain and foam, with sharper sunblink on calm water. The ferry’s window mirroring uses the reflected vision line of the wave. Channel View with all three renderers.
Lotten pulls a V-shaped wake behind the active acre. The strength follows the speed of the crossing and goes to zero at the dock. Both directions tested and exceeded in Forward+.
The motorboat’s swallow starts from the stern at the front and from the bow when backing. Godot test with three courses, both directions and standstill.
The braking of the motorboat to the eastern shark limit is verified in Godot with the gas suppressed from 9 m/s at 30, 60 and 120 updates per second. The ship reached zero at the border and the boat was able to back off at all three frequencies.
A new boat ride starts at the engine boat’s original mooring point with zero speed and straight outboard. Verified by driving a tour and starting a new one in the same game instance.
The boat ride start menu now explains how the left and right mouse button works when driving. Swedish language choices and the translations of the boat instruction controlled in Godot.
Screenshots can be used with the left mouse button. Verified gas, brakes and drop off the pedal via Godots viewport.
Paus also restores the clickable screen brake. Trying to pause with the pedal suppressed, continuing and gassing again.
The motorboat stops if both pedals are kept down. Try driving forward, backwards and from stagnant, including dropping the gas to back.
The snowmobile drive band now has an open towing with dual wheels, meds and bandcams. The Blender model is exported and tested in Godot.
The snowmobile skiing tips now have lifting villages that follow the skis' steering rashes. Governance, gas, brakes and disembarking tested in Godot.
The front wagon on the snowmobile has modeled spiral springs with spring seats and separate shock absorbers. Both feathers are available in the export and the driving test in Godot went through.
The snowmobile leaves a centered, 40 cm wide brake track from the drivebar at hard braking. The tyre screams of the cars are used only for wheel vehicles. Controlled track instance and sound in Godot.
When snow covers the ground, the scooter’s drive tracks also leave during regular driving. Tested gas on bare ground and snow in Godot.
Fixed the brake light on the scooter. The lamp had a material type that the game did not recognize. Verified stronger light at brakes and returns when the brake is released. The back party also has lamp houses and arc.
Brake lights now also work for the classics, Teslan, the bus, the tow truck, the raggar car and the A-tractor. Tested brightness on all twelve selectable vehicles and two traffic models and the LGF reflex is separate.
The brake lights of the player vehicle will shine during the automatic wait at red even after the release of gas. Tested red to green in Godot with free lane.
Driving aid brakes in front of parked vehicles along the direction of the journey with the same vehicle measure as the collision control. At the store’s transitional point, the main hazard app decreased from 5.80 to 0.083 m/s per step at 60 Hz. I also tried free passage at the green.
The depot bus was partly in Stationsallén’s lane. It moved 2.6 meters into the depot and extended and marked the bus route. Verified soft stop at red and passage on green with all parked vehicles on site.
The guide from depot to cafe and street kitchen is located. Checked the texts of both depot signs in Godot by switching English-Swedish-English.
The snowmobile's two skis leave 12 cm wide sheep in snow. The positions of the tracks are taken from the joints of the skis. Tested switching between snow and bare ground during track formation in Godot.
Traces formed in the snow cover fade by thigh and are removed when the snow melts. Brake tracks from Barmark remain. Verified intermediate and zero snow in Godot.
Older brake tracks on asphalt are gradually hidden by the snow cover and appear after thaw. Visibility of verified materials and preserved traces in Godot.
The start script seeks Godot 4 and explicitly prioritizes GODOT_BIN, even for specially built engines. Tested against simulated 3.x, 4.x and special buildings.
Verified choices of snowmobiles, control, gas, brakes and disembarkation in the main stage with Godot 4.7.dev NGX. Added and tried Swedish text for the DLSS setting in the same engine. The test was driven headless.
Started the main scene with real graphics in Godot 4.6.3 on AMD Renoir and controlled four frames per renderer. All three were completed normally.
Godot 4.6.3, AMD Renoir, 960×540, VSync of, fixed simulation step 1/60s. After 30 heating boxes, 90 frame ranges were measured under 5,215 m of scooter drive per renderer. Median/95th percentile in ms: Compatibility 39.3/46.9; Mobile 41.9/57.1; Forward+51.2/58.8. A short drive per location.
Profiling of the depot vehicles in Godot 4.6.3 Compatibility, 960×540: four runs with the order visible/hidden/hidden/visible, identical movement 5.215 m. The MeshInstance3D of parked vehicle models was hidden in the test. The final image went from 8304 to 7610 draw calls. Median 40.7 and 41.6 ms with models, 38.9 and 37.4 ms without. The rest of the scene also needs to be profiled. The game's vehicle display is unchanged.
Vehicle-controlled assignments, separate progress in prey, family-SMS and eating buttons for ice cream and sausages in the kiosk. Tested allocation, replacement, homework SMS, both snacks, balance and happy indicator in Godot 4 with insulated savings file.
The fire truck’s control at the square has a modeled fire mail. Tested access, collision and completed inspection on foot in Godot 4.
The fire truck's inspection in the marina has an orange lifeboy on the stand next to the walking destination. Tested collision, accessibility and transition to the next mission in Godot 4.
Two people from the fire protection team meet the player at the health centre during the first mission of the fire truck. Tested the walking goal, the meeting and the transition to the inspection at the dock in Godot 4.
Current assignments are at the top of the phone even after the SMS history is completed. Verified vehicle replacement, Swedish heading and free driving in Godot 4.
The keyboard marking of the kiosk is moved to the next edible snack when the last portion is eaten, then to the first buy button. Verified with two Enter prints through Godots viewport and control of stock balance and coins.
Package assignments have two visible cartons in the square. After pick-up, the respective cardboard is shown at the drop-off point of the health centre or marina when the delivery is completed. Verified all four states in Godot 4.
Two folded blankets are visible at the snowmobile pickup point, on the scooter during delivery and on the recipients after dropping. The entire assignment was verified in Godot 4.
The phone’s SMS list can be rolled and opened at the top. Verified separately with Swedish text in Godot 4 and 640×360 windows.
The phone supports Page Up, Page Down, Home and End when the inbox is open. Tested keyboard events in a separate telephone view with Swedish text in Godot 4.
Pure imports of published origin/main b283268 into separate project folder: the main stage and depot started in Godot 4.6.3 Compatibility. Swedish SMS rolling through the main stage, package and file delivery and keyboard-controlled kiosk visits passed with graphics in 640×360 and isolated savings files. No scripts or engine failures in the test logs.
The vehicle selection task menu shows the assignment type before start. Swedish headlines for ambulance, police, fire truck, packages and file delivery verified in Godot 4.
The player’s mouth gets upturned mongipes after ice cream or sausage. Verified activation on the walking and driver model and return when the joy time has expired in Godot 4.
Mouse control with V and free pointer when the button is released. Axis, Alma and pedestrians have new facial features, clothing details and steps with curved knees. Tested time in the quaystacks with both gamers. Weather clothes follow the season and current rainfall for walking and sitting people.
At the start, all 25 people get their clothes already when the stage is built. Tested with four saved weather choices in Godot 4.6.3 prior to the first process frame.
The front wagon of the road shows the next stop on a stone-colored side sign at the door. Tested all three sign changes during both automatic and manual driving in Godot 4.6.3.
Four signal-regulated transition sites have targeted night lighting. Godot 4.6.3 verified day and night modes and that each candle canopy reaches the center of the transition site.
The eight wheels of the stroller and the roller tower roll after real movement and the respective wheel radius. Tires, rims, hubs and valves follow the same axis. Verified in Godot 4.6.3.
The pedestrians on the sidewalks of the main street turn and go back at both ends of the street. Verified coherent movement through both turns in Godot 4.6.3.
Daylight is subdued before automatic precipitation and gradually returns afterwards. Verified transition sun-snow sun in Godot 4.6.3.
The cloudiness of Heaven follows the same weather transition as the sunlight. Tested the celestial material before the snowfall and during the clearance in the main stage.
The four main crossings have painted stop lines in the right lane of the route. The location of verified markings against red light braking in Godot 4.6.3.
Two new family SMS about grandfather's mirror image on the Tvärbanan and the teddy's socket cap. Tested delivery and language change in the inbox with up-to-date mission at the top.
Escape closes an open phone and allows driving to continue. Also tested the Swedish closing button and the next Escape pauses the game.
Vehicle radion pauses at disembarking and continues in the same place when embarking. Tested both seat changes and shutdown with the radio action in Godot.
The stop braking of Tvärbanan counts with the movement under each frame. Verified all stations in driver and passenger mode at 30, 60 and 120 simulation steps per second.
The school’s taxi seat has a yellow double-sided TAXI sign at the assignment’s pavement curb. Controlled placement and both reading directions in Godot.
The school transport confirms that the student is in the taxi and the student thanks at the school. Tested Swedish text, pick-up and drop-off and exactly a payout of 15 coins.
Driving aid is verified in Godot 4.6.3: a rolling taxi does not pick up a pupil, a suspended wait begins again and a complete stop at both pickup and drop-off gives 15 coins exactly once without button pressing.
The store menu retains keyboard focus at language change. Tested that the ice cream button remains selected and two owned ice creams are displayed in both Swedish and English.
The shops show the wallet balance in the shopping menu. Tested the balance before and after an ice cream purchase and when the coins were not enough for sausages.
Coherent savings file test in Godot 4.6.3: school transport provided 15 coins, the ice cream cost four and was in the kiosk after recharging the main stage. The student could eat the saved ice cream; the next recharge kept the balance and showed zero ice creams.
The rear destination sign of the bus shows the line and the next stop even from the side of the camera. Verified six mission steps and free run in Godot.
The text size of the bus destination signs is adapted to the stop name. Checked the text width for all six names and the same size in front and back.
Verified six stops with the bus’s driving assistance: rolling bus served no stop, three drops gave a total of 45 coins and the next goal and sign returned to the square.
Pure imports from published 1c76c53: eight scenario tests in Godot 4.6.3 approved for mouse camera, stop lines, tvärbanan braking, school transport and kiosk-saving, bus round, winter weather, phone and radio. Each scenario used a separate savings folder.
Graphic control of published game code in Godot 4.6.3 at 960×600: Compatibility, Mobile and Forward+ rendered the bus mission. On the Compatibility image, the entire 502 SUBD was read from the companion camera.
The open phone releases the mouse pedals so that clicks during SMS reading do not gas or brake. Verified with the left and right mouse button before, during and after the phone view in Godot.
The mid-button trait now keeps the camera still when the phone or store’s shopping menu is open. Tested to pull back the camera after both views of Godot 4.6.3.
The phone’s current mission has a fixed location above the rollable SMS history. Tested position when scrolling, Swedish heading, unread messages and history without a mission.
At bus missions, two passengers await together and as many are visible after disembarkation. The number and position of the groups tested at the six stops.
Swedish stop information verified in driver and passenger mode through the entire Tvärbanan loop. During each stop, the correct station and six and four seconds remained; at the time of departure, the status line was switched to the next stop.
The first handed-in car remains in the workshop even while the next car is on the tow truck’s flatbed. Verified both salvations and two payouts of 20 coins.
- Slask combines scarf, rain hat and rain collar. The visibility of the garments in slask, snow, rain and residence was controlled in Godot 4.6.3.
- Automatic weather retains the manual forecast in five game minutes even at unusual seasonal weather. Tested with summer snow and gradual thawing in Godot 4.6.3.
- Rain streaks follow the fall direction and six-edge snowflakes vary in size. The life of the particles also covers high cameras. Weather tests run without graphics in Godot 4.6.3, visual control remains.
- Visual control from the compatibility ambulance camera showed dark spots even on full snow cover. The snow now covers the roadway gradually and has matte surface at full coverage. Compared before and after in the same view.
- Snow and hydrogen now also affect painted lanes, cycling quantities, passageways and parking boxes. Checked full snow cover from the companion camera in Godot Compatibility.
- The same winter view with the ambulance and total snow cover was visually checked in Mobile and Forward+ on Radeon Renoir with the Volcano in Godot 4.6.3. Assignment arrows, steering wheels and pedals are also visible there. This checks the look of the scene on this computer.
- Gas and brakes each have solid color and shape even in sleep mode. A printed pedal is lowered and has a light frame. The rest controlled visually in the camera.
- The boat's back pedal shows the right mouse button when backing and is visually released when the boat slips backwards. Both permits were verified in Godot 4.6.3.
- Land vehicles brake before both quay edges with the dimensions of the body and cannot turn out the corners over the surface of the water. Checked with the ambulance against both beaches and free passage on both bridges in Godot 4.6.3.
- Lotten received reshaped hulls, loops, landings, steering cabin and transparent salon with fourteen seats as well as hull mirroring in daylight. Final GLB imported and controlled in the channel's regular Godot scene. Backing and turning at the quay also tested.
- The player’s feet need support on the dock, sidewalk on the bridge or bridge. Even long walking steps are divided so that they can’t skip water. Verified both landings, the promenade and walking towards the quay edge.
- The model now features Lotten's high flag bars, upper reling, black fenders, yellow gates, lifeboys and waterline from the new references. Final game view controlled in Godot.
- Lotten takes passengers from both bridges. Ascension and disembarkation with F or the screen button when the ferry is inside. Steering and stepping out over the water is locked up while traveling. Goodot test of luck and return with the quay protection and the new model approved.
- Passengers at Lotten see the remaining seconds to the dock followed by the drop-off button. Swedish countdown checked visually on board in Godot 4.6.3.
- Both bridges show the waiting time for that bridge. Tested in Swedish at departure, at the opposite bridge and a second before arrival; boarding was activated upon arrival.
- Both stairs to the ferry are marked with double-sided LOTTEN signs on land. Checked the sign's readability from the street in Compatibility.
- On board, the player can choose the next bridge in advance and regret the choice. Tested interrupted disembarking and automatic disembarking on viable dock in Godot.
- With the phone open, F does not affect the ferry’s disembarkation or vehicle replacement. Tested F with open and closed SMS windows on board in Godot.
- Alma was given Axel's length when she left Lotten. A test that measured the scale even on the bridge failed before the change and passed afterwards.
- Persistent regression test for both directions of the Lotten, disembarkation of open water, foot attachment and preserved character scale can be found in tests/ferry_passenger.gd. approved in Godot 4.6.3.
- Radio with J also serves as passengers at Lotten. Player tests in Godot checked that the onset radio was paused on the walkway, resumed on board and paused upon disembarkation.
- The mission of the package cars sends SMS receipts for pickup on the square and the respective recipients. The entire package tour was tested with the Volvo 240, including three receipts and 30 coins.
- The next package follows the player visible on foot. Tested that both packages in the Volvo assignment are moved to the right recipient after delivery.
- The package follows the walking movement of the upper body and both arms are held forward during delivery. Reservation and handover controlled in Godot.
- The close-up showed that the hands disappeared into the carton. Adjusted arm angle and new control from the side show the closest hand to the outside of the carton.
- Testing tests/water_exit.gd Check that the player can get out of and in the car on both sides of the bridges and stay on board the motor boat in the canal.
- The plot shows a personal countdown when disembarking is selected. Swedish status in elections and regrets and disembarking at the next bridge tested in Godot.
- Assignment arrows are hidden at the time of ascension on Lotten and are displayed from the new dock at disembarkation. Tested with active mission in Godot.
- At both ferry docks, the walkway tour begins on the boards of the landing and leads via the quay staircase to the street. The position and height of the first arrow controlled in Godot.
- In the case of a vehicle change in the depot, the time for ongoing assistance and temporary status text is zeroed. Verified telephone assignments and restored times for taxi, bus and salvage car in Godot.
- The regression test in `tests/taxi_dispatch.gd` picks up a taxi passenger, switches to the bus and back, and checks the destination, a single fare payment and the next school pickup.
- The student who is picked up at the school tells us that the next stop is the health centre. Both the lodge and pickup were tested in Swedish.
- tests/bus_route.gd Try line 502 through six stop visits with automatic assistance, both destination signs, three ticket revenues and return to Torget.
- Traffic reacts to the visible player vehicle and parked vehicles. In an isolated Godot test, the car stopped 1.10 m behind the bus and continued as it disappeared from the lane.
- Automotives who have already taken care of an A tractor will remember that even if another car comes in between. Godot tests confirm that the titanium is restored when the distance to the tractor increases.
- The Porsche 911 GT3 RS is available in the depot with its own Blender model, wheel rig, engine sound and dumb. The body has shaped headlight houses, open cooler intake, sculpted hoods, wide rear screens and double rear wing. Driving tests compared to the taxi show exactly three times the acceleration of the first second and three times the top speed of both driving modes (90 and 237.6 km/h respectively). Departure and re-entry tested in Godot 4.6.3.
- The white backlight of the pot sits under the curved rear light ramp. The Godot test verifies that the brake lights shine at stops and that the backlight is lit upon reversal. The lower reflexes have separate passive material.
- The front-carbon fibre splitter of the porsch has a arched profile and rounded front edge that follows the bumper during all three air intake. Checked in Blender rendering and with driving tests in Godot.
- The sidoprofil of the porsch follows the new image references with white lacquer, red tenected rims, wide GT3 RS decor, carbon fibre blades behind the front wheels and reshaped air intake in front of the rear wheels.
- The buckwing range decreased by 11%, the depth of the wing profile by 24% and the height above the fortress by 21%. Less grid openings, folders with separate projectors, seals and transparent lenses. Checked from two rendering angles and with driving tests.
Both projector lenses shine with the half light at night. The switch between day and night is tested in Godot 4.6.3.
Manual weather changes now follow the same slow course as automatic. Godot test tests/weather_transition.gd Controls clouds before snow and the snowfall continues when switching to automatic.
Automatics can provide slask during spring and autumn. The weather transition test also checks that slask provides both hydrogen and snow on the ground.
During the winter rain, the people retain the scarf when the rain hat comes on. The visibility of the garment checked in Godot for winter and summer rains.
Reviewed rain and snow in a separately rendered Compatibility scene. The thickness of the snowflakes was increased so that nearby flakes are also visible from the side.
Particle systems only release the precipitation that actually falls. Tested in Godot that both emit particles when slack and shut down after arousal.
Precipitation is placed after the camera moves in the same frame. Tested with Lotten and Tvärbanan in Godot 4.6.3.
The pause of the game also freezes falling rain and snow. Godot tests verified the speed of both particle systems at pause and resume during slask.
Verified vehicle radio when switching from car to Lotten. The music paused on foot and continued from the same place on board.
Extended SMS history from four to 32 messages per game round. Verified reading of a family text message after 31 receipts, the unobstructed counter and that the oldest message disappears only at the next delivery.
The family now sends seven different SMS messages, including grandfather greetings from Lotten and mother’s cinnamon noise. All seven were delivered via the phone’s timer and displayed in both languages after language change in Godot.
SMS is displayed in a mobile phone of 248 × 350 with rollable history. Visually verified in Godot in Swedish. Axel and Alma have their own face shapes and portraits as drivers. The gait has weight transfer, curved elbows and heel-to-tow steps. Both were tested in Godot 4.6.3.
The steam rig measures the ground at heel and toe. Tested Axel and Alma with the toe on a 12 cm high test step and heel over lower ground.
Local Godot 4.7.dev.custom_build.f8d44ac6b: all seven tests/*.gd approved without reported motor or script errors in headless mode (bus, Lotten, walk, Porsche, taxi, water and weather).
The XC60 has new body, T-shaped lanterns and freed blue light ramp. Tvärbanan has new carriage baskets, moving belts and two cabins. Cars can run into other traffic and parked cars. The Bumper test controls contact and rebound.
The road traveler sits inside the middle wagon with a free mouse. The coupe has patterned seats, ceiling lamps, yellow handles and stop signs. Image from the passenger camera and three sign switches checked with local Godot 4.7 DVD.
The Perronger of the Cross Trail follows the curve along all three carriage parts. Six door blades against the perrong are opened at a break and closed before departure. Tested at all three stations in Godot 4.7 Dev.
The electric park cycle is folded with U on free ground. Axel and Alma can control, gas and brake. A neighbor goes on the sidewalk. Tested both players, wheel movement and stop and drop off at the bridge edge of the local 4.7-dev building.

## Local preliminary edition c8c5c83

- The glass car and the electric park cycle are included in DEB, RPM, take.gz and DMG in `~/Dokument/Axel-releaser/`. Select the files for c8c5c83. The RPM file is called `axels-spel-0.1.0-0.1.preview.x86_64.rpm`.
- The editable model of the Glass Car is available in `source_blender/IceCreamVan.blend`. H plays the melody. The glass round has three stops and provides ten coins per stop.
- The Linux package uses the local Godot 4.7-dev build and requires glibc 2.44. The Mac app uses Godot 4.6.3 and has verified Intel and Apple Silicon binaries in the same app. The integrity of the DMG file and the embedded game file have been checked.
- Remains for macOS: try running the app on a Mac. The preliminary edition is ad hoc-signed and lacks notarization.

## Vehicles and workplaces in the western district

- The MINI Cooper S Cabriolet can be selected in the vehicle menu and also stands at the depot. Open a coupe with the player at the driver’s seat. Sample in the main scene in Godot 4.7-dev.
- The Volvo EC950F and Volvo wheel loaders are set on the gravel pitch west of the depot. Both game models have been verified in the main stage. The machines are exhibition models with solid scooping.
- The granite wall encloses the game area. Sjökiosken, pizzeria and Sjöstaden Livs have walk-in entrances.
- The C8c5c83 package is located in yeager/deb-repo and yeager/rpm-repo. Newer local game changes are included in the next package only when built. Just create a GitHub release on explicit request.

The tram runs at street level on a 685.4 meter long loop with four stops, grass between the rails and lane in opposite directions. F at open doors allows the player to step on and off. The entire tour and protection of persons on the track were verified with Godot 4.7-dev. tests/street_tram.gd.

Six track transitions have signals for trams, cars and foot traffic. Red stops both automatic and manually operated tram. After yellow and a red time, the next direction gets green only when the crossing is free. Transition with tests/tram_signals.gd in Godot 4.7 Dev.

## Building, night lights and moped in the local game version

- In the eastern district there are four historically inspired residential buildings and seven modern Sjöstadshus. Six of the modern houses face the canal. The staircases behind glass shine warmly in the evening.
- Sjöstadens Pizzeria has brickwork, awnings and a menu in the window. Godisboden has 40 illuminated pick-and-mix bins. Tests covered walking in and out, buying pizza for eight coins and candy for four, and checking the wallet and inventory.
- Of 155 road and park lamps, 18 stand at the bench, promenade and bridge. The lanterns are lit and extinguished in the day cycle. The ground lighting at the bench is controlled by comparing rendered night images with the park lamps on and off.
- The canal reflects 15 lights along the quay and pier. Night views were rendered in Compatibility, Mobile and Forward+ using the local Godot 4.7-dev build on AMD Radeon. Testing DLSS on compatible NVIDIA hardware remains outstanding.
- Puch Dakota is available in the vehicle menu and in the depot. Axel and Alma can drive it, and a neighbor rides moped in traffic. Testing `tests/puch_dakota.gd` covers, among other things, grip on the control, braking and vehicle change in the depot.

The tram’s Blender models have rounded cab fronts with recessed lights, arched roofs, gently curved sides and blue roof panels above the sliding doors. The destination display updates at each stop. The articulated gangways have rounded corners. The exterior was inspected in the local Godot 4.7-dev build. See docs/tram-exterior.png.

### Sjömackens pumps – visual assessment 2026-11-23

Comparison between the reference photo of the pump and [pump 3 and 4 in the game view](docs/sjomacken-pump.jpg).

| Feature | Score out of 100 | observation |
|---|---:|---|
| Silhouette | 94 | Three hoses and handles sit next to the payment terminal as on the reference pump. The compact number sign sits on top of the meter house. Its rounded corners are most clearly visible on pump 3 in the updated game view. |
| Color and readability | 96 | The yellow plate separates the black hoses from the socket. The handles have the same color as the respective fuel sign. The signs above the handles show both fuel and litre price. The yellow service door is also visible under the roof. |
| Exterior details | 94 | Three open bays with dark backs and light dividers house the nozzles. The hoses pass through fittings, and the service panel has a round lock with a keyhole. The housing corners are still sharper than in the photo. |

My visual overall rating is **95/100** rounded, with equal weight for the three parts. The assessment applies to the outside viewed in the reference photo.

### Shopping Moped's Model Assessment

Assessed against the supplied Shopper photographs using front three-quarter, side and rear three-quarter views taken in Godot with a seated driver. Each category carries equal weight.

| Feature | Score out of 100 | Observation |
| --- | ---: | --- |
| Silhouette | 88 | The tapered rear deck, single rear wheel and swept roof read clearly in profile. The front corners look squarer than the moulded shell in the photos. |
| Color and surface | 84 | The cherry-red panels, silver basket and black seat match the reference palette. Sunlit panels have a flatter sheen and the lamp lens loses definition at driving distance. |
| Driving position | 85 | The side view shows the rider’s bent knees and feet extending below the handlebar. The rebuilt vinyl backrest has a rounded padded face, a slight rearward rake and ivory piping around its perimeter. |
| Exterior details | 91 | The rear view shows both deck vents, the mesh side intake and the filler cap inside the tapered basket. The tapered basket now has continuous rounded wire rims, checked in a rear three-quarter game view. |

Overall visual score **87/100** (348 ÷ 4). The front shell corners and the surface finish remain the clearest discrepancies in these views.

## Renderer diagnostics

- On Godot 4.7 dev5 with Compatibility and Radeon Renoir, two texture RIDs (87,376 and 65,532 bytes) are reported at shutdown. The same warnings reproduce in a standalone scene with only a camera and a box, as well as when quitting Harbor Town through its confirmation dialog. Use the standalone scene as a baseline when investigating future rendering warnings.
