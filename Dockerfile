from ubuntu:20.04 as builder
ARG LIBRTLSDR_TAG=master
ARG IONOSPHERE_VERSION=v1.0.3

ENV TZ=America/Chicago
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -y build-essential cmake git libusb-dev libusb-1.0-0-dev

RUN git clone --depth 1 --branch $LIBRTLSDR_TAG https://github.com/librtlsdr/librtlsdr.git
RUN cd /librtlsdr && mkdir build && cd build && cmake ../ && make && cd src && mkdir /static
RUN apt-get install -y binutils patchelf build-essential scons upx
RUN apt-get install -y python3 python3-pip && pip install --no-warn-script-location --upgrade virtualenv pip poetry pyinstaller staticx

RUN apt-get install -y socat

COPY scripts /scripts
RUN /bin/bash /scripts/static.sh

# FROM gcr.io/distroless/static-debian12

# COPY --from=builder /static/* /bin
