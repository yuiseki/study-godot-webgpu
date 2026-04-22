# Experiment Report: Minimal Project Startup Matrix on `davnotdev/godot`

Date: 2026-04-23

## Repository Note

The full raw `logs/` directory is intentionally kept out of version control.

For this report, a curated subset of representative logs is preserved under:

- `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/docs/reports/2026-04-23/artifacts`

Those artifacts were selected to keep the public repository readable while still preserving concrete runtime evidence for the main startup patterns discussed below.

## Goal

Determine how far the `davnotdev/godot` WebGPU fork can progress when launching the smallest possible Godot projects, and compare that behavior against known-good renderer baselines.

The key question was not "does rendering look correct?" but "how far does engine startup progress?" Specifically:

- Does the engine initialize the renderer?
- Does it reach `Loading resource: res://main.tscn`?
- Does it execute the scene's `_ready()` path?
- Does it hang before scene load, or does it load the scene and then fail?

## Test Environment

- Engine binary:
  - `/home/yuiseki/Workspaces/repos/_godot/davnotdev-godot-src/bin/godot.linuxbsd.editor.x86_64.llvm`
- Display:
  - `:0`
- Timeout per project:
  - `12s`
- Auto quit after:
  - `1s`
- Runner script:
  - `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/scripts/compare_webgpu_projects.sh`

## Project Set

Six minimal projects were used.

1. `001_node2d_only`
2. `002_sprite_one`
3. `003_ui_one`
4. `004_canvas_item_batch`
5. `005_subviewport`
6. `006_meshinstance3d_one`

These projects were intentionally chosen to increase complexity gradually while keeping startup behavior easy to reason about.

## Configurations Tested

The following renderer configurations were compared:

1. `webgpu + forward_plus`
2. `webgpu + mobile`
3. `vulkan + forward_plus`
4. `opengl3 + gl_compatibility`

## Summary Table

| Configuration | Avg elapsed | Scene load | `_ready()` | Result shape | Primary failure mode |
| --- | ---: | --- | --- | --- | --- |
| `webgpu + forward_plus` | `12.135s` | `0/6` | `0/6` | Never reaches scene load | Stalls during renderer startup before `main.tscn` |
| `webgpu + mobile` | `12.161s` | `6/6` | `6/6` | Scene loads, then times out | Repeated shader creation / shader data errors |
| `vulkan + forward_plus` | `5.130s` | `6/6` | `6/6` | Starts successfully | One 3D-specific texture usage error in project 006 |
| `opengl3 + gl_compatibility` | `2.507s` | `6/6` | `6/6` | Starts successfully | No observed errors |

## Detailed Results

### 1. `webgpu + forward_plus`

Artifacts:

- Curated representative log:
  - `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/docs/reports/2026-04-23/artifacts/webgpu-forward-plus-001-node2d-only.log`
- `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/logs/20260423-074609-webgpu-forward_plus-100631/summary.md`
- `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/logs/20260423-074609-webgpu-forward_plus-100631/summary.tsv`

Observed behavior:

- All 6 projects timed out at about 12.1 seconds.
- All 6 projects reported `webgpu=yes`.
- All 6 projects compiled exactly `32` shaders.
- None of the 6 projects reached `Loading resource: res://main.tscn`.
- None of the 6 projects reached the scene `ready` marker.
- No WGSL errors or generic runtime errors were recorded in the summary.

Interpretation:

This path appears to stall before project scene loading begins. The failure is therefore not explained by project content. Even the `Node2D`-only case fails at the same stage as the 3D case.

This is the strongest evidence that the current `webgpu + forward_plus` issue is an engine-level initialization problem rather than a scene-level or gameplay-level problem.

### 2. `webgpu + mobile`

Artifacts:

- Curated representative logs:
  - `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/docs/reports/2026-04-23/artifacts/webgpu-mobile-001-node2d-only.log`
  - `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/docs/reports/2026-04-23/artifacts/webgpu-mobile-006-meshinstance3d-one.log`
- `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/logs/20260423-075301-webgpu-mobile-110937/summary.md`
- `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/logs/20260423-075301-webgpu-mobile-110937/summary.tsv`

Observed behavior:

- All 6 projects timed out at about 12.16 seconds.
- All 6 projects reached `Loading resource: res://main.tscn`.
- All 6 projects reached the scene `ready` marker.
- The 2D-oriented projects reported `23` compiled shaders.
- Projects `001` through `005` reported `6` WGSL errors and `7` total errors.
- Project `006_meshinstance3d_one` reported `10` WGSL errors and `11` total errors.

Representative runtime signatures:

- `Condition "shader_data.is_empty()" is true.`
- `Parameter "shader" is null.`

Interpretation:

