FROM ubuntu:18.04

# Install dependencies from apt

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y bc nano mc build-essential autoconf libtool cmake pkg-config git \
    python-dev swig3.0 libpcre3-dev nodejs-dev gawk wget diffstat bison flex \
    device-tree-compiler libncurses5-dev gcc-aarch64-linux-gnu g++-aarch64-linux-gnu binfmt-support

# need some 32bit stuff
RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1

RUN mkdir /workspace

# grab the 64bit toolchain
RUN cd /opt; \
    wget https://releases.linaro.org/archive/13.11/components/toolchain/binaries/gcc-linaro-aarch64-none-elf-4.8-2013.11_linux.tar.xz; \
    tar xvfJ gcc-linaro-aarch64-none-elf-4.8-2013.11_linux.tar.xz; \
    rm gcc-linaro-aarch64-none-elf-4.8-2013.11_linux.tar.xz

# also grab the 32bit toolchain
RUN cd /opt; \
    wget https://releases.linaro.org/archive/13.11/components/toolchain/binaries/gcc-linaro-arm-none-eabi-4.8-2013.11_linux.tar.xz; \
    tar xvfJ gcc-linaro-arm-none-eabi-4.8-2013.11_linux.tar.xz; \
    rm gcc-linaro-arm-none-eabi-4.8-2013.11_linux.tar.xz

COPY makeimage.sh /makeimage.sh

ENTRYPOINT [ "/makeimage.sh" ]