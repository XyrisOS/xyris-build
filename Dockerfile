FROM alpine:3.14
LABEL org.opencontainers.image.description "Xyris build environment container"
# Packages necessary to build the cross compiler
ARG BUILD_PKGS="make wget bison flex mpc1-dev gmp-dev mpfr-dev texinfo build-base util-linux-dev"
# Install packages
RUN apk update; \
    apk add --no-cache ${BUILD_PKGS}
# Environment variables for cross compiler
ENV BIN_VER="2.39"
ENV GCC_VER="12.2.0"
ENV CROSS_PREFIX="/opt/cross"
ENV CROSS_MAKEFLAGS="-j6"
ENV PATH="$CROSS_PREFIX/bin:$PATH"
# Build Binutils
WORKDIR /tmp
RUN export MAKEFLAGS="${CROSS_MAKEFLAGS}"; \
    wget "https://ftp.gnu.org/pub/gnu/binutils/binutils-${BIN_VER}.tar.gz"; \
    tar -xf "binutils-${BIN_VER}.tar.gz"; \
    for TARGET in "x86_64-elf" "mips64-elf"; do \
        echo "Building binutils for ${TARGET}"; \
        mkdir "build-binutils-${TARGET}"; \
        cd "build-binutils-${TARGET}"; \
        ../binutils-${BIN_VER}/configure --target="${TARGET}" --prefix="${CROSS_PREFIX}" --with-sysroot --disable-nls --disable-werror; \
        make; \
        make install-strip; \
        cd /tmp; \
        rm -r "build-binutils-${TARGET}"; \
    done; \
    rm "binutils-${BIN_VER}.tar.gz";
# Build GCC
WORKDIR /tmp
RUN export MAKEFLAGS="${CROSS_MAKEFLAGS}"; \
    wget "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.gz"; \
    tar -xf "gcc-${GCC_VER}.tar.gz"; \
    for TARGET in "x86_64-elf" "mips64-elf"; do \
        echo "Building binutils for ${TARGET}"; \
        mkdir "build-gcc-${TARGET}"; \
        cd "build-gcc-${TARGET}"; \
        ../gcc-${GCC_VER}/configure --target="${TARGET}" --prefix="${CROSS_PREFIX}" --disable-nls --enable-languages=c,c++ --without-headers; \
        make all-gcc; \
        make all-target-libgcc; \
        make install-strip-gcc; \
        make install-strip-target-libgcc; \
        cd /tmp; \
        rm -r "build-gcc-${TARGET}"; \
    done; \
    rm "gcc-${GCC_VER}.tar.gz";
# Packages necessary to build Xyris and docs
ARG TOOLCHAIN_PKGS="nasm scons doxygen graphviz jq"
# Useful tools for debugging and image creation
ARG OTHER_PKGS="git parted e2fsprogs e2tools xorriso gdb-multiarch"
# Install packages
RUN apk update; \
    apk add --no-cache ${TOOLCHAIN_PKGS} ${OTHER_PKGS}