`webgpu + mobile` progresses significantly further than `webgpu + forward_plus`. It does not stall before scene load. Instead, it reaches scene startup and then degrades into repeated shader-related failures.

This means the WebGPU fork is not uniformly broken across all rendering methods. The `mobile` path is meaningfully more alive than `forward_plus`, even though it is still not usable.

### 3. `vulkan + forward_plus`

Artifacts:

- Curated representative logs:
  - `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/docs/reports/2026-04-23/artifacts/vulkan-forward-plus-001-node2d-only.log`
  - `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/docs/reports/2026-04-23/artifacts/vulkan-forward-plus-006-meshinstance3d-one.log`
- `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/logs/20260423-074858-vulkan-forward_plus-104985/summary.md`
- `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/logs/20260423-074858-vulkan-forward_plus-104985/summary.tsv`

Observed behavior:

- All 6 projects started successfully.
- All 6 projects reached `Loading resource: res://main.tscn`.
- All 6 projects reached the scene `ready` marker.
- Each project compiled `65` shaders.
- Five projects completed with zero recorded errors.
- `006_meshinstance3d_one` reported one error after scene load:
  - `Image (binding: 2, index 0) needs the TEXTURE_USAGE_STORAGE_BIT usage flag set in order to be used as uniform.`

Interpretation:

This configuration establishes that the minimal projects themselves are valid and that the engine build is capable of normal scene startup under a modern renderer path. The single error in project 006 is useful but orthogonal: it is a localized 3D resource usage issue, not a renderer initialization failure.

### 4. `opengl3 + gl_compatibility`

Artifacts:

- Curated representative log:
  - `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/docs/reports/2026-04-23/artifacts/opengl3-gl-compatibility-001-node2d-only.log`
- `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/logs/20260423-074729-opengl3-gl_compatibility-100681/summary.md`
- `/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/logs/20260423-074729-opengl3-gl_compatibility-100681/summary.tsv`

Observed behavior:

- All 6 projects started successfully.
- All 6 projects reached `Loading resource: res://main.tscn`.
- All 6 projects reached the scene `ready` marker.
- Each project compiled `13` shaders.
- No errors were recorded.

Interpretation:

This is the cleanest baseline and confirms that the minimal projects are not doing anything unusual. It also gives a lower bound for expected startup behavior on this machine.

## Comparative Findings

The four configurations do not fail in the same way.

### `webgpu + forward_plus` vs `webgpu + mobile`

This is the most important comparison in the experiment.

- `forward_plus` never reaches scene load.
- `mobile` reliably reaches scene load and `_ready()`.

That means "WebGPU is broken" is too coarse as a conclusion. The breakage is renderer-path dependent.

### `webgpu + mobile` vs `vulkan + forward_plus`

- Both reach scene load and scene startup.
- Only `webgpu + mobile` repeatedly fails shader creation / shader data validation.

This suggests the next useful debugging layer is not startup sequencing but shader translation / shader resource generation / pipeline creation.

### `webgpu + forward_plus` vs `vulkan + forward_plus`

- Same high-level rendering family intention: modern forward renderer.
- Completely different startup outcome.

This strongly isolates the problem to the WebGPU implementation path rather than to the minimal projects or the machine setup.

## Working Hypotheses After This Experiment

These are hypotheses, not conclusions:

1. `webgpu + forward_plus` is blocked by an engine-level renderer initialization problem before scene resources are loaded.
2. `webgpu + mobile` can initialize enough of the renderer to run the scene, but shader compilation or shader object creation is failing repeatedly after startup.
3. The minimal test corpus is sufficient to reproduce both classes of failure, so future debugging should stay focused on engine code rather than adding more complex scenes.

## Recommended Next Steps

1. Capture the first shader-related failure in `webgpu + mobile` and map it back to the responsible engine source path.
2. Compare the last successful initialization milestone between `webgpu + forward_plus` and `vulkan + forward_plus`.
3. Add more structured milestone logging inside renderer initialization so the "stalls before scene load" diagnosis becomes source-level rather than log-pattern-based.
4. Once the first `webgpu + mobile` shader failure is understood, reduce the reproducer further to a single smallest project that still triggers the same error.

## Bottom Line

The experiment does not support a single blanket statement like "the WebGPU fork works" or "the WebGPU fork does not work."

The more accurate statement is:

- `webgpu + forward_plus` currently fails before minimal projects even begin scene loading.
- `webgpu + mobile` currently reaches minimal scene startup but falls apart on shader-related errors.
- `vulkan + forward_plus` and `opengl3 + gl_compatibility` both validate the minimal project corpus and the surrounding runtime environment.

That is enough to justify narrowing the next debugging step specifically to:

- renderer initialization for `webgpu + forward_plus`
- shader generation / shader resource setup for `webgpu + mobile`
