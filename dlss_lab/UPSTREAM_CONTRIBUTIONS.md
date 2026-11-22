# Contributing Godot improvements upstream

Axels Vehicle is a useful integration and reproduction project, but game-specific code, art, and assets stay here. Send a change upstream only when it fixes a Godot engine issue or improves reusable engine behavior.

## Contribution loop

1. Record the Godot repository, exact base commit, engine configuration, OS/GPU/driver, and a minimal reproduction.
2. Search existing issues and pull requests before proposing a change. For official engine behavior, use `godotengine/godot`; for the experimental Linux NGX backend currently used here, use its source repository and target branch.
3. Make the smallest engine-only patch in a clean worktree. Never include this game's scripts/assets or NVIDIA SDK/runtime files.
4. Build the affected target and run the smallest reproducible check. Record hardware limitations explicitly; a fallback on AMD does not validate DLSS on NVIDIA.
5. Run the repository's `prek` hooks on the changed files, then prepare focused technical notes with the observed failure, cause, behavior change, build/check evidence, and remaining validation. A human contributor must review, author, and submit any upstream change under the project's rules; do not have an AI agent submit a PR.

## Candidate 1: NGX initialization failure behavior

- Repository/base: `plankatron/godot`, branch `ngx-dlss-linux`, commit `f8d44ac6b38c5025593b9f76c0205df1afd208aa`.
- Local branch: `codex/ngx-init-fallback-and-user-data-logs-pr`.
- Commit: `1791547` — `Fix NGX initialization fallback and log path`.
- File: `servers/rendering/renderer_rd/effects/dlss.cpp` only.
- Change: cache a failed NGX init attempt to avoid retrying and logging on every frame; store NGX logs in Godot's writable per-user data directory; report unavailable context once and keep the ordinary rendering path.
- Evidence: Linux x86_64 Forward+ editor built successfully with `use_ngx_dlss=yes`; the modified source compiled. On AMD Radeon Graphics (RADV Renoir), NGX initialization returned `0xbad00001`, and the renderer continued without DLSS while writing its log under Godot user data.
- Build evidence: editor, Linux x86_64 debug export template, and release export template all compiled successfully with `use_ngx_dlss=yes`; both templates were installed to Godot's versioned export-template directory.
- Limits: this machine cannot verify successful NGX startup or image quality on RTX hardware. The build reports a pre-existing unused `vk_device` warning in `dlss.cpp`.
- PR: [plankatron/godot #9](https://github.com/plankatron/godot/pull/9), open against `ngx-dlss-linux`. The integration API denied PR creation with HTTP 403, so the authenticated GitHub web flow was used after pushing to the personal fork `yeager/godot-ngx-dlss`.

## Candidate 2: Unicode-safe NGX Linux paths

- Local branch: `codex/ngx-linux-unicode-paths`.
- Commit: `886226d` — `Preserve Unicode in NGX Linux paths`.
- File: `servers/rendering/renderer_rd/effects/dlss.cpp` only.
- Change: convert Godot Unicode codepoints to Linux `wchar_t` codepoints instead of widening UTF-8 bytes. This preserves runtime library and user-data paths containing non-ASCII characters.
- Evidence: the modified editor and both debug/release export template targets compiled successfully. A runtime with a non-ASCII home or install path was not available for validation.
- PR: [plankatron/godot #10](https://github.com/plankatron/godot/pull/10), open against `ngx-dlss-linux`.

Both PRs target the experimental NGX branch because `master` does not contain this backend; applying these changes to `master` would introduce backend code rather than fix existing functionality. They are contributions to the DLSS fork and are not yet PRs to the official `godotengine/godot` repository.

## Candidate 3: Runtime DLSS-SR capability query

- Repository/base: `plankatron/godot`, branch `ngx-dlss-linux`, commit `f8d44ac6b38c5025593b9f76c0205df1afd208aa`.
- Local branch: `codex/ngx-runtime-capability-query`.
- Change: expose `RenderingServer.is_dlss_supported()`, route it through `RendererSceneCull` to the active Forward+ renderer, then query NGX Vulkan `GetFeatureRequirements`. The result is cached, does not initialize the DLSS feature, and replaces the game's adapter-name heuristic.
- Evidence: Linux x86_64 Forward+ editor built with `use_ngx_dlss=yes`; the interactive AMD run reached the NGX query and logged `0xbad00012` (`OutOfDate`). This confirms the call path but is not a positive hardware support result.
- Style/build checks: Godot `prek run --files ...` passed for all 11 changed C++ files after applying `clang-format`; `codespell`, copyright/header checks, and file-format checks passed. The Forward+ editor was rebuilt successfully with `use_ngx_dlss=yes` after preserving the NVIDIA helper-header dependency order.
- Limits: capability discovery and feature creation/evaluation still need validation on a supported RTX system. The Streamline query now requires both the DLSS optimal-settings entry point and the active adapter's Streamline capability result; that build path has not been validated in this Linux NGX build.
- Branch pushed to `yeager/godot-ngx-dlss:codex/ngx-runtime-capability-query` (commit `d0ed2c7`), but no PR was submitted. Godot's current contributor rules prohibit AI agents from submitting PRs on a contributor's behalf and require advance maintainer permission for features from new contributors. Treat this branch as technical review material only; a human contributor must independently review, author, and submit any contribution in line with those rules.
- Note: pushed commit `d0ed2c7` predates Candidate 6 and does not route the query through `RendererSceneCull`; use the complete local patch as the current implementation reference.

## Official Godot direction

- Proposal: [godotengine/godot-proposals #13718](https://github.com/godotengine/godot-proposals/issues/13718), “Add support for integrating custom 3D resolution scaling methods (upscalers)”. It is open and explicitly lists DLSS/DLAA/XeSS as use cases for custom upscalers, with a RenderingDevice implementation in Mobile and Forward+.
- Relevance: a reusable Forward+ hook that lets extensions provide proprietary upscalers is a closer fit for official Godot than adding NVIDIA's proprietary runtime or a vendor-specific backend directly to core. The proposal is assigned to a maintainer and has no linked implementation PR at the time of this note.
- Current API gap: `CompositorEffect` exposes scene textures and motion vectors, but its public callback cannot enqueue a `RenderingDevice::driver_callback_add()` with tracked resources or receive Godot's active native command buffer. That internal driver callback is how this NGX backend records work in the render graph. A standalone addon therefore cannot safely replace the native DLSS upscale step with the current public hook set.
- Minimum data for a custom upscaler hook: internal HDR color, depth and velocity textures; target-size output; jitter and reset state; frame delta; camera projection/reprojection data; exposure when used; plus explicit render-graph resource usage and callback completion/readiness for a safe fallback. The current implementation additionally consumes albedo, normal/roughness and hit-distance buffers only when Ray Reconstruction is available.
- Our useful evidence is the vehicle game's real Forward+ use case and the Linux NGX fallback/readiness behavior captured below. Any implementation contribution still requires the human authorship and advance approval described in the current contribution rules.

## Candidate 4: Do not mark failed DLSS output as ready

- Repository/base: local `plankatron/godot` NGX working copy; the readiness path is in `ngx-dlss-linux`'s Forward+ renderer.
- File: `servers/rendering/renderer_rd/effects/dlss.cpp`.
- Change: `DLSSEffect::is_ready()` now waits for a successful NGX feature creation and evaluation. Before this, readiness could turn true after the warmup delay even if feature creation or evaluation had failed, causing RenderSceneBuffers to treat the upscaled output as available.
- Evidence: Linux x86_64 Forward+ editor rebuild succeeded; interactive AMD run hit NGX init error `0xbad00001`, logged the unavailable-context warning once, and continued on the renderer's ordinary presentation path.
- Limits: runtime fallback after feature creation/evaluation failure and successful DLSS evaluation still need validation on a supported RTX system. This remains local work; any upstream submission must follow Godot's current AI contribution and new contributor rules.

## Candidate 5: Report Streamline DLSS support per adapter

- File: `servers/rendering/renderer_rd/effects/dlss.cpp`.
- Change: `DLSSEffect::is_supported()` in the Streamline build now requires both the DLSS optimal-settings function and `streamline_capabilities.dlss_available`. Previously, the presence of the API function alone could expose DLSS on an adapter for which Streamline reported the feature unsupported.
- Evidence: source inspection of `StreamlineContext::enumerate_support_*()` shows `dlss_available` is populated from `slIsFeatureSupported`; the active build on this machine uses the separate NGX backend, so Streamline compilation and GPU behavior remain unverified.

## Candidate 6: Route the support query to Forward+

- Files: `servers/rendering/renderer_scene_cull.h` and `servers/rendering/renderer_scene_cull.cpp`.
- Cause: `RenderingServerDefault` forwards methods to `RSG::scene`, which is a `RendererSceneCull`. The Forward+ method was implemented on `RendererSceneRender`, but the culler inherited the default `false`, so NGX's support query never ran and the game's DLSS option stayed hidden on every adapter.
- Change: `RendererSceneCull::is_dlss_supported()` now delegates to its active `scene_render` implementation.
- Evidence: the editor rebuilt successfully; an interactive AMD run now logs the NGX query failure (`0xbad00012`) and the separate initialization failure (`0xbad00001`), with normal-renderer fallback.
- Limits: positive NVIDIA RTX support remains unverified.

## Candidate 7: Preserve NGX helper-header dependencies

- File: `servers/rendering/renderer_rd/effects/dlss.cpp`.
- Cause: Godot's include sorter reordered the NVIDIA DLSSD helper before the Vulkan resource helper it relies on, producing missing-type and missing-macro errors at compile time.
- Change: keep the NGX headers in dependency order and scope clang-format around that small include block.
- Evidence: `prek` passes for the file and the Linux x86_64 Forward+ editor rebuild with `use_ngx_dlss=yes` completes successfully.

## Bug report notes

For every future engine bug, keep the report independent of the game's content: exact engine commit, renderer/API, minimal scene or script, expected/actual behavior, logs, reproduction steps, and whether stock Godot also reproduces it. Do not label an NGX/DLSS run successful unless the runtime confirms feature creation and evaluation.
