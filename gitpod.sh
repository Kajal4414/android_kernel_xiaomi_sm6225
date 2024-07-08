#!/bin/bash

# Install dependencies
sudo apt install -y elfutils libarchive-tools flex bc

# Clone Clang compiler if not already cloned
if [ ! -d "clang-r450784e" ]; then
    git clone --depth 1 https://gitlab.com/ThankYouMario/android_prebuilts_clang-standalone.git clang-r450784e
fi

# Set environment variables
export KBUILD_BUILD_USER=nobody
export KBUILD_BUILD_HOST=android-build
export PATH="$(pwd)/clang-r450784e/bin:$PATH"

# Clean build directory and previous build log
rm -rf out build.log

# Build kernel and log errors
make O=out ARCH=arm64 vendor/spes-perf_defconfig \
    CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm \
    OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
    CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    LLVM=1 LLVM_IAS=1 Image.gz dtbo.img -j$(nproc --all) 2>&1 | tee build.log

# Display last 50 lines of log if build.log exists
if [ -f "build.log" ]; then
    clear
    echo -e "\e[1;31mBuild failed. Please check the error logs below:\e[0m"
    tail -n 50 build.log
fi
