#!/bin/bash
echo "Cloning dependencies"
git clone --depth=1 -b old-cam https://github.com/stormbreaker-project/android_kernel_xiaomi_lavender kernel
cd kernel
git clone --depth=1 https://github.com/crDroidMod/android_prebuilts_clang_host_linux-x86_clang-6032204 clang
git clone --depth=1 https://github.com/KudProject/arm-linux-androideabi-4.9 gcc32
git clone --depth=1 https://github.com/KudProject/aarch64-linux-android-4.9 gcc
git clone https://github.com/sohamxda7/Anykernel3.git -b lavender --depth=1 AnyKernel
echo "Done"
KERNEL_DIR=$(pwd)
IMAGE="${KERNEL_DIR}/out/arch/arm64/boot/Image.gz-dtb"
TANGGAL=$(date +"%Y%m%d-%H")
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PATH="${KERNEL_DIR}/clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export ARCH=arm64
export KBUILD_BUILD_USER=sohamsen
export KBUILD_BUILD_HOST=circleci
# sticker plox
function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAACAgUAAxkBAAJNIl44MHAX4Kg_6opRvrIM0PNjcLZfAAKwAAN24FYTSoIYNjisXxwYBA" \
        -d chat_id="$chat_id"
}
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="New build available!%0ADevice : <code>Xiaomi Redmi Note 7/7S</code>%0AToolchain : <code>${KBUILD_COMPILER_STRING}</code>%0ABranch : <code>${BRANCH}</code>%0ACommit Point : <code>$(git log --pretty=format:'"%h : %s"' -1)</code>"
}
# Push kernel to channel
function push() {
    cd AnyKernel || exit 1
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}
# Build Success
function buildsucs() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build Success. Congratulations!"
}
# Compile plox
function compile() {
    make -j$(nproc) O=out ARCH=arm64 lavender-perf_defconfig
    make -j$(nproc) O=out \
                    ARCH=arm64 \
                    CC=clang \
                    CLANG_TRIPLE=aarch64-linux-gnu- \
                    CROSS_COMPILE=aarch64-linux-android- \
                    CROSS_COMPILE_ARM32=arm-linux-androideabi-

    if ! [ -a "$IMAGE" ]; then
        finerr
        exit 1
    fi
    buildsucs
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 Predator-Stormbreaker-${TANGGAL}.zip *
    cd ..
}
compile
zipping
sticker
sendinfo
push
