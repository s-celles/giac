# GIAC — Computer Algebra System Library
# Task runner for build, test, and packaging tasks.
# Requires: https://github.com/casey/just

builddir := "builddir"
xcas_dir := "../xcas"
xcas_builddir := "../xcas/builddir"

# List available recipes
default:
    @just --list

# Configure the build with Meson
setup *ARGS:
    meson setup {{builddir}} {{ARGS}}

# Build the project
build:
    meson compile -C {{builddir}}

# Run unit tests
test:
    meson test -C {{builddir}} --suite unit

# Run integration (check) tests
check:
    meson test -C {{builddir}} --suite check

# Run all tests
test-all:
    meson test -C {{builddir}}

# Install to system prefix
install:
    meson install -C {{builddir}}

# Clean build directory
clean:
    rm -rf {{builddir}}

# Full rebuild from scratch
rebuild: clean setup build

# Build with GUI support (two-pass: giac → xcas → giac+GUI)
build-with-gui *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Pass 1: Build and install libgiac (without GUI) ==="
    rm -rf {{builddir}}
    meson setup {{builddir}} --buildtype=release -Dgui=disabled {{ARGS}}
    meson compile -C {{builddir}}
    meson install -C {{builddir}}
    echo ""
    echo "=== Pass 2: Build and install xcas (libxcas + xcas executable) ==="
    if [ ! -d "{{xcas_dir}}" ]; then
        echo "Error: xcas repo not found at {{xcas_dir}}"
        echo "Clone it: git clone https://github.com/s-celles/xcas {{xcas_dir}}"
        exit 1
    fi
    rm -rf {{xcas_builddir}}
    meson setup {{xcas_builddir}} {{xcas_dir}} --buildtype=release
    meson compile -C {{xcas_builddir}}
    meson install -C {{xcas_builddir}}
    echo ""
    echo "=== Pass 3: Rebuild giac with GUI support (links libxcas) ==="
    rm -rf {{builddir}}
    meson setup {{builddir}} --buildtype=release {{ARGS}}
    meson compile -C {{builddir}}
    # Fix: on macOS, patch icas/aide to use installed libgiac (same copy as libxcas)
    # to avoid symbol address mismatch between two loaded copies of libgiac
    if [ "$(uname)" = "Darwin" ]; then
        echo "Patching rpath for macOS..."
        install_name_tool -change @rpath/libgiac.0.dylib /opt/homebrew/lib/libgiac.0.dylib {{builddir}}/src/icas
        install_name_tool -change @rpath/libgiac.0.dylib /opt/homebrew/lib/libgiac.0.dylib {{builddir}}/src/aide
    fi
    echo ""
    echo "=== Done! icas now has FLTK graph output support ==="
    echo "Run: just icas"

# Build Debian package
debian:
    dpkg-buildpackage -us -uc

# Run the icas interactive CAS shell
icas *ARGS:
    {{builddir}}/src/icas {{ARGS}}

# Run the aide help tool
aide *ARGS:
    {{builddir}}/src/aide {{ARGS}}

# Show build configuration summary
info:
    meson introspect {{builddir}} --buildoptions
