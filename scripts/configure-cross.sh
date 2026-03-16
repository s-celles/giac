#!/bin/bash
# Configure Android cross-compilation files by substituting NDK paths.
#
# Usage:
#   ./scripts/configure-cross.sh --ndk /path/to/android-ndk
#
# Produces ready-to-use cross files in cross/local/ (gitignored).

set -euo pipefail

NDK=""
NDK_HOST=""

usage() {
  echo "Usage: $0 --ndk <path-to-android-ndk>"
  echo ""
  echo "Substitutes @NDK@ and @NDK_HOST@ in cross/android-*.ini templates"
  echo "and writes ready-to-use files to cross/local/"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --ndk) NDK="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

if [[ -z "$NDK" ]]; then
  echo "Error: --ndk is required"
  usage
fi

if [[ ! -d "$NDK" ]]; then
  echo "Error: NDK path does not exist: $NDK"
  exit 1
fi

# Detect host platform
case "$(uname -s)" in
  Linux*)  NDK_HOST="linux-x86_64" ;;
  Darwin*) NDK_HOST="darwin-x86_64" ;;
  *)       echo "Error: unsupported host platform: $(uname -s)"; exit 1 ;;
esac

# Verify toolchain exists
if [[ ! -d "$NDK/toolchains/llvm/prebuilt/$NDK_HOST" ]]; then
  echo "Error: NDK toolchain not found at $NDK/toolchains/llvm/prebuilt/$NDK_HOST"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CROSS_DIR="$(dirname "$SCRIPT_DIR")/cross"
LOCAL_DIR="$CROSS_DIR/local"

mkdir -p "$LOCAL_DIR"

echo "Configuring Android cross-compilation files..."
echo "  NDK:      $NDK"
echo "  NDK_HOST: $NDK_HOST"
echo "  Output:   $LOCAL_DIR/"

for template in "$CROSS_DIR"/android-*.ini; do
  filename="$(basename "$template")"
  sed -e "s|@NDK@|$NDK|g" -e "s|@NDK_HOST@|$NDK_HOST|g" \
    "$template" > "$LOCAL_DIR/$filename"
  echo "  Created: $LOCAL_DIR/$filename"
done

echo "Done. Use: meson setup builddir --cross-file cross/local/android-arm64.ini"
