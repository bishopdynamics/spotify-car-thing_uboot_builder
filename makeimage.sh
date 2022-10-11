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

# TODO: these instructions were for "gxl" but we actually want "g12a"
#   options:
#       Amlogic Meson S905 (GXBB)
#       Amlogic Meson S905X (GXL)
#       Amlogic Meson S905X2 (G12A)
#   Car Thing uses S905D2, and prints to console G12A, and in https://github.com/spsgsb/uboot superbird references g12a, so I think thats what we need

# For the above reason, I went ahead and abstracted the CPU Firmware Model to a variable
CPU_FIRMWARE_MODEL="gxl"

# TODO ugly hardcoded paths
export PATH=/workspace/blobs/gcc-linaro-aarch64-none-elf-4.8-2013.11_linux/bin:/workspace/blobs/gcc-linaro-arm-none-eabi-4.8-2013.11_linux/bin:$PATH

# Build u-boot from superbird sources
announce "Building u-boot for superbird"
git clone --depth 1 https://github.com/spsgsb/uboot -b buildroot-openlinux-201904-g12a /workspace/u-boot
cd /workspace/u-boot
export CROSS_COMPILE=aarch64-none-elf-
make "$UBOOT_CONFIG"
make 

# now lets build the blobs that we need from amlogic
#   TODO: Need to replace https://github.com/BayLibre/u-boot.git with another repo, that has what we need for "g12a" instead of "gxl"

announce "Building amlogic blobs"
git clone --depth 1 https://github.com/BayLibre/u-boot.git -b libretech-cc /workspace/blobs/amlogic-u-boot
cd /workspace/blobs/amlogic-u-boot
sed -i 's/aarch64-linux-gnu-/aarch64-none-elf-/' Makefile
sed -i 's/arm-linux-/arm-none-eabi-/' arch/arm/cpu/armv8/${CPU_FIRMWARE_MODEL}/firmware/scp_task/Makefile

make "libretech_cc_defconfig"
make
export FIPDIR=/workspace/blobs/amlogic-u-boot/fip


announce "Collecting files"

cd /workspace/u-boot
mkdir fip

cp $FIPDIR/${CPU_FIRMWARE_MODEL}/bl2.bin fip/
cp $FIPDIR/${CPU_FIRMWARE_MODEL}/acs.bin fip/
cp $FIPDIR/${CPU_FIRMWARE_MODEL}/bl21.bin fip/
cp $FIPDIR/${CPU_FIRMWARE_MODEL}/bl30.bin fip/
cp $FIPDIR/${CPU_FIRMWARE_MODEL}/bl301.bin fip/
cp $FIPDIR/${CPU_FIRMWARE_MODEL}/bl31.img fip/
cp build/u-boot.bin fip/bl33.bin

announce "running blx_fix.sh for bl30"

$FIPDIR/blx_fix.sh fip/bl30.bin fip/zero_tmp fip/bl30_zero.bin fip/bl301.bin fip/bl301_zero.bin fip/bl30_new.bin bl30

announce "running acs_tool.pyc"

# if running the acs_tool.pyc file directly does not work, try running it with the python interpreter ("python $FIPDIR/acs_tool.pyc ...")
python $FIPDIR/acs_tool.pyc fip/bl2.bin fip/bl2_acs.bin fip/acs.bin 0

announce "running blx_fix.sh a second timefor bl2"

$FIPDIR/blx_fix.sh fip/bl2_acs.bin fip/zero_tmp fip/bl2_zero.bin fip/bl21.bin fip/bl21_zero.bin fip/bl2_new.bin bl2

announce "encrypting binaries"

$FIPDIR/${CPU_FIRMWARE_MODEL}/aml_encrypt_${CPU_FIRMWARE_MODEL} --bl3enc --input fip/bl30_new.bin
$FIPDIR/${CPU_FIRMWARE_MODEL}/aml_encrypt_${CPU_FIRMWARE_MODEL} --bl3enc --input fip/bl31.img
$FIPDIR/${CPU_FIRMWARE_MODEL}/aml_encrypt_${CPU_FIRMWARE_MODEL} --bl3enc --input fip/bl33.bin
$FIPDIR/${CPU_FIRMWARE_MODEL}/aml_encrypt_${CPU_FIRMWARE_MODEL} --bl2sig --input fip/bl2_new.bin --output fip/bl2.n.bin.sig

announce "encrypting final boot record (u-boot.bin)"

$FIPDIR/${CPU_FIRMWARE_MODEL}/aml_encrypt_${CPU_FIRMWARE_MODEL} --bootmk --output fip/u-boot.bin --bl2 fip/bl2.n.bin.sig --bl30 fip/bl30_new.bin.enc --bl31 fip/bl31.img.enc --bl33 fip/bl33.bin.enc

cp fip/u-boot.bin /output_bin/

announce "image build appears to have been successful"
