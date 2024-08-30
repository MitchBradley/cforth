marker sdcard.fth cr lastacf .name #19 to-column .( 28-08-2024 )

0 [if]

Notes:

1) For the best relayable results:
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


[then]

#5000 value sd_speed
  #33 value spics-gpio
  #25 value sclk-gpio
  #26 value mosi-gpio
  #27 value miso-gpio
 true value format_if_mount_failed

: .SDcard-settings ( - )
    base @ decimal
    cr ." SPIcard settings:"
    cr ." format_if_mount_failed:" format_if_mount_failed
          if ." TRUE" else ." FALSE" then
    cr ." cs-gpio  :" spics-gpio .
    cr ." clk-gpio :" sclk-gpio  .
    cr ." Mosi-gpio:" mosi-gpio  .
    cr ." Miso-gpio:" miso-gpio  .
    cr ." SD-speed :" sd_speed .
    base ! cr
;

: sd-mount ( - ior )
  spics-gpio gpio-is-output
  sclk-gpio  gpio-is-output
  mosi-gpio  gpio-is-output
  miso-gpio  gpio-is-input-pullup
  spics-gpio  sclk-gpio  miso-gpio  mosi-gpio  format_if_mount_failed  sd_speed
  mount-sd-card
;

0 [if] \ EG:

.SDcard-settings sd-mount .
s" /sdcard/" set-path

: make-test-file ( - )
  s" test.txt" w/o create-file .
  s" Hello 1  from test.txt on CDcard" 2 pick write-file .
  1 s>d 2 pick reposition-file  .
  s" Hello 2" 2 pick write-file .  close-file drop
  s" test.txt" w/o open-file .
  s" >" 2 pick write-file .  close-file drop
;

make-test-file \ Should show 6 zeros.

ls
cat  test.txt
\ Should show:>Hello 2 from test.txt on CDcard

sd-unmount
s" /spiffs/" set-path

[then]
