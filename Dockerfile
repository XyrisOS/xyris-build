# Use Arch Linux since it works with Scuba
FROM archlinux:base-devel
# Packages necessary to build the cross compiler
ARG REQ_PACKAGES="git wget gmp libmpc mpfr mtools nasm parted diffutils doxygen"
# Create pacman key
RUN pacman-key --init
# Update nobody to have sudo access
RUN pacman -Sy --noconfirm ${REQ_PACKAGES} && passwd -d nobody && printf 'nobody ALL=(ALL) ALL\n' | tee -a /etc/sudoers
# Install necessary packages
# Do all of this in one run command so we can
# minimize the package size
RUN pacman -Syu --noconfirm ${TMP_PACKAGES}
# Environment variables
ENV PREFIX="/opt/cross"
ENV TARGET=i686-elf
ENV PATH="$PREFIX/bin:$PATH"
ENV BIN_VER="2.36.1"
ENV GCC_VER="11.1.0"
ENV GDB_VER="10.2"
# Enable multithreaded compilation
ENV MAKEFLAGS="-j2"
# Create directories
RUN mkdir /tmp/nobody/
RUN chown -R nobody /tmp/nobody/
RUN mkdir ${PREFIX}
RUN chown -R nobody ${PREFIX}
# Build tasks as nobody user
USER nobody
# Build Binutils
WORKDIR /tmp/nobody/
RUN	wget "https://ftp.gnu.org/pub/gnu/binutils/binutils-${BIN_VER}.tar.gz"
RUN tar -xf binutils-${BIN_VER}.tar.gz
RUN rm -rf binutils-${BIN_VER}.tar
RUN mkdir build-binutils
WORKDIR build-binutils
RUN ../binutils-${BIN_VER}/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
RUN make
RUN make install
WORKDIR /tmp/nobody
RUN rm -rf build-binutils
RUN rm -rf binutils-${BIN_VER}
# Build GCC
WORKDIR /tmp/nobody/
RUN	wget "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.gz"
RUN tar -xf gcc-${GCC_VER}.tar.gz
RUN rm -rf gcc-${GCC_VER}.tar.gz
RUN mkdir build-gcc
WORKDIR /tmp/nobody/build-gcc
RUN ../gcc-${GCC_VER}/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers
RUN make all-gcc
RUN make all-target-libgcc
RUN make install-gcc
RUN make install-target-libgcc
WORKDIR /tmp/nobody
RUN rm -rf build-gcc
RUN rm -rf gcc-${GCC_VER}
# Build GDB
WORKDIR /tmp/nobody/
RUN	wget "https://ftp.gnu.org/gnu/gdb/gdb-${GDB_VER}.tar.gz"
RUN tar -xf gdb-${GDB_VER}.tar.gz
RUN rm -rf gdb-${GDB_VER}.tar.gz
RUN mkdir build-gdb
WORKDIR /tmp/nobody/build-gdb
RUN ../gdb-${GDB_VER}/configure --target=$TARGET --prefix="$PREFIX"
RUN make all-gdb
RUN make install-gdb
# Build echfs tools
WORKDIR /tmp/nobody/
RUN	git clone https://github.com/echfs/echfs.git
WORKDIR echfs
RUN	make echfs-utils && make mkfs.echfs
# Install echfs utilities
USER root
RUN cp /tmp/nobody/echfs/echfs-utils /usr/local/bin/
RUN cp /tmp/nobody/echfs/mkfs.echfs /usr/local/bin/
# Perform cleanup as root
WORKDIR /tmp/
RUN rm -rf nobody; \
    find $ROOTFS/usr/bin -type f \( -perm -0100 \) -print | xargs file | sed -n '/executable .*not stripped/s/: TAB .*//p' | xargs -rt strip --strip-unneeded; \
    find $ROOTFS/usr/lib -type f \( -perm -0100 \) -print | xargs file | sed -n '/executable .*not stripped/s/: TAB .*//p' | xargs -rt strip --strip-unneeded; \
    pacman -Scc;
# Update path to include new tools
ENV PATH="$HOME/opt/cross/bin:$PATH"
# Done.
