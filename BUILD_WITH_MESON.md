# Building giac with Meson

This document describes how to build giac and its components using the Meson build system.

## Prerequisites

- **Meson** >= 1.2.0
- **Ninja** (or another Meson backend)
- **C/C++ compiler** (GCC >= 7, Clang, or MSVC)
- **GMP** and **MPFR** development libraries (mandatory)

## Quick Start

```bash
meson setup builddir
meson compile -C builddir
meson test -C builddir        # run test suite
meson install -C builddir     # install to prefix
```

## Installing Prerequisites

### Debian / Ubuntu

```bash
sudo apt install meson ninja-build gcc g++ libgmp-dev libmpfr-dev
```

### Fedora / RHEL

```bash
sudo dnf install meson ninja-build gcc gcc-c++ gmp-devel mpfr-devel
```

### macOS (Homebrew)

```bash
brew install meson ninja gmp mpfr
```

### FreeBSD

```bash
sudo pkg install meson ninja gmp mpfr
```

### Alpine Linux (musl)

```bash
apk add meson ninja gcc g++ gmp-dev mpfr-dev
```

### Windows (MSYS2 / MinGW)

```bash
pacman -S mingw-w64-x86_64-meson mingw-w64-x86_64-ninja \
  mingw-w64-x86_64-gmp mingw-w64-x86_64-mpfr
```

## Build Targets

The Meson build produces the following targets:

| Target | Type | Description | Condition |
|--------|------|-------------|-----------|
| libgiac | static + shared | Core CAS library | Always |
| libxcas | shared | FLTK GUI library | `-Dgui=enabled` + FLTK |
| xcas | executable | Graphical CAS | `-Dgui=enabled` + FLTK |
| icas | executable | Interactive CLI shell | `-Dgui=enabled` + FLTK |
| aide | executable | Help tool | `-Dgui=enabled` + FLTK |
| hevea2mml | executable | LaTeX to MathML | Always |
| libjavagiac | shared | JNI bindings for Java | `-Djni=enabled` + JDK headers |

## Build Options

All feature options accept `auto` (detect), `enabled` (require), or `disabled` (skip).

### GUI and Bindings

| Option | Default | Description |
|--------|---------|-------------|
| `gui` | auto | Build xcas GUI (requires FLTK) |
| `jni` | auto | Build Java bindings (libjavagiac) |

### Optional Math Libraries

| Option | Default | Description |
|--------|---------|-------------|
| `pari` | auto | PARI number theory library |
| `ntl` | auto | NTL number theory library |
| `cocoa` | auto | CoCoA commutative algebra |
| `gsl` | auto | GNU Scientific Library |
| `lapack` | auto | LAPACK linear algebra (Accelerate on macOS) |
| `ecm` | auto | ECM factorization |
| `glpk` | auto | GLPK linear programming |

### Optional Utility Libraries

| Option | Default | Description |
|--------|---------|-------------|
| `png` | auto | libpng for image output |
| `ao` | auto | libao audio output |
| `samplerate` | auto | libsamplerate audio resampling |
| `curl` | auto | libcurl for network features |
| `readline` | auto | GNU readline for icas |
| `gettext` | auto | Internationalization |
| `gc` | disabled | Boehm garbage collector |
| `dl` | auto | Dynamic loading (libdl) |

### Embedded Engines

| Option | Default | Description |
|--------|---------|-------------|
| `micropython` | disabled | Embedded MicroPython interpreter |
| `quickjs` | auto | Embedded QuickJS JavaScript engine |
| `libbf` | auto | libbf arbitrary precision |

### Build Behavior

| Option | Default | Description |
|--------|---------|-------------|
| `regen_parser` | false | Regenerate flex/bison parser files |

### Usage Examples

```bash
# Minimal build (libgiac only, no GUI)
meson setup builddir -Dgui=disabled

# Full build with all optional deps required
meson setup builddir -Dgui=enabled -Dpari=enabled -Dntl=enabled \
  -Dgsl=enabled -Dlapack=enabled

# Disable LAPACK explicitly
meson setup builddir -Dlapack=disabled

# Reconfigure an existing build
meson configure builddir -Dlapack=disabled -Dgui=disabled

# View current configuration
meson configure builddir
```

