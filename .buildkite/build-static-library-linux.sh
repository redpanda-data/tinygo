#!/bin/bash
#
# This script is expected to be run within a Fedora 38 docker container and 
# should produce a single tarball that is the build output.

TARGET="x86_64-linux-musl"
GOURL="https://go.dev/dl/go1.20.7.linux-amd64.tar.gz"
ZIGURL="https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz"

# These same values for linux aarch64
# target: "aarch64-linux-musl"
# gourl: "https://go.dev/dl/go1.20.7.linux-arm64.tar.gz"
# zigurl: "https://ziglang.org/download/0.11.0/zig-linux-aarch64-0.11.0.tar.xz"

# Create our project directory
mkdir -p /home/tinygo-build
cd /home/tinygo-build

# install build deps
dnf install -y \
    cmake \
    git \
    ninja-build \
    which \
    xz

# install latest version of go
mkdir -p /usr/local
curl -s -L \
  $GOURL \
  | tar xz -C /usr/local 
export PATH=$PATH:/usr/local/go/bin

# install zig for a hermetic clang toolchain
mkdir -p /usr/local/zig
curl -s -L \
  $ZIGURL \
  | tar xJ --strip-components=1 -C /usr/local/zig
export PATH=$PATH:/usr/local/zig

# create wrapper scripts for zig compilation
echo -e "#!/bin/sh\nexec zig c++ -target $TARGET \"\$@\"" > /usr/local/bin/zigc++
echo -e "#!/bin/sh\nexec zig cc -target $TARGET \"\$@\"" > /usr/local/bin/zigcc
echo -e "#!/bin/sh\nexec zig ranlib \"\$@\"" > /usr/local/bin/ranlib
echo -e "#!/bin/sh\nexec zig ar \"\$@\"" > /usr/local/bin/ar
chmod +x /usr/local/bin/zigcc \
  /usr/local/bin/zigc++ \
  /usr/local/bin/ranlib \
  /usr/local/bin/ar

export CC=zigcc
export CXX=zigc++
export AR=ar
export RANLIB=ranlib

# Verify deps installed correctly
echo "go version installed:"
command -v go
go version
echo "zig version installed:"
command -v zig
zig version
echo "clang version installed:"
zig cc --version
env

git clone https://github.com/redpanda-data/tinygo.git .
# Clone submodules
git submodule update --init
pushd ./lib/binaryen
git apply /binaryen.patch
popd
# Clone LLVM
make llvm-source
pushd ./llvm-project
git apply /llvm-lseek64.patch
popd
make llvm-build
make release
# build output is in /home/tinygo/build/release.tar.gz
