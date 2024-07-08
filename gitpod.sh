#!/bin/bash

# Install dependencies
sudo apt install -y elfutils libarchive-tools flex bc cpio

# Clone Clang compiler if not already cloned
if [ ! -d "clang-r450784e" ]; then
    git clone --depth 1 https://gitlab.com/ThankYouMario/android_prebuilts_clang-standalone.git clang-r450784e
fi

# Set environment variables
export KBUILD_BUILD_USER=nobody
export KBUILD_BUILD_HOST=android-build
export PATH="$(pwd)/clang-r450784e/bin:$PATH"

# Clean build directory and previous build log
rm -rf out error.log KernelSU AnyKernel3 *.zip

# Prompt user for KernelSU integration
echo -e -n "\e[33mDo you want to integrate KernelSU? (y/N):\e[0m " && read integrate_kernelsu

if [ "$integrate_kernelsu" = "y" ]; then
    git fetch https://github.com/Kajal4414/android_kernel_xiaomi_spes.git 13.0-ksu
    git cherry-pick db26e4c
    curl -LSs "https://raw.githubusercontent.com/Kajal4414/KernelSU/main/kernel/setup.sh" | bash -
    ZIP_SUFFIX="SU"
    echo -e "\e[32mKernelSU Building...\e[0m"
else
    ZIP_SUFFIX=""
    echo -e "\e[33mKernelSU Skiping...\e[0m "
fi

# Build kernel and log errors
make O=out ARCH=arm64 vendor/spes-perf_defconfig \
    CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm \
    OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
    CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    LLVM=1 LLVM_IAS=1 Image.gz dtbo.img -j$(nproc --all) 2> >(tee error.log >&2)

# Display last 50 lines of log if error.log exists
if [ -s "error.log" ]; then
    echo -e "\e[1;31mBuild failed. Please check the error logs below:\e[0m"
    tail -n 50 error.log
fi

# Dummy
mkdir -p out/arch/arm64/boot
fallocate -l 8M out/arch/arm64/boot/Image.gz
fallocate -l 4M out/arch/arm64/boot/dtbo.img

# Package kernel into zip if build successful
if [ -f "out/arch/arm64/boot/Image.gz" ]; then
    ZIPNAME="Murali_Kernel${ZIP_SUFFIX}_$(date '+%d-%m-%Y')_$(git rev-parse --short=7 HEAD).zip"
    git clone -q https://github.com/Kajal4414/AnyKernel3.git -b murali
    cp "out/arch/arm64/boot/Image.gz" "out/arch/arm64/boot/dtbo.img" AnyKernel3
    (cd AnyKernel3 && zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder)
    if [ -f "$ZIPNAME" ]; then
        echo -e "\e[32m\nCompleted in $((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds!\e[0m"
        echo -e "\e[1;32mZIP: $ZIPNAME\e[0m"
    fi
fi
