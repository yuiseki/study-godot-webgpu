# study-godot-webgpu

Small Godot projects for isolating `webgpu` / `wgpu` startup behavior on Linux/X11.

These projects are intentionally minimal and avoid imported assets where possible.

## Reproduction assumptions

This study currently assumes a Linux desktop environment, not a generic "any Linux" target.

Tested baseline:

- Ubuntu Linux Desktop
- X11 session
- A real desktop GPU stack
- A locally built `davnotdev/godot` editor binary

Important limitations:

- This repository is aimed at native desktop startup debugging.
- The current notes assume a visible desktop session such as `DISPLAY=:0`.
- Wayland-only, headless-only, or remote-only setups may behave differently.
- If you are not reproducing on Ubuntu Linux Desktop with an X11-capable session, treat any mismatch as an environment difference first.

## How to build

For Linux build prerequisites, dependency branches, and the practical Ubuntu Desktop build flow for `davnotdev/godot`, see:

- [docs/build_guide/linux/README.md](/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/docs/build_guide/linux/README.md)

## Projects

- `001_node2d_only`
  - Root `Node2D` only.
- `002_sprite_one`
  - One generated `Sprite2D`.
- `003_ui_one`
  - One generated UI label.
- `004_canvas_item_batch`
  - One `Node2D` doing repeated `draw_rect()` calls.
- `005_subviewport`
  - One `SubViewportContainer` with a nested `SubViewport`.
- `006_meshinstance3d_one`
  - Minimal 3D scene with camera, light, and one `MeshInstance3D`.

## Recommended launch command

Use the locally built `davnotdev/godot` binary and force the WebGPU path explicitly:

```bash
DISPLAY=:0 /home/yuiseki/Workspaces/repos/_godot/davnotdev-godot-src/bin/godot.linuxbsd.editor.x86_64.llvm \
  --rendering-driver webgpu \
  --rendering-method forward_plus \
  --path /home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/001_node2d_only
```

Swap the project path for `002_sprite_one` or `003_ui_one` as needed.

## Compare script

Run all numbered projects with the same `webgpu` settings and collect logs:

```bash
/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/scripts/compare_webgpu_projects.sh
```

Environment overrides:

```bash
TIMEOUT_SECONDS=20 \
QUIT_AFTER=1 \
DISPLAY_VALUE=:0 \
GODOT_BIN=/home/yuiseki/Workspaces/repos/_godot/davnotdev-godot-src/bin/godot.linuxbsd.editor.x86_64.llvm \
/home/yuiseki/Workspaces/repos/_godot/study-godot-webgpu/scripts/compare_webgpu_projects.sh
```

The script writes a timestamped run directory under `logs/` and prints the generated `summary.md` path.

The raw `logs/` directory is treated as local-only scratch output. Public-facing evidence should go under dated report folders such as `docs/reports/2026-04-23/artifacts/`.

## Notes

- These projects are intended for runtime debugging, not editor feature coverage.
- If a project hangs, compare behavior across the numbered projects to identify the first feature that triggers it.
- Do not rely on default project renderer settings when testing `webgpu`; pass the driver on the command line.
- The first three projects isolate scene-node categories. The later ones isolate renderer-sensitive features.
