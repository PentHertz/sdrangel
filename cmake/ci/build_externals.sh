#!/bin/bash
# Pre-build and install external dependencies that are not available as system packages.
# This avoids git clones during debuild (which can fail due to transient GitHub errors).
set -e

PREFIX="/usr/local"
JOBS=$(nproc)
BUILDDIR="$HOME/external_builds"
mkdir -p "$BUILDDIR"

run_privileged() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

build_cmake_project() {
  local name="$1"
  local repo="$2"
  local tag="$3"
  shift 3
  # remaining args are extra cmake flags

  echo "=== Building $name ==="
  cd "$BUILDDIR"
  git clone --depth 1 --branch "$tag" "$repo" "$name"
  mkdir -p "$name/build"
  cd "$name/build"
  cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" "$@"
  make -j"$JOBS"
  run_privileged make install
  echo "=== $name installed ==="
}

# --- mbelib (must be before dsdcc) ---
build_cmake_project mbelib \
  https://github.com/srcejon/mbelib.git lib \
  -DDISABLE_TEST=ON

# --- serialdv ---
build_cmake_project serialdv \
  https://github.com/f4exb/serialDV.git v1.1.5 \
  -DBUILD_TOOL=OFF

# --- cm256cc ---
build_cmake_project cm256cc \
  https://github.com/f4exb/cm256cc.git v1.1.2 \
  -DBUILD_TOOLS=OFF -DENABLE_DISTRIBUTION=ON

# --- dsdcc (depends on mbelib) ---
build_cmake_project dsdcc \
  https://github.com/f4exb/dsdcc.git v1.9.6 \
  -DBUILD_TOOL=OFF -DUSE_MBELIB=ON

# --- libsigmf ---
# Old flatbuffers submodule triggers -Wstringop-overflow false positive with GCC 13+
build_cmake_project libsigmf \
  https://github.com/f4exb/libsigmf.git new-namespaces \
  -DCMAKE_CXX_FLAGS=-Wno-error=stringop-overflow

# --- sgp4 ---
cd "$BUILDDIR"
git clone --depth 1 https://github.com/dnwrnr/sgp4.git sgp4
mkdir -p sgp4/build && cd sgp4/build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX"
make -j"$JOBS"
run_privileged make install
echo "=== sgp4 installed ==="

# --- aptdec ---
build_cmake_project aptdec \
  https://github.com/srcejon/aptdec.git libaptdec

# --- dab-cmdline (source is in library/ subdir) ---
cd "$BUILDDIR"
git clone --depth 1 --branch msvc https://github.com/srcejon/dab-cmdline.git dab-cmdline
mkdir -p dab-cmdline/library/build && cd dab-cmdline/library/build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX"
make -j"$JOBS"
run_privileged make install
echo "=== dab-cmdline installed ==="

# --- ggmorse ---
build_cmake_project ggmorse \
  https://github.com/srcejon/ggmorse.git cmake4 \
  -DGGMORSE_BUILD_TESTS=OFF -DGGMORSE_BUILD_EXAMPLES=OFF

# --- inmarsatc ---
build_cmake_project inmarsatc \
  https://github.com/srcejon/inmarsatc.git msvc

# --- rnnoise ---
build_cmake_project rnnoise \
  https://github.com/f4exb/rnnoise.git main \
  -DRNNOISE_BUILD=ON

# --- libperseus-sdr (uses commit hash, not a branch/tag) ---
echo "=== Building perseus ==="
cd "$BUILDDIR"
git clone https://github.com/f4exb/libperseus-sdr.git perseus
cd perseus
git checkout afefa23e3140ac79d845acb68cf0beeb86d09028
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX"
make -j"$JOBS"
run_privileged make install
echo "=== perseus installed ==="

# --- libmirisdr-4 ---
build_cmake_project libmirisdr \
  https://github.com/f4exb/libmirisdr-4.git v2.0.0

# Update linker cache
run_privileged ldconfig

echo "=== All external dependencies built and installed ==="
