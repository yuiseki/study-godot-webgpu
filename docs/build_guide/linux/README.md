# Linux Build Guide

This guide documents the Linux-side build flow used for the WebGPU startup study in this repository.

It is intentionally scoped to the setup that was actually used during investigation:

- Ubuntu Linux Desktop
- X11 session
- locally built `davnotdev/godot`
- `webgpu` branch

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

This repository is not the build guide for the WebGPU fork in general. It documents the build path used for this runtime study corpus.

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
