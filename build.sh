#!/bin/bash

set -xeu -o pipefail

trap 'rm -fr rye venv' EXIT

export RYE_HOME=$PWD/rye
curl -sSf https://rye.astral.sh/get | \
    RYE_INSTALL_OPTION=--yes \
    RYE_VERSION=0.34.0 RYE_TOOLCHAIN_VERSION=3.12.3 bash

export PATH=$PWD/venv/bin:$PATH

./rye/self/bin/python3 -m venv --clear venv
python3 -m pip --no-cache-dir install pip==24.0
python3 -m pip --no-cache-dir install cmake==3.29.3 ninja==1.11.1.1

rm -fr build && mkdir -p build
cp -a cmake/config.cmake build/
cat <<'EOF' | tee -a build/config.cmake
set(USE_CUDA ON)
set(USE_CUDNN ON)
set(USE_CUBLAS ON)
set(USE_CURAND ON)
set(USE_GRAPH_EXECUTOR_CUDA_GRAPH ON)
set(USE_LLVM "llvm-config --link-static")
set(HIDE_PRIVATE_SYMBOLS ON)
set(CMAKE_CUDA_COMPILER "/usr/local/cuda/bin/nvcc")
EOF

cmake -S . -B build -G Ninja
cmake --build build

rm -fr wheels && mkdir -p wheels
for version in 3.8.8 3.9.2 3.10.0 3.11.1 3.12.0; do
    ./rye/shims/rye toolchain fetch cpython@$version
    ./rye/py/cpython@$version/bin/python3 -m venv --clear venv
    python3 -m pip --no-cache-dir install pip==24.0
    python3 -m pip --no-cache-dir wheel -w wheels ./python 
done

exit 0

