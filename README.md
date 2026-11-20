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
