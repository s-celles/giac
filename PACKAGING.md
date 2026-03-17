# Packaging GIAC

This document covers building distribution packages for GIAC.

## Debian / Ubuntu

The `debian/` directory contains packaging files for building `.deb` packages using debhelper with the Meson build system.

### Prerequisites

```bash
sudo apt install debhelper meson ninja-build \
  libgmp-dev libmpfr-dev libreadline-dev libpng-dev libcurl4-openssl-dev
```

### Building the Package

```bash
# From the repository root
dpkg-buildpackage -us -uc

# Or using the justfile
just debian
```

This produces `.deb` files in the parent directory (`../`):

```
../giac_2.0.0-21_amd64.deb
../giac_2.0.0-21.dsc
../giac_2.0.0-21_amd64.changes
```

### Installing Locally

```bash
sudo dpkg -i ../giac_2.0.0-21_amd64.deb
# Fix any missing dependencies
sudo apt --fix-broken install
```

### Publishing to a PPA (Ubuntu)

To publish to a Personal Package Archive (PPA) on Launchpad:

1. **Create a PPA** at https://launchpad.net/~/+activate-ppa

2. **Set up GPG key** (one-time):
   ```bash
   gpg --gen-key
   gpg --send-keys --keyserver keyserver.ubuntu.com <KEY_ID>
   ```

3. **Build a signed source package**:
   ```bash
   debuild -S -sa
   ```

4. **Upload to PPA**:
   ```bash
   dput ppa:<your-username>/<ppa-name> ../giac_2.0.0-21_source.changes
   ```

### Publishing to Debian (Official)

To submit to the official Debian archive:

1. **File an ITP** (Intent To Package) bug at https://bugs.debian.org
2. **Find a sponsor** on https://mentors.debian.net
3. **Upload signed source package** to mentors.debian.net:
   ```bash
   dput mentors ../giac_2.0.0-21_source.changes
   ```
4. A Debian Developer reviews and uploads to the archive

See the [Debian New Maintainers' Guide](https://www.debian.org/doc/manuals/maint-guide/) for the full process.

## RPM (Fedora / RHEL)

Currently no `.spec` file is provided. Contributions welcome.

A basic workflow would be:

```bash
# Install build deps
sudo dnf install meson ninja-build gcc gcc-c++ gmp-devel mpfr-devel

# Build with Meson
meson setup builddir --buildtype=release --prefix=/usr
meson compile -C builddir
DESTDIR=rpmbuild/BUILDROOT meson install -C builddir

# Create RPM with fpm (if available)
fpm -s dir -t rpm -n giac -v 2.0.0 -C rpmbuild/BUILDROOT
```

## Homebrew (macOS)

Currently no Homebrew formula is provided for the Meson-based build. The upstream `giac` formula in Homebrew core uses autotools.

## Julia (BinaryBuilder)

For Julia packaging via [Yggdrasil](https://github.com/JuliaPackaging/Yggdrasil), see the GIAC_jll recipe. The Meson build is not yet integrated into BinaryBuilder (it still uses autotools).
