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

Hold the middle mouse button and drag to orbit the exterior camera. On foot, nearby neighbours greet you in the selected language. Greetings appear above the speaker and use a matching system speech voice when available.

The central junction has phased traffic lights and red and green pedestrian figures beside the crossing. Traffic waits for its green phase. The player's vehicle also slows as it approaches a red signal, pedestrians in its path or a queue.

The double-ended passenger ferry **Lotten** runs between two landings in the canal. It pauses at each end before reversing direction. Its editable Blender model is in `source_blender/Lotten.blend`.

## Taxi and horns

Choose **Taxi** and start the mission activity to pick up a passenger. Follow the green arrows along the streets and over a bridge when needed. Stop at the marker to board or drop off your fare. Gentle driving handles boarding automatically. The next fare appears after drop-off.

Press **H** or click **Horn** while driving. The ambulance, police car, fire engine, BMW and taxi each have their own horn.
