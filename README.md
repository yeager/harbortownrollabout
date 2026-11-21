# Axel's Emergency Vehicles

Explore a 3D waterfront neighbourhood inspired by Hammarby Sjöstad in Stockholm. Drive an ambulance, police car, fire engine or black BMW X5 M60i. Follow three untimed missions or explore the streets and bridges at your own pace.

## Play

Open `project.godot` in Godot 4.6 and press **F5**. Select a vehicle and choose **Start driving**. English is the default. Select **Settings → Language → Svenska** for Swedish.

| Action | Control |
| --- | --- |
| Accelerate | W, Up arrow or left mouse button |
| Steer | A/D or Left/Right arrows |
| Brake | S, Down arrow or right mouse button |
| Reverse | Stop, release the brake, then press S or Down again |
| Help at a mission marker | Space |
| Leave or enter a parked vehicle | F |
| Pause | P or Escape |

Gentle driving limits speed to 30 km/h and completes an interaction when you stop at the marker. The steering wheel and pedals on screen show your inputs. You can adjust volume and emergency lights independently, choose daylight or night, or let a full day pass in six minutes of active play.

## Project files

Godot loads the playable world from `main.tscn`. Vehicle meshes are in `vehicles/`, buildings and vegetation in `environment/`, and editable Blender scenes in `source_blender/`. The Python scripts in `tools/` generate models and audio. Swedish translations live in `l10n/`.

## Tvärbanan

Select **Ride the tram** in the activity menu to follow an automatic service around a fictional three-stop canal loop. Select **Drive the tram** to control its speed with W and S or the arrow keys. Steering follows the rails, and the tram stops at each platform for six seconds. The lead car carries a Swedish notice beside a blue door.

## Weather and exploration

Select a season and weather in Settings or leave either on Automatic. Automatic seasons last 30 minutes of active play. The forecast holds for five minutes, then precipitation builds or clears over roughly a minute. Snow accumulates on roads, rain darkens the asphalt and braking takes slightly longer on slippery surfaces. Manual changes take effect more quickly. Daylight includes a visible sun aligned with the light casting the street shadows.

Hold the middle mouse button and drag to orbit the exterior camera or look around from the BMW driver’s seat. Returning to the driver’s seat with **C** centres the view. On foot, nearby neighbours greet you in the selected language. Greetings appear above the speaker and use a matching system speech voice when available.

The central junction has phased traffic lights and red and green pedestrian figures beside the crossing. Traffic waits for its green phase. The player's vehicle also slows as it approaches a red signal, pedestrians in its path or a queue.

The double-ended passenger ferry **Lotten** runs between two landings in the canal. It pauses at each end before reversing direction. Its editable Blender model is in `source_blender/Lotten.blend`.

## Taxi and horns

Choose **Taxi** and start the mission activity to pick up a passenger. Follow the green arrows along the streets and over a bridge when needed. Stop at the marker to board or drop off your fare. Gentle driving handles boarding automatically. The next fare appears after drop-off.

Press **H** or click **Horn** while driving. The ambulance, police car, fire engine, BMW and taxi each have their own horn.

## Motorboat

Choose **Drive the motorboat** in the activity menu. The white centre-console boat starts in the southern canal basin. Use the same steering and pedal controls as a car. Hold the brake to slow down and reverse. The shore and buoy lines bound the boating area. Press **H** for the boat horn or drag with the middle mouse button to look around.

A blue-and-white Swedish police helicopter flies a continuous patrol above the waterfront during play. Its main and shrouded tail rotors turn independently. The editable model is in `source_blender/Polishelikopter.blend`.

Two slow, white pickup-converted A-traktors share the main street. Look for the orange triangular reflector on the back of the cab. Faster traffic following one slows down and gives a short horn greeting.

Choose **Axel · 15** or **Alma · 12** beside the vehicle selector. The choice changes the character you see on foot. Each rescue mission step earns 10 coins and completing a taxi fare earns 15. Both characters share one wallet on this installation.

Press **T** or click **Phone** during play to open the four most recent dispatches. New rescue and taxi assignments appear silently with an unread count. Completed jobs send a payment receipt. Messages follow the selected language.

## Shops

Park along Stationsallén, south of the vehicle depot, and walk through a shop doorway. The café sells cinnamon buns and berry cordial, the kiosk sells ice cream and hot dogs, and the pizzeria and sweet shop sell pizza and pick-and-mix sweets. The first product is focused when you enter. Press Tab to choose another product and Enter to buy it with mission coins. The game saves the purchase and remaining balance together.

## Roadside recovery

Select **Recovery truck** and the mission activity. Dispatch sends the location of a car with a smoking bonnet or a missing wheel. Look for the warning triangle and amber hazard lights. The hazards follow the traffic light effects setting and switch off when the car is loaded. Stop at the marker beside the car to load it onto the flatbed. Follow the arrows to the workshop and stop to unload and earn 20 coins. Gentle driving handles loading and unloading automatically. In full-speed mode, press Space while stopped.

The police station stands on the north side of the western main street. Cross the northern bridge to find Sjöstads Sjukhus and its covered emergency entrance. The hospital and neighbourhood clinic are distinct buildings.

Along the main street, a neighbour pushes a green pram near the police station and an older pedestrian walks with a four-wheel rollator near the square. They turn around at the ends of their pavement stretches.

Two sea-green 1960s-style cruisers with ivory roofs drive along the main street. They weave gently within their lanes and stop behind other vehicles.

Between the two bridges, leave your vehicle on the western bank and take the steps down to the timber boardwalk. Follow the rope railing between Lotten’s two landings and take the other staircase back up to the street.

During the rescue route, the medic hands over a green first-aid bag. It travels inside the vehicle, appears in the player's hand on foot and stays on the quay after delivery.
