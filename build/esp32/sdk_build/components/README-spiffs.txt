The spiffs code was cloned from

https://github.com/loboris/ESP32_spiffs_example.git

The code therein includes a verbatim copy of upstream
spiffs code https://github.com/pellepl/spiffs.git
as of the 5/25/2017, plus configuration files and VFS
interfaces suitable for ESPS32.

The verbatim SPIFFS files are, in components/spiffs/:

spiffs.h
spiffs_cache.c
spiffs_check.c
spiffs_gc.c
spiffs_hydrogen.c
spiffs_nucleus.c
spiffs_nucleus.h

The rest of the files in that directory are ESP32-specific.

../partitions.csv includes a spiffs partition and ../sdkconfig
is configured to use it, via CONFIG_PARTITION_TABLE_CUSTOM .
