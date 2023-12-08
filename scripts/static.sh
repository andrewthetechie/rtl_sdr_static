#!/bin/bash
cd /librtlsdr/build/src/
RTL_FILES="rtl_adsb rtl_biast rtl_eeprom rtl_fm rtl_ir rtl_power rtl_raw2wav rtl_sdr rtl_tcp rtl_test rtl_udp rtl_wavestat rtl_wavestream"
for file in $RTL_FILES
do
    staticx --strip $file /static/$file
done

SUPPORTING_FILES="tee nc socat filan procan multimon-ng rtl_433 direwolf sh"
for file in $SUPPORTING_FILES
do
    staticx --strip /usr/bin/$file /static/$file
done