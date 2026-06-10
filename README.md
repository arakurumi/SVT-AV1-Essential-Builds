# SVT-AV1-Essential GitHub Actions Builder

This repository builds [nekotrix/SVT-AV1-Essential](https://github.com/nekotrix/SVT-AV1-Essential) with FFMS2 support enabled.

## What It Builds

- Linux x64 on `ubuntu-24.04`
- Windows x64 on `windows-2022` through MSYS2 `UCRT64`
- Build arguments: `--disable-lto --release --static ext-lib-static use-ffms2`

The workflow uploads GitHub Actions artifacts named:

- `svt-av1-essential-linux-x64-<upstream-version>`
- `svt-av1-essential-windows-x64-<upstream-version>`

Each artifact includes the built encoder, license files, the upstream commit SHA, version output, and dependency information. FFmpeg and FFMS2 are built from source as static dependencies before SVT-AV1-Essential is compiled. The Windows artifact is expected to contain a standalone `.exe`; the workflow fails if MSYS2 DLL dependencies are still required.

The workflow also creates a GitHub Release after both platform builds finish. Release titles use the upstream version reported by the built encoder, release tags use `svt-av1-essential-<upstream-version>`, and each versioned build artifact is attached as a `.tar.gz` asset. If a manual forced build targets a version that already has a release, the release assets are replaced.

## Automatic Update Check

The workflow runs every day at `00:00 UTC`. It checks the current upstream default branch commit and skips the build if that exact commit was already built successfully.

Manual runs are available from the GitHub Actions tab. Set `force` to rebuild an upstream commit even if it was built before.
