from ubuntu:20.04 as builder
ARG LIBRTLSDR_TAG=master
ARG MUTLIMON_NG_VERSION=1.3.0

ENV TZ=America/Chicago
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -y build-essential cmake git libusb-dev libusb-1.0-0-dev

RUN git clone --depth 1 --branch $LIBRTLSDR_TAG https://github.com/librtlsdr/librtlsdr.git
RUN cd /librtlsdr && mkdir build && cd build && cmake ../ && make && cd src && mkdir /static
RUN apt-get install -y binutils patchelf build-essential scons upx
RUN apt-get install -y python3 python3-pip && pip install --no-warn-script-location --upgrade virtualenv pip poetry pyinstaller staticx

RUN apt-get install -y socat curl
RUN curl -L -o multimon.tar.gz https://github.com/EliasOenal/multimon-ng/archive/refs/tags/$MUTLIMON_NG_VERSION.tar.gz && \
    tar xvzf multimon.tar.gz && \
    cd /multimon-ng-$MUTLIMON_NG_VERSION && \
    mkdir build && \ 
    cd build && \
    cmake .. && \
    make && \
    cp ./multimon-ng /usr/bin/multimon-ng

COPY scripts /scripts
RUN /bin/bash /scripts/static.sh

FROM gcr.io/distroless/static-debian12

COPY --from=builder /static/* /bin
