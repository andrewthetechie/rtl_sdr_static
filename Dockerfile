from ubuntu:20.04 as base

# Builder is our base image with librtlsdr

ARG LIBRTLSDR_TAG=v0.8.0
ARG RTLSDRBLOG_TAG=V1.3.4
ARG MUTLIMON_NG_VERSION=1.3.0
ARG RTL_433_VERSION=master

ENV TZ=America/Chicago
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
# rtlsdr and rtl_433 requirements
RUN apt-get update && apt-get install -y build-essential cmake git libusb-dev libusb-1.0-0-dev libtool pkg-config libssl-dev moreutils

# staticx requirements
RUN apt-get install -y binutils patchelf build-essential scons upx
RUN apt-get install -y python3 python3-pip && pip install --no-warn-script-location --upgrade virtualenv pip poetry pyinstaller staticx

# socat, netcat, and curl 
RUN apt-get install -y socat netcat curl

# multimon-ng
RUN git clone --depth 1 --branch $MUTLIMON_NG_VERSION https://github.com/EliasOenal/multimon-ng.git && \
    cd /multimon-ng && \
    mkdir build && \ 
    cd build && \
    cmake .. && \
    make && \
    cp ./multimon-ng /usr/bin/multimon-ng

COPY /scripts /scripts

# used for storing our static linked binaries
RUN mkdir /static

## librtlsdr builder - install from git, then build rtl_433 and multimon-ng
FROM base as librtlsdr-builder
ARG LIBRTLSDR_TAG
ARG RTL_433_VERSION

# Install some more packages
RUN apt-get install -y librtlsdr-dev

# install librtlsdr from git
RUN git clone --depth 1 --branch $LIBRTLSDR_TAG https://github.com/librtlsdr/librtlsdr.git && \
    cd /librtlsdr && \
    mkdir build && \
    cd build && \
    cmake ../ && \
    make && \
    make install && \
    ldconfig

# rtl_433
RUN git clone --depth 1 --branch $RTL_433_VERSION https://github.com/merbanan/rtl_433.git && \
    cd rtl_433 && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    cp src/rtl_433 /usr/bin/rtl_433


# overwrite librtlsdr with the rtlsdr blog dribers
FROM base as rtlsdrblog-builder
ARG RTLSDRBLOG_TAG
ARG RTL_433_VERSION

RUN git clone --depth 1 --branch $RTLSDRBLOG_TAG https://github.com/rtlsdrblog/rtl-sdr-blog && \
    cd rtl-sdr-blog/ && \
    mkdir build && \
    cd build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON && \
    make && \
    make install && \
    cp ../rtl-sdr.rules /etc/udev/rules.d/ && \
    ldconfig

# rtl_433
RUN git clone --depth 1 --branch $RTL_433_VERSION https://github.com/merbanan/rtl_433.git && \
    cd rtl_433 && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    cp src/rtl_433 /usr/bin/rtl_433

FROM librtlsdr-builder as librtlsdr-staticfy
RUN /bin/bash /scripts/static.sh

FROM rtlsdrblog-builder as rtlsdrblog-staticfy
RUN /bin/bash /scripts/static.sh

FROM gcr.io/distroless/static-debian12 as librtlsdr

COPY --from=librtlsdr-staticfy /static/* /bin

FROM gcr.io/distroless/static-debian12 as rtlsdrblog

COPY --from=rtlsdrblog-staticfy /static/* /bin