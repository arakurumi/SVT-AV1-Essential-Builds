#!/usr/bin/env bash
# Script to build static FFmpeg and FFMS2 dependencies
set -euo pipefail

# Determine the prefix directory (handling MSYS2 paths on Windows)
if command -v cygpath >/dev/null; then
  workspace="$(cygpath -u "${GITHUB_WORKSPACE}")"
else
  workspace="${GITHUB_WORKSPACE}"
fi

export DEPS_PREFIX="${workspace}/static-deps"
mkdir -p "${DEPS_PREFIX}"

# Build FFmpeg
echo "===================================================="
echo "Cloning FFmpeg (${FFMPEG_REF}) from ${FFMPEG_REPOSITORY}..."
echo "===================================================="
git clone --depth 1 --branch "${FFMPEG_REF}" "${FFMPEG_REPOSITORY}" ffmpeg
cd ffmpeg

# Determine platform-specific configure arguments
if [[ "$(uname -s)" == *"NT"* || "$(uname -s)" == *"MINGW"* || "$(uname -s)" == *"MSYS"* ]]; then
  echo "Configuring FFmpeg for Windows (MSYS2)..."
  FFMPEG_CFLAGS="-D_WIN32_WINNT=0x0601"
  FFMPEG_LDFLAGS="-static"
  FFMPEG_EXTRA_FLAGS="--target-os=mingw32"
else
  echo "Configuring FFmpeg for Linux..."
  FFMPEG_CFLAGS="-fPIC"
  FFMPEG_LDFLAGS=""
  FFMPEG_EXTRA_FLAGS=""
fi

./configure \
  --arch=x86_64 \
  --disable-autodetect \
  --disable-debug \
  --disable-doc \
  --disable-network \
  --disable-programs \
  --disable-shared \
  --enable-static \
  --extra-cflags="${FFMPEG_CFLAGS}" \
  --extra-ldflags="${FFMPEG_LDFLAGS}" \
  --pkgconfigdir="${DEPS_PREFIX}/lib/pkgconfig" \
  --prefix="${DEPS_PREFIX}" \
  ${FFMPEG_EXTRA_FLAGS}

make -j"$(nproc)"
make install
cd ..

# Verify FFmpeg pkg-config files
export PKG_CONFIG_PATH="${DEPS_PREFIX}/lib/pkgconfig"
if [[ ! -f "${PKG_CONFIG_PATH}/libavformat.pc" ]]; then
  echo "::error::FFmpeg pkg-config files were not installed in ${PKG_CONFIG_PATH}."
  find "${DEPS_PREFIX}" -type f -name '*.pc' -print
  exit 1
fi
pkg-config --print-errors --exists libavformat libavcodec libswscale libavutil libswresample
pkg-config --modversion libavformat libavcodec libswscale libavutil libswresample

# Build FFMS2
echo "===================================================="
echo "Cloning FFMS2 (${FFMS2_REF}) from ${FFMS2_REPOSITORY}..."
echo "===================================================="
git clone --depth 1 --branch "${FFMS2_REF}" "${FFMS2_REPOSITORY}" ffms2
cd ffms2
./autogen.sh
PKG_CONFIG="pkg-config --static" ./configure \
  --disable-dependency-tracking \
  --disable-shared \
  --enable-static \
  --prefix="${DEPS_PREFIX}"

make -j"$(nproc)"
make install
cd ..

# Verify FFMS2 build
test -f "${DEPS_PREFIX}/lib/libffms2.a"
pkg-config --static --libs ffms2
