ARG BASE_IMAGE_VERSION="bionic-20200311"
ARG OPENCV_VERSION="2.4.13.6"

FROM ubuntu:$BASE_IMAGE_VERSION AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential cmake git pkg-config wget unzip ca-certificates \
        libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev

WORKDIR /tmp/opencv-build
RUN wget https://github.com/opencv/opencv/archive/$OPENCV_VERSION.zip && \
    unzip $OPENCV_VERSION.zip
RUN cd opencv-$OPENCV_VERSION && \
    mkdir build && cd build && \
    cmake \
        -DWITH_TBB=ON \
        -DWITH_OPENCL=ON \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_TESTS=OFF \
        -DBUILD_PERF_TESTS=OFF \
        -DENABLE_PRECOMPILED_HEADERS=OFF \
        .. && \
    make -j$(nproc) && \
    mkdir /destdir && make DESTDIR=/destdir install && \
    rm -rf /tmp/opencv-build
WORKDIR /destdir

FROM ubuntu:$BASE_IMAGE_VERSION
MAINTAINER Roman Khotsyn <me@hotsnr.com>

WORKDIR /

# List of packages depends on actual outcome of the previous step
# Script to retrieve packages with runtime dependencies:
#
# find /destdir -executable -type f -o -name "*.so*" | \
# 	xargs ldd  | cut -d' ' -f3 | grep -v "opencv" | grep ".so." | sort -u | \
#	xargs dpkg -S | cut -d':' -f1,2 | sort -u | paste -sd " "
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libc6 libgcc1 libstdc++6 libjbig0 libjpeg-turbo8 \
        liblzma5 libpng16-16 libtbb2 libtiff5 zlib1g
COPY --from=builder /destdir /
