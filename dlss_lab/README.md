# DLSS / Forward+ evaluation harness

This is an isolated test entry point for evaluating temporal upscalers against Axels Vehicle's real city scene. The ordinary Godot build used by the project has no DLSS integration; a separately built experimental NGX-enabled Godot engine is available locally for DLSS runs.

## Local experimental Godot build

The local `third_party/` worktree contains the Linux NGX proof-of-concept engine at commit `f8d44ac6b38c5025593b9f76c0205df1afd208aa` and NVIDIA DLSS SDK 310.9.16 (tag `v310.9.16`, commit `9981c6350dc58c0ce21f024fd65e31e851c31689`). The PoC originally bundled NGX 310.5.3; its headers, static library and Linux runtime have been overlaid with SDK 310.9.16. [`godot-ngx-dlss-local.patch`](godot-ngx-dlss-local.patch) now contains the complete local engine-source changes against that base: runtime capability reporting, Unicode-safe NGX paths, per-user logs, failed-init caching, and output readiness only after a successful NGX evaluation. NVIDIA SDK/runtime binaries and the engine worktree are ignored by Git and must not be redistributed outside NVIDIA's SDK terms.

Build the Linux x86_64 Forward+ editor with DLSS enabled:

```sh
cd dlss_lab/third_party/godot-ngx-dlss-linux
# On a clean checkout, overlay SDK 310.9.16, then apply the tracked local fixes:
git apply ../../../dlss_lab/godot-ngx-dlss-local.patch
TMPDIR="../../.build_tools/tmp" TMP="../../.build_tools/tmp" TEMP="../../.build_tools/tmp" ../../.build_tools/venv/bin/scons platform=linuxbsd target=editor arch=x86_64 use_ngx_dlss=yes use_streamline=no -j4
```

This is an experimental Godot 4.7 development fork, not an official Godot release. The test scene accepts `--dlss`, prints the active adapter's DLSS-SR capability-query result, then requests the fork's DLSS scaling mode at 67% internal resolution. DLSS requires NVIDIA NGX-capable hardware/driver and Vulkan extensions. On this machine, AMD Radeon Graphics (RADV Renoir), NGX's `GetFeatureRequirements` returns `0xbad00012` (`OutOfDate`; no support bitfield was returned), initialization fails with `0xbad00001`, and rendering continues without NGX DLSS through the renderer's normal presentation path. DLSS image quality and performance have therefore not been validated here. The fork's Linux backend supports NGX DLSS Super Resolution/Ray Reconstruction, not Streamline Frame Generation.

Both Linux x86_64 editor export templates with NGX enabled (`template_debug` and `template_release`) have been built and installed locally for this engine version. Upstream contribution candidates and their PR status are tracked in [`UPSTREAM_CONTRIBUTIONS.md`](UPSTREAM_CONTRIBUTIONS.md).

## Run

```sh
./play.sh dlss-lab
```

The first command is the native-resolution project baseline. For the current FSR 2.2 baseline, run:

```sh
./play.sh dlss-lab-fsr2
```

For a DLSS run, build the NGX-enabled editor above and launch:

```sh
GODOT_BIN="$PWD/dlss_lab/third_party/godot-ngx-dlss-linux/bin/godot.linuxbsd.editor.x86_64" ./play.sh dlss-lab-dlss
```

The custom engine exposes `Settings → Graphics → Forward+ · NVIDIA DLSS` in the game's main menu only when the engine contains the DLSS viewport enum and the NGX runtime reports DLSS Super Resolution support for the active Vulkan adapter. The capability query is cached and does not initialize the NGX feature. The entry is marked experimental and saves the choice for the next launch; feature creation can still fail later, in which case the renderer continues on its normal presentation path. To use the game with the saved setting, launch the normal game scene through the custom binary:

```sh
GODOT_BIN="$PWD/dlss_lab/third_party/godot-ngx-dlss-linux/bin/godot.linuxbsd.editor.x86_64" ./play.sh saved
```

Stock Godot and adapters for which NGX does not report DLSS-SR support do not show the DLSS entry. If a saved DLSS choice is later opened with stock Godot or an unsupported adapter, the game clears the unsupported mode and restores standard Forward+ scaling. A custom engine build still needs a supported NVIDIA RTX GPU/driver at runtime; without NGX initialization it logs a warning and continues without DLSS.

To save a timestamped run log and machine metadata, use:

```sh
./dlss_lab/profile.sh native
./dlss_lab/profile.sh fsr2
GODOT_BIN="$PWD/dlss_lab/third_party/godot-ngx-dlss-linux/bin/godot.linuxbsd.editor.x86_64" ./dlss_lab/profile.sh dlss
```

Runs are written under `dlss_lab/runs/` by default. Set `DLSS_LAB_OUTPUT_DIR` to change the output location, or `DLSS_LAB_TAG` to add a short run label. The profiler records the Godot version, OS/session type and NVIDIA GPU state when `nvidia-smi` is available. The GDScript metrics remain CPU-side frame pacing; `nvidia-smi` utilization/power snapshots are not per-frame GPU timings.

## Capture protocol

1. Use the same machine, GPU driver, display mode, output resolution, power mode and scene quality for every run. Record the Godot commit/build and rendering driver (Vulkan or D3D12).
2. The harness discards the first 30 seconds, then prints five-second average FPS and average/p50/p95/p99 CPU-side frame pacing. Capture at least 60 seconds after warm-up. These frame times are measured from GDScript's frame delta and do not represent GPU time. Capture GPU frame time with a GPU profiler (Nsight Graphics on NVIDIA; RenderDoc timing is useful for inspection, not a substitute for stable benchmark timing).
3. Compare native Forward+, FSR 2.2 at 75%, and later DLSS SR using the same output resolution. Include average and 1% low frame times, GPU time, VRAM, and power if available. FPS alone cannot attribute gains to the upscaler.
4. Inspect a fixed screenshot and a 60-second motion capture for ghosting on moving traffic/pedestrians, thin poles and wires, wet road highlights, rain, foliage, vehicle lights, and HUD. Repeat with camera orbit and car motion.
5. Verify fallback on non-RTX hardware and when the runtime is absent. Never label an option DLSS unless the active runtime reports DLSS capability and the renderer actually submits its inputs.

## Remaining work for a shippable game integration

- Run image-quality and performance checks on RTX hardware with a supported NVIDIA Linux driver.
- Validate the NGX capability query and successful feature evaluation on supported RTX hardware; keep FSR/native fallback when NGX is absent or unsupported.
- Rebase/port the experimental renderer changes onto a maintained Godot version before relying on it for releases.

## Current constraints

The standard engine remains Forward+ with AMD FSR 2.2 at 75%; the DLSS menu entry exists only in the separate experimental engine. The harness fixes the season to summer, weather to rain, and lighting to night to keep wet-road and vehicle-light artifacts visible. Traffic and some procedural activity remain time-dependent, so use the same camera framing and visual inspection when comparing screenshots. NGX logs are written to Godot's user data directory; local smoke runs set `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, and `XDG_CACHE_HOME` under `dlss_lab/.build_tools/`.
