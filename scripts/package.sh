#!/usr/bin/env bash
# Script to package and validate the built artifacts
set -euo pipefail

# Detect binary name
if [[ "$(uname -s)" == *"NT"* || "$(uname -s)" == *"MINGW"* || "$(uname -s)" == *"MSYS"* ]]; then
  EXE_SUFFIX=".exe"
  IS_WINDOWS=true
else
  EXE_SUFFIX=""
  IS_WINDOWS=false
fi

BIN_PATH="source/Bin/Release/SvtAv1EncApp${EXE_SUFFIX}"

install -d package
cp "${BIN_PATH}" package/
cp source/LICENSE*.md source/PATENTS.md package/
git -C source rev-parse HEAD > package/upstream-sha.txt
"${BIN_PATH}" --version | tee package/version.txt
{ ldd "${BIN_PATH}" || true; } | tee package/ldd.txt

# Validation for static linking of ffmpeg/ffms2
if [ "$IS_WINDOWS" = true ]; then
  if grep -Ei '(ffms2|avcodec|avformat|avutil|swscale|swresample).*\.(dll|so)' package/ldd.txt; then
    echo "::error::FFMS2/FFmpeg is still dynamically linked. Static FFmpeg/FFMS2 build was not used."
    exit 1
  fi

  if grep -Ei '/(clang64|mingw64|ucrt64)/bin/.*[.]dll' package/ldd.txt; then
    echo "::error::Windows binary is still linked to MSYS2 DLLs. Build must be standalone before release."
    exit 1
  fi

  if find package -maxdepth 1 -iname '*.dll' | grep -q .; then
    echo "::error::Windows package contains DLL files; expected standalone executable only."
    exit 1
  fi
else
  if grep -Ei 'lib(ffms2|avcodec|avformat|avutil|swscale|swresample)[.]' package/ldd.txt; then
    echo "::error::FFMS2/FFmpeg is still dynamically linked. Static FFmpeg/FFMS2 build was not used."
    exit 1
  fi
fi

echo "Packaging and validation completed successfully!"
