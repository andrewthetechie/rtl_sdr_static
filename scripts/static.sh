#!/bin/bash
cd /librtlsdr/build/src/
for file in rtl_adsb rtl_biast rtl_eeprom rtl_fm rtl_ir rtl_power rtl_raw2wav rtl_sdr rtl_tcp rtl_test rtl_udp rtl_wavestat rtl_wavestream
do
    staticx --strip $file /static/$file
done
