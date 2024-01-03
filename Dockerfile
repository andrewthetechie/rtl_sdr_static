from ubuntu:20.04 as builder

# Builder is our base image with librtlsdr

ARG LIBRTLSDR_TAG=v0.8.0
ARG RTLSDRBLOG_TAG=V1.3.4
ARG MUTLIMON_NG_VERSION=1.3.0
ARG RTL_433_VERSION=23.11
ARG DIREWOLF_VERSION=1.7

ENV TZ=America/Chicago
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
# rtlsdr and rtl_433 requirements
RUN apt-get update && apt-get install -y build-essential cmake git libusb-dev libusb-1.0-0-dev librtlsdr-dev rtl-sdr libtool pkg-config libssl-dev

# install librtlsdr from git
RUN git clone --depth 1 --branch $LIBRTLSDR_TAG https://github.com/librtlsdr/librtlsdr.git
RUN cd /librtlsdr && mkdir build && cd build && cmake ../ && make && cd src && mkdir /static

# staticx requirements
RUN apt-get install -y binutils patchelf build-essential scons upx
RUN apt-get install -y python3 python3-pip && pip install --no-warn-script-location --upgrade virtualenv pip poetry pyinstaller staticx

# socat, netcat, and curl 
RUN apt-get install -y socat netcat curl

# multimon-ng
RUN curl -L -o multimon.tar.gz https://github.com/EliasOenal/multimon-ng/archive/refs/tags/${MUTLIMON_NG_VERSION}.tar.gz && \
    tar xvzf multimon.tar.gz && \
    cd /multimon-ng-$MUTLIMON_NG_VERSION && \
    mkdir build && \ 
    cd build && \
    cmake .. && \
    make && \
    cp ./multimon-ng /usr/bin/multimon-ng

# rtl_433
RUN curl -L -o rtl_433.tar.gz https://github.com/merbanan/rtl_433/archive/refs/tags/${RTL_433_VERSION}.tar.gz && \
    tar xvzf rtl_433.tar.gz && \
    cd rtl_433-${RTL_433_VERSION} && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    cp src/rtl_433 /usr/bin/rtl_433

# scripts to static link everything
COPY scripts /scripts


# overwrite librtlsdr with the rtlsdr blog dribers
FROM builder as rtlsdrblogbuilder
ARG RTLSDRBLOG_TAG

RUN apt-get install libusb-1.0-0-dev git cmake pkg-config && \
    git clone --depth 1 --branch $RTLSDRBLOG_TAG https://github.com/rtlsdrblog/rtl-sdr-blog && \
    cd rtl-sdr-blog/ && \
    mkdir build && \
    cd build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON && \
    make && \
    make install && \
    cp ../rtl-sdr.rules /etc/udev/rules.d/ && \
    ldconfig

# rtl_433
RUN cd rtl_433-${RTL_433_VERSION} && \
    cd build && \
    cmake .. && \
    make && \
    cp src/rtl_433 /usr/bin/rtl_433

RUN /bin/bash /scripts/static.sh

FROM builder as builder-static
RUN /bin/bash /scripts/static.sh

FROM rtlsdrblogbuilder as rtlsdrblogbuilder-static

RUN /bin/bash /scripts/static.sh

FROM gcr.io/distroless/static-debian12 as librtlsdr

COPY --from=builder-static /static/* /bin

FROM gcr.io/distroless/static-debian12 as rtlsdrblog

COPY --from=rtlsdrblogbuilder-static /static/* /bin