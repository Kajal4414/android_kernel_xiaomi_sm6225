# Install dependencies
sudo apt install -y elfutils libarchive-tools flex bc

# Clone the Clang compiler repository
git clone --depth 1 https://gitlab.com/ThankYouMario/android_prebuilts_clang-standalone.git clang-r450784e

# Set environment variables
export KBUILD_BUILD_USER=nobody
export KBUILD_BUILD_HOST=android-build
export PATH="$(pwd)/clang-r450784e/bin:$PATH"

# Clean the build directory
rm -rf out

# Build the kernel and capture errors to a log file
make O=out ARCH=arm64 vendor/spes-perf_defconfig \
    CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm \
    OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
    CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    LLVM=1 LLVM_IAS=1 Image.gz dtbo.img -j$(nproc --all) 2>&1 | tee build.log

# Check if build failed and display error logs
if [ $? -ne 0 ]; then
    echo "Build failed. Error logs:"
    tail -n 50 build.log  # Display last 50 lines of the log file
fi
