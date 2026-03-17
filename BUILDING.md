# Building giac with Meson

This document describes how to build the GIAC CAS library and CLI tools using the Meson build system.

> **Note**: The Xcas GUI has been moved to a [separate repository](https://github.com/s-celles/xcas). This document covers libgiac, icas (CLI shell), and aide (help tool) only.

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

Or using the justfile:

```bash
just setup
just build
just test
just icas          # launch the interactive CAS shell
just aide          # launch the help tool
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

# Optional
brew install readline
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
| icas | executable | Interactive CLI shell | Always |
| aide | executable | Help tool | Always |
| hevea2mml | executable | LaTeX to MathML | Always |
| libjavagiac | shared | JNI bindings for Java | `-Djni=enabled` + JDK headers |

## Build Options

All feature options accept `auto` (detect), `enabled` (require), or `disabled` (skip).

### Bindings

| Option | Default | Description |
|--------|---------|-------------|
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
# Default build (auto-detect optional deps)
meson setup builddir

# Recommended: enable ECM for large integer factoring
meson setup builddir -Decm=enabled

# Full build with key math libraries
meson setup builddir -Decm=enabled -Dpari=enabled -Dntl=enabled \
  -Dgsl=enabled -Dlapack=enabled

# Disable LAPACK explicitly
meson setup builddir -Dlapack=disabled

# Reconfigure an existing build
meson configure builddir -Dlapack=disabled

# View current configuration
meson configure builddir
```

### Recommended Build

For best results, build in **release mode** with optional math libraries:

```bash
just setup --buildtype=release
just build

# Test large integer factoring (~1.2s)
just icas
0>> ifactor(632459103267572196107100983820469021721602147490918660274601)
650655447295098801102272374367*972033825117160941379425504503
```

> **Note**: Always use `--buildtype=release` for production builds. Debug mode (`-O0`) is 10-20x slower for computation-heavy operations like factoring.

### GMP-ECM (Optional)

The ECM option (`-Decm=enabled`) enables the [GMP-ECM](https://gitlab.inria.fr/zimmerma/ecm) library as a fallback for factoring very large integers (>60 digits) when the built-in MPQS sieve is insufficient. When enabled and no system libecm is found, GMP-ECM 7.0.6 is automatically downloaded and built as a Meson subproject.

```bash
just setup --buildtype=release -Decm=enabled
just build
```

### PARI (Optional)

The PARI library provides additional number theory functions. On macOS with Homebrew, PARI is installed but lacks a pkg-config file — the build system detects it automatically via `cc.find_library`.

```bash
brew install pari  # macOS
just setup --buildtype=release -Dpari=enabled
just build
```

## Packaging

See [PACKAGING.md](PACKAGING.md) for building Debian/Ubuntu packages and publishing to PPAs or the official Debian archive.

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
meson test -C builddir --suite check
```

**macOS-specific notes:**

- **LAPACK** is provided via the Accelerate framework automatically.
- **GMP / MPFR**: Homebrew installs these in separate Cellar directories. The build system injects GMP's `-L` path into MPFR's link flags to handle this.
- **readline**: Homebrew's readline is keg-only (not symlinked into `/opt/homebrew`). The build system falls back to `cc.find_library` to detect it.
- **CoCoA**: The build uses pkg-config only to avoid confusing the CoCoA math library with macOS's Cocoa.framework.
- **JNI**: If `giac_wrap.cxx` is out of sync with the current API, the JNI build is automatically skipped with a warning. Regenerate with `swig -c++ -java -package javagiac giac.i` if needed.

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

### ifactor fails on large numbers ("Quadratic sieve failure")

If `ifactor()` fails with "Quadratic sieve failure, perhaps number too large", ensure you are building in **release mode** (`--buildtype=release`). Debug builds are significantly slower and may time out on large numbers.

If the issue persists on numbers above ~60 digits, enable GMP-ECM as a fallback:

```bash
meson configure builddir -Decm=enabled
meson compile -C builddir
```

### LAPACK / BLAS link errors

On Linux, LAPACK requires BLAS. Install both:

```bash
sudo apt install liblapack-dev libblas-dev
```

On macOS, the Accelerate framework provides LAPACK and BLAS automatically.

### Cross-compilation: dependency not found

When cross-compiling, GMP and MPFR must be available in the target sysroot. Set `pkg_config_libdir` in the cross file's `[properties]` section to point to the sysroot's pkgconfig directory.

### JNI bindings skipped (stale wrapper)

If you see a warning like `giac_wrap.cxx references removed API (printcharptr)`, the SWIG-generated wrapper is out of sync with the current giac API. Regenerate it:

```bash
# Requires SWIG installed
cd src
swig -c++ -java -package javagiac -outdir javagiac giac.i
```

Then reconfigure: `meson setup builddir --reconfigure`

### C++ standard errors

The build requires C++14 minimum. If you see errors about `std::chrono` literals or `operator""s`, ensure your compiler supports C++14 (GCC >= 5, Clang >= 3.4).
