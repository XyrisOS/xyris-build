FROM alpine:3.14
# Packages necessary to build the cross compiler
ARG BUILD_PKGS="bison flex mpc1-dev gmp-dev mpfr-dev texinfo build-base util-linux-dev"
# Packages necessary to build Xyris and docs
ARG TOOLCHAIN_PKGS="make nasm scons doxygen graphviz jq"
# Useful tools for debugging and image creation
ARG OTHER_PKGS="git parted xorriso gdb-multiarch"
# Install packages
RUN apk update; \
    apk add --no-cache ${BUILD_PKGS} ${TOOLCHAIN_PKGS} ${OTHER_PKGS}
# Environment variables for cross compiler
ENV BIN_VER="2.37"
ENV GCC_VER="11.2.0"
ENV CROSS_PREFIX="/opt/cross"
ENV CROSS_TARGET="i686-elf"
ENV CROSS_MAKEFLAGS="-j4"
ENV PATH="$CROSS_PREFIX/bin:$PATH"
# Build Binutils
WORKDIR /tmp
RUN export MAKEFLAGS="${CROSS_MAKEFLAGS}"; \
    wget "https://ftp.gnu.org/pub/gnu/binutils/binutils-${BIN_VER}.tar.gz"; \
    tar -xf binutils-${BIN_VER}.tar.gz; \
    rm -rf binutils-${BIN_VER}.tar; \
    mkdir build-binutils; \
    cd build-binutils; \
    ../binutils-${BIN_VER}/configure --target="${CROSS_TARGET}" --prefix="${CROSS_PREFIX}" --with-sysroot --disable-nls --disable-werror; \
    make; \
    make install-strip; \
    cd /tmp; \
    rm -rf ./*;
# Build GCC
WORKDIR /tmp
RUN export MAKEFLAGS="${CROSS_MAKEFLAGS}"; \
    wget "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.gz"; \
    tar -xf gcc-${GCC_VER}.tar.gz; \
    rm -rf gcc-${GCC_VER}.tar.gz; \
    mkdir build-gcc; \
    cd build-gcc; \
    ../gcc-${GCC_VER}/configure --target="${CROSS_TARGET}" --prefix="${CROSS_PREFIX}" --disable-nls --enable-languages=c,c++ --without-headers; \
    make all-gcc; \
    make all-target-libgcc; \
    make install-strip-gcc; \
    make install-strip-target-libgcc; \
    cd /tmp; \
    rm -rf ./*;
# Build echfs-utils
WORKDIR /tmp
RUN git clone https://github.com/echfs/echfs.git; \
    cd echfs; \
    make echfs-utils; \
    make mkfs.echfs; \
    cp echfs-utils /usr/local/bin/; \
    cp mkfs.echfs /usr/local/bin/; \
    make clean; \
    cd /tmp; \
    rm -rf ./*;
