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

## Getting `davnotdev/godot`

Do not test against upstream Godot, and do not assume the default branch is the correct one.

Use the `davnotdev/godot` fork and switch to the `webgpu` branch explicitly:

```bash
cd /path/to/repos/_godot
git clone https://github.com/davnotdev/godot davnotdev-godot-src
cd davnotdev-godot-src
git switch webgpu
```

If you are using your own fork, make sure it still tracks `davnotdev/godot` and that you are actually on `webgpu`, not on `master`, `main`, or a stale detached revision.

Recommended remote setup:

```bash
git remote add upstream https://github.com/davnotdev/godot.git
git fetch upstream
git switch webgpu
git pull --ff-only upstream webgpu
```

## Native dependency notes

At the time of this study, the fork expects additional native-side dependencies beyond the main Godot tree.

The practical setup used for this investigation followed the branch guidance shared by the fork author:

- `wgpu-native`
  - repo: `https://github.com/davnotdev/wgpu-native`
  - branch: `godot-wgpu-29.0.0`
- `naga-native`
  - repo: `https://github.com/davnotdev/naga-native`
  - branch: `naga-patches-wgpu-29`
- `spirv-webgpu-transform`
  - repo: `https://github.com/davnotdev/spirv-webgpu-transform`
  - branch: `pruneunuseddref`

This repository does not attempt to vendor those dependencies. It assumes you already have a working local `davnotdev/godot` build.

## Build note

This repository is not the build guide for the WebGPU fork. It is the runtime study corpus.

That said, one point is essential for reproducibility:

- reproduce with a locally built binary from `davnotdev/godot` on the `webgpu` branch
- do not substitute a stock Godot release
- do not substitute upstream `godotengine/godot`
- do not assume that a successful compile on another branch means WebGPU startup behavior is comparable

## Practical Linux build flow for `davnotdev/godot`

This is the shortest useful outline for reproducing the setup on Ubuntu Linux Desktop.

### 1. Install base tooling

At minimum, expect to need:

- `git`
- `python3`
- `scons`
- `clang`
- `llvm`
- `mold`
- `ninja-build`
- `pkg-config`
- `build-essential`
- Rust via `rustup`

You will also likely need the usual Godot desktop development packages for X11/OpenGL/Vulkan-related compilation. Package names may vary across Ubuntu releases.

### 2. Clone the fork and switch to the correct branch

```bash
cd /path/to/repos/_godot
git clone https://github.com/davnotdev/godot davnotdev-godot-src
cd davnotdev-godot-src
git switch webgpu
```

### 3. Build the native WebGPU dependencies

Build each dependency on the expected branch, then copy the produced static library into the matching `thirdparty/` folder inside `davnotdev-godot-src`.

#### `wgpu-native`

```bash
cd /path/to/repos/_godot
git clone https://github.com/davnotdev/wgpu-native
cd wgpu-native
git switch godot-wgpu-29.0.0
make lib-native
cp -f target/debug/libwgpu_native.a ../davnotdev-godot-src/thirdparty/wgpu/
```

#### `naga-native`

```bash
cd /path/to/repos/_godot
git clone https://github.com/davnotdev/naga-native
cd naga-native
git switch naga-patches-wgpu-29
cargo build
cp -f target/debug/libnaga_native.a ../davnotdev-godot-src/thirdparty/naga-native/
```

#### `spirv-webgpu-transform`

```bash
cd /path/to/repos/_godot
git clone https://github.com/davnotdev/spirv-webgpu-transform
cd spirv-webgpu-transform
git switch pruneunuseddref
cd ffi
cargo build
cd ..
cp -f target/debug/libspirv_webgpu_transform_ffi.a ../davnotdev-godot-src/thirdparty/spirv-webgpu-transform/
```

### 4. Verify that the libraries are in place

Before building Godot, make sure the fork can see the copied static archives:

```bash
ls davnotdev-godot-src/thirdparty/wgpu/libwgpu_native.a
ls davnotdev-godot-src/thirdparty/naga-native/libnaga_native.a
ls davnotdev-godot-src/thirdparty/spirv-webgpu-transform/libspirv_webgpu_transform_ffi.a
```

### 5. Build the Godot editor

A practical debug-oriented Linux build command is:

```bash
cd /path/to/repos/_godot/davnotdev-godot-src
scons \
  platform=linuxbsd \
  optimize=none \
  debug_symbols=yes \
  use_llvm=yes \
  linker=mold
```

If you want to stay closer to the fork author's tested setup, a more explicit variant is:

```bash
cd /path/to/repos/_godot/davnotdev-godot-src
scons \
  --max-drift=1 \
  --experimental=ninja \
  platform=linuxbsd \
  optimize=none \
  debug_symbols=yes \
  use_llvm=yes \
  linker=mold
```

### 6. Expected output binary

The editor binary is typically produced at:

```bash
bin/godot.linuxbsd.editor.x86_64.llvm
```

That is the binary used throughout this study.

### 7. Important branch / build caveats

- Rebuild if you change any of the dependency branches.
- Do not mix a `webgpu` engine checkout with stale third-party static libraries.
- If startup behavior changes unexpectedly, verify both the Godot branch and the dependency branches before assuming a renderer regression.

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
