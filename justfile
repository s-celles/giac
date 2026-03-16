# GIAC — Computer Algebra System Library
# Task runner for build, test, and packaging tasks.
# Requires: https://github.com/casey/just

builddir := "builddir"

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
