#!/bin/bash
export KBUILD_BUILD_USER=ABHI
export KBUILD_BUILD_HOST=ABHIXXY
# Compile plox
function compile() {
    make -j$(nproc) O=out CC=clang ARCH=arm64 lavender-perf_defconfig
    make -j$(nproc) ARCH=arm64 O=out CC=clang \
                               CROSS_COMPILE=aarch64-linux-gnu- \
                               CROSS_COMPILE_ARM32=arm-linux-gnueabi-
}
compile 
