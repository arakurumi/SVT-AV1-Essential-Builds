#!/usr/bin/env bash
# Script to build SVT-AV1-Essential
set -euo pipefail

# Determine paths
if command -v cygpath >/dev/null; then
  workspace="$(cygpath -u "${GITHUB_WORKSPACE}")"
else
  workspace="${GITHUB_WORKSPACE}"
fi

export PKG_CONFIG_PATH="${workspace}/static-deps/lib/pkgconfig"
cd source/Build/linux

if [[ "$(uname -s)" == *"NT"* || "$(uname -s)" == *"MINGW"* || "$(uname -s)" == *"MSYS"* ]]; then
  echo "Building SVT-AV1 for Windows..."
  # For Windows/MSYS2: pass static linking flags to CMake
  ./build.sh ${BUILD_ARGS} cc=clang cxx=clang++ jobs="$(nproc)" -- \
    -DCMAKE_EXE_LINKER_FLAGS="-static -static-libgcc -static-libstdc++" \
    -DCMAKE_CXX_STANDARD_LIBRARIES="-static -static-libgcc -static-libstdc++ -Wl,-Bstatic -lstdc++ -lpthread"
else
  echo "Building SVT-AV1 for Linux..."
  # For Linux: pass static linking flags to CMake
  ./build.sh ${BUILD_ARGS} cc=clang cxx=clang++ jobs="$(nproc)" -- \
    -DCMAKE_EXE_LINKER_FLAGS="-static -no-pie"
fi