## Native Builds

### Linux (glibc / musl)

```bash
meson setup builddir
meson compile -C builddir
meson test -C builddir
```

### macOS

```bash
meson setup builddir
meson compile -C builddir
```

On macOS, LAPACK is provided via the Accelerate framework when the `lapack` option is auto or enabled. GMP and MPFR are found via Homebrew's pkg-config.

### Windows (MinGW / MSYS2)

From an MSYS2 MinGW64 shell:

```bash
meson setup builddir
meson compile -C builddir
```

### FreeBSD

```bash
meson setup builddir
meson compile -C builddir
```

## Cross-Compilation

Cross-compilation files are provided in the `cross/` directory.

### Android

Android cross files use `@NDK@` and `@NDK_HOST@` placeholders. Use the configure script to generate ready-to-use files:

```bash
# Generate cross files for your NDK
./scripts/configure-cross.sh --ndk $ANDROID_NDK_HOME

# Build for arm64
meson setup builddir-android-arm64 --cross-file cross/local/android-arm64.ini
meson compile -C builddir-android-arm64
```

Available Android targets: `android-arm.ini`, `android-arm64.ini`, `android-x86.ini`, `android-x86_64.ini`

GMP and MPFR must be pre-built for the target ABI and available via pkg-config in the sysroot.

### iOS

```bash
# Device (arm64)
meson setup builddir-ios --cross-file cross/ios-arm64.ini
meson compile -C builddir-ios

# Simulator (arm64, for Apple Silicon Macs)
meson setup builddir-ios-sim --cross-file cross/ios-sim-arm64.ini
meson compile -C builddir-ios-sim

# Simulator (x86_64, for Intel Macs)
meson setup builddir-ios-sim-x86 --cross-file cross/ios-sim-x86_64.ini
meson compile -C builddir-ios-sim-x86
```

### Mac Catalyst

```bash
meson setup builddir-catalyst --cross-file cross/maccatalyst-arm64.ini
meson compile -C builddir-catalyst
```

### Windows (from Linux)

```bash
meson setup builddir-win --cross-file cross/windows-mingw64.ini
meson compile -C builddir-win
```

### WebAssembly (Emscripten)

```bash
source /path/to/emsdk/emsdk_env.sh
meson setup builddir-wasm --cross-file cross/emscripten-wasm32.ini
meson compile -C builddir-wasm
```

### Linux ARM

```bash
# 32-bit ARM (e.g., Raspberry Pi)
meson setup builddir-arm --cross-file cross/linux-arm.ini
meson compile -C builddir-arm

# 64-bit ARM (aarch64)
meson setup builddir-aarch64 --cross-file cross/linux-aarch64.ini
meson compile -C builddir-aarch64
```

### Linux musl (Alpine)

```bash
meson setup builddir-musl --cross-file cross/linux-musl-x86_64.ini
meson compile -C builddir-musl
```

### FreeBSD (from Linux)

```bash
meson setup builddir-freebsd --cross-file cross/freebsd-amd64.ini
meson compile -C builddir-freebsd
```

## Troubleshooting

### GMP or MPFR not found

Ensure development packages are installed. On some systems, pkg-config may not find them by default:

```bash
# Set pkg-config path explicitly
PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig meson setup builddir
```

### FLTK not found for GUI build

Install FLTK development packages:

```bash
# Debian/Ubuntu
sudo apt install libfltk1.3-dev

# macOS
brew install fltk

# Fedora
sudo dnf install fltk-devel
```

### LAPACK / BLAS link errors

On Linux, LAPACK requires BLAS. Install both:

```bash
sudo apt install liblapack-dev libblas-dev
```

On macOS, the Accelerate framework provides LAPACK and BLAS automatically.

### Cross-compilation: dependency not found

When cross-compiling, GMP and MPFR must be available in the target sysroot. Set `pkg_config_libdir` in the cross file's `[properties]` section to point to the sysroot's pkgconfig directory.

### C++ standard errors

The build requires C++14 minimum. If you see errors about `std::chrono` literals or `operator""s`, ensure your compiler supports C++14 (GCC >= 5, Clang >= 3.4).
