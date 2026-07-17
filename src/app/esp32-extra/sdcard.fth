marker sdcard.fth cr lastacf .name #20 to-column .( 21-03-2026 )

0 [if]

Notes:

1) For the best reliable results:
   I use a card holder with a level shifter.
   Start with a blank sd-card without any partition.
   It took about 2 minutes to make a partition and to format a 32 GB card

2) Possible Error:
E (282479) sdmmc_sd: sdmmc_init_sd_if_cond: send_if_cond (1) returned 0x108
E (282479) example: Failed to initialize the card (UNKNOWN ERROR).
Reboot the ESP32 then remove and place the SDcard again in the holder.

3) Corrupt files can be removed by placing the SDcard in a pc and delete them there.

4) For long file names:
Change in menuconfig: Component config > FAT Filesystem support > Long filename support in heap.

18-03-2026 adapted for IDF 5.5.1

About the host_id parameter:
Chip	SPI2_HOST	SPI3_HOST	Remark
ESP32		1	2		Both available
ESP32-C3	1	-		Only SPI2_HOST



[then]

#5000 value sd_speed  \ Just a slow, safe value. In one case I could use #26700
   #1 value spi_host
  #33 value spics-gpio
  #25 value sclk-gpio
  #26 value mosi-gpio
  #27 value miso-gpio

#7 to sclk-gpio  #6 to mosi-gpio   #5 to miso-gpio  #1 to spics-gpio \ ESP32C3 super mini

0 value spi-bus-init-done    true value format_if_mount_failed

: .SDcard-settings ( - )
    base @ decimal
    cr ." SD card settings:"
    cr ." spi_host :" spi_host .
    cr ." format_if_mount_failed:" format_if_mount_failed
          if ." TRUE" else ." FALSE" then
    cr ." cs-gpio  :" spics-gpio .
    cr ." clk-gpio :" sclk-gpio  .
    cr ." Mosi-gpio:" mosi-gpio  .
    cr ." Miso-gpio:" miso-gpio  .
    cr ." SD-speed :" sd_speed .
    base ! cr
;

: init-spi-bus ( mosi miso clk host max_transfer  -- )
    spi-bus-init-done 0= if
      spi-bus-init abort" spi-bus-init  failed"  true to  spi-bus-init-done
   then
;

: sd-mount ( - hndl )
  spics-gpio gpio-is-output
  sclk-gpio  gpio-is-output
  mosi-gpio  gpio-is-output
  miso-gpio  gpio-is-input-pullup
  #4096 spi_host mosi-gpio  miso-gpio  sclk-gpio init-spi-bus  
\ C(sd_mount)             //c mount-sd-card    \    { i.cs i.format_if_fail i.speed_khz i.host -- i.ior }  
  spics-gpio   format_if_mount_failed  sd_speed spi_host
  mount-sd-card
;

: esp-32 ( - ) s" /esp-32/" set-path ;
: sdcard ( - ) s" /sdcard/" set-path ;

0 [if] \ EG:

0 value sd-hndl

.SDcard-settings sd-mount to sd-hndl

s" /sdcard/" set-path

: make-test-file ( - )
  s" test.txt" w/o create-file .
  s" Hello 1  from test.txt on SDcard" 2 pick write-file .
  1 s>d 2 pick reposition-file  .
  s" Hello 2" 2 pick write-file .  close-file drop
  s" test.txt" w/o open-file .
  s" >" 2 pick write-file .  close-file drop
;

make-test-file \ Should show 6 zeros.

ls
cat  test.txt
\ Should show:>Hello 2 from test.txt on SDcard

 sd-hndl sd-unmount drop

   
\ spi-free: Only when the bus is not needed anymore   0= skip spi_bus_remove_device   
0  spi_host spi-free drop 0 to spi-bus-init-done 

s" /esp-32/" set-path

[then]
