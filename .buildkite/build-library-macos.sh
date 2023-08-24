#!/bin/bash
#
# This script is expected to be run on a mac with XCode installed along with
# brew.

# Create our project directory
mkdir -p tmp
cd tmp

brew install \
  cmake \
  ninja \
  go@1.21

# Verify deps installed correctly
echo "go version installed:"
command -v go
go version
echo "clang version installed:"
clang --version

BINARYEN_PATCH="$PWD/binaryen.patch"
LLVM_PATCH="$PWD/llvm-lseek64.patch"

git clone https://github.com/redpanda-data/tinygo.git .
# Clone submodules
git submodule update --init
pushd ./lib/binaryen
git apply "$BINARYEN_PATCH"
popd
# Clone LLVM
make llvm-source
pushd ./llvm-project
git apply "$LLVM_PATCH"
popd
make llvm-build
make release

# build output is in tmp/build/release.tar.gz
