#!/bin/bash

# Meant to be run inside container, build u-boot and then assemble it along with proprietary, encrypted blobs from amlogic
#   this is adapted from here: http://wiki.loverpi.com/faq:sbc:libre-aml-s805x-howto-compile-u-boot


# an echo that will stand out in the logs
function announce () {
    echo "##########################################################################################"
    echo "##############################  $*  #######################################"
    echo "##########################################################################################"
}

set -e

UBOOT_CONFIG="superbird_production_defconfig"  # config used for u-boot build


export PATH=/opt/gcc-linaro-aarch64-none-elf-4.8-2013.11_linux/bin:/opt/gcc-linaro-arm-none-eabi-4.8-2013.11_linux/bin:$PATH

# Build u-boot from superbird sources
announce "Building u-boot for superbird"
git clone --depth 1 https://github.com/spsgsb/uboot -b buildroot-openlinux-201904-g12a /workspace/u-boot
cd /workspace/u-boot
export CROSS_COMPILE=aarch64-none-elf-
make "$UBOOT_CONFIG"
make 

# now lets build the blobs that we need from amlogic
announce "Signing and packaging BL33 firmware image"

git clone --depth 1 https://github.com/LibreELEC/amlogic-boot-fip -b master /workspace/amlogic-boot-fip
cd /workspace/amlogic-boot-fip

# TODO: here we try to use u200, which was the reference dev board for S905D2, however it still does not work
#   Possible reasons this does not work:
#       * the key used to sign u200 may be different than that usedin superbird
#       * u200 has secure boot disabled, but no-doubt superbird has it enabled with a key that only spotify holds
#       * the u200 does not have the exact same device tree as superbird, and some detail is tripping up the whole process


BOARD_MODEL="u200"
./build-fip.sh "$BOARD_MODEL" /workspace/u-boot/build/u-boot.bin /output_bin

announce "image build appears to have been successful"
