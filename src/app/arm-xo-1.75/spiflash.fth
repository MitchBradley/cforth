\   spi-cs-on   ( -- )  Starts an SPI transaction by asserting CS#
\   spi-cs-off  ( -- )  Ends an SPI transaction by deasserting CS#
\   spi-out   ( b -- )  Sends a byte on the SPI bus
\   spi-in    ( -- b )  Receives a byte from the SPI bus
\
\   spi-us   ( -- us )  Approximate time in uS to do an spi-out
\     This lets us optimize the SST chip's auto-increment write
\     sequence by avoiding unnecessary polls of the status register.
\     If the host SPI access mechanism is so slow that the write
\     is guaranteed to have finished, polling is superfluous.

\ At the bottom of this file, there is a list of supported SPI FLASH
\ chips and the commands that they implement.


h# 10000 constant /spi-eblock   \ Smallest erase block common to all chips
h#   100 constant /spi-page     \ Largest write for page-oriented chips

\ Every SPI transaction starts with the assertion CS followed by a command code

: spi-cmd  ( cmd -- )  spi-cs-on  spi-out  ;

\ For some commands, a 3-byte address follows the command code

: spi-adr  ( adr -- )
   lbsplit drop  spi-out  spi-out  spi-out
;

\ The SPI status register tells you when a write is done
\ Its bitmasks are:
\  01 - RO  BUSY (Write in progress)
\  02 - RO  Write enable latch
\  04 - RW  Block protect 0 (non volatile on some parts)
\  08 - RW  Block protect 1 (non volatile on some parts)
\  10 - RW  Block protect 2 (non volatile on some parts)
\  20 - RW  SST BP3 - not used on other parts
\  40 - R   SST: Auto-Address Increment in progress (not used on other parts)
\  80 - RW  Status register write disable (write once)

: spi-read-status  ( -- b )  5 spi-cmd  spi-in  spi-cs-off  ; \ READSTATUS

\ I'm not sure this delay is necessary, but the EnE code did it, so
\ I'm being safe.  The EnE code did 4 PCI reads of the base address
\ which should be around 800nS.  2 uS should cover it in case I'm wrong
: short-delay  ( -- )  2 us  ;

\ You have to write-enable before any command that modifes stuff
\ inside the part - writes, erases, status register writes
\ The write-enabled mode is mostly self-clearing; the exception
\ is the SST part's auto-increment-address write sequence

: spi-write-enable  ( -- )  6 spi-cmd  spi-cs-off  short-delay  ;
: spi-write-disable  ( -- ) 4 spi-cmd  spi-cs-off  short-delay  ;

\ You have to wait after any command that modifies stuff
\ inside the part - writes, erases, status register writes

: wait-write-done  ( -- timeout? )
   \ The Spansion part's datasheet claims that the only operation
   \ that takes longer than 500mS is bulk erase and we don't ever
   \ want to use that command

   d# 100000 0  do  \ 1 second at 10 us/loop
      spi-read-status 1 and 0=  if  unloop exit  then  \ Test WIP bit
      d# 10 us
   loop
   -1
;

\ Common start sequence for writes and erases - anything that
\ writes using an address.

: setup-spi-write  ( addr cmd -- )  spi-write-enable  spi-cmd spi-adr  ;

\ Common end sequence for writes, erases, status register writes

: stop-writing  ( -- )  spi-cs-off  wait-write-done  ;

\ Write status register - used to set lock bits

: spi-write-status  ( b -- )
   spi-write-enable
   1 spi-cmd  ( b ) spi-out  stop-writing
;

\ Erase a 64k block
: erase-spi-block  ( offset -- )  h# d8 setup-spi-write  stop-writing  ;

\ Write a single byte to the SPI FLASH
: spi-flash!  ( byte addr -- )
   2 setup-spi-write  ( byte ) spi-out  stop-writing
;

\ Figures out how many bytes can be written in one transaction,
\ subject to not crossing a 256-byte page boundary.

: left-in-page  ( len offset -- len offset #left )
   \ Determine how many bytes are left in the page containing offset
   /spi-page  over /spi-page 1- and -      ( adr len offset left-in-page )

   \ Determine the number of bytes to write in this transaction
   2 pick  min                  ( adr len offset r: #to-write )
;

\ Adjust address, length, and write offset by the number of
\ bytes transferred in the last action

: adjust  ( adr len offset #transferred -- adr+ len- offset+ )
   tuck +  >r  /string  r>
;

\ Determine if it's worthwhile to write; writing FF's is pointless
: non-blank?  ( adr len -- non-blank? )
   bounds  ?do
      i c@  h# ff  <>  if  true unloop exit  then
   loop
   false
;

\ Write within one SPI FLASH page.  Offset + len must not cross a page boundary

: write-spi-page  ( adr len offset -- )
   2 setup-spi-write                  ( adr len )
   bounds  ?do  i c@ spi-out  loop    ( )
   stop-writing
;

\ Write as many bytes as can be done in one operation, limited
\ by page boundaries, and adjust the parameters to reflect the
\ data that was written.  If the data that would be written is
\ all FFs, save time by not actually writing it.

: write-spi-some  ( adr len offset -- adr' len' offset' )
   left-in-page                    ( adr len offset #to-write )

   3 pick  over  non-blank?  if    ( adr len offset #to-write )
      3 pick  over  3 pick         ( adr len offset #to-write  adr #to-write offset )
      write-spi-page               ( adr len offset #to-write )
   then                            ( adr len offset #to-write )

   adjust                          ( adr' len' offset' )
;

\ Write data from the range adr,len to SPI FLASH beginning at offset
\ Does not erase automatically; you have to do that beforehand.

\ Estimated programming time in the serial case:
\ 1 SPI bytes = 2 serial bytes per programmed byte.
\ 115200 is about 10,000 serial/second, so about 5K programmed/second.
\ A bit over 3 minutes for 1 MiB, half that for a 512K load.

\ This version works for ST, Spansion, and Winbond parts,
\ all of which support multiple data bytes after command 2

: common-write  ( adr len offset -- )  \ And Spansion
   begin  over  while    ( adr len offset )
      write-spi-some     ( adr' len' offset' )
   repeat                ( adr 0 offset )
   3drop
;

\ This version is for SST parts, which use an auto-increment
\ address command for fast writing.  The SST part does not
\ require you to stop at 256-byte page boundaries.  The
\ sequence is:
\   ADcmd adr,adr,adr data0 data1   WAIT
\   ADcmd data0 data1  WAIT
\   ADcmd data0 data1  WAIT
\   ...
\   write-disable
\
\ WAIT can be any of:
\   a) Wait at least 10 uS
\   b) Poll the chip status register for the BUSY bit to clear
\   c) Hardware handshaking using the SO line (prior setup with cmd70)

\ Estimated programming time in the serial case:
\ 3 SPI bytes = 6 serial bytes per 2 programmed bytes, so 3 serial/programmed
\ 115200 is about 10,000 serial/second, so about 3K programmed/second.
\ About 5 minutes for 1 MiB, half that for a 512K load.

: sst-word  ( adr -- )
   dup c@ spi-out  1+ c@ spi-out
   spi-cs-off

   \ Optimization of waiting for programming to be done.  Tbp is 10 uS max.
   \ If it takes longer than that to send a command, there's no need to wait.
   \ The only case where polling the status register wins is if the access
   \ time is very fast.
   spi-us d# 10 <=  if
      spi-us  d# 3 <  if  wait-write-done  else  d# 10 us  then
   then
;
: sst-write  ( adr len offset -- )
   spi-write-enable
   h# ad spi-cmd  spi-adr     ( adr len )   \ Send address the first time
   2 round-up                 ( adr len' )
   over sst-word   2 /string  ( adr' len' ) \ Then two data bytes

   \ XXX this structure, while simple, makes it difficult to optimize
   \ out unnecessary writes of FF data.  Overall it might be better
   \ to pretend that the device has pages and use the same logic as
   \ for the page-oriented parts.

   \ On subsequent beats, send AD plus 2 data bytes
   bounds  ?do  h# ad spi-cmd i sst-word  2 +loop

   spi-write-disable
;

defer spi-reprogrammed  ( -- ) \ What to do when done reprogramming
' noop to spi-reprogrammed

defer write-spi-flash  ( adr len offset -- )

\ Read len bytes of data from the SPI FLASH beginning at offset
\ into the memory buffer at adr

: read-spi-flash  ( adr len offset -- )
   \ Fast read command - no point since host access is the bottleneck
   \ h# b spi-cmd spi-adr  0 spi-out    ( adr len )
   3 spi-cmd  spi-adr              ( adr len )
   bounds  ?do  spi-in i c!  loop  ( )
   spi-cs-off                      ( )
;

\ Verify the contents of SPI FLASH starting at offset against
\ the memory range adr,len .  Aborts with a message on mismatch.

: verify-spi-flash  ( adr len offset -- mismatch? )
   over alloc-mem >r                  ( adr len offset r: temp-adr )
   r@  2 pick  rot                    ( adr len temp-adr len offset r: temp-adr )
   flash-read                         ( adr len r: temp-adr )
   tuck  r@ swap comp                 ( len mismatch? r: temp-adr )
   r> rot free-mem                    ( mismatch? )
;

: jedec-id  ( -- b3b2b1)
   h# 9f spi-cmd spi-in spi-in spi-in  spi-cs-off  ( b1 b2 b3 )
   0 bljoin
;
: 90-id  ( -- b2b1 )
   h# 90 spi-cmd  0 spi-adr  spi-in  spi-in spi-cs-off
   bwjoin
;
: ab-id  ( -- b1 )
   h# ab spi-cmd  0 spi-adr  spi-in  spi-cs-off
;

\ Get the SPI FLASH ID and decode it to the extent that we need.
\ There are several different commands to get ID information,
\ and the various SPI FLASH chips support different subsets of
\ those commands.  The AB command seems to be supported by all
\ of them, so it's a good starting point.

: spi-identify  ( -- )
   ab-id   ( id )

   \ ST, Spansion, and WinBond all identify as 13
   \ For now, we only need to distinguish between if it's
   \ a common page-write part or the SST part with its
   \ unique auto-increment address writing scheme.
   case
      h# 13  of  ['] common-write  endof
      h# bf  of  ['] sst-write     endof
      h# 14  of
         ." The SPI FLASH ID reads as 14.  This is due to an infrequent hardware problem."  cr
         ." If you power cycle and try again, it will probably work the next time." cr
         abort
      endof
      ( default )  ." Unsupported SPI FLASH ID " dup .x  cr  abort
   endcase
   to write-spi-flash
   0 spi-write-status  \ Turn off write protect bits
;

\ Display a message telling what kind of part was found

: .spi-id  ( -- )
   ." SPI FLASH is "
   ['] write-spi-flash behavior  ['] sst-write  =  if
      ." SST"
   else
      ." type 13 - Spansion, Winbond, or ST"
   then
;

: spi-flash-write-enable  ( -- )  spi-start spi-identify  .spi-id cr  ;

: use-spi-flash-read  ( -- )  ['] read-spi-flash to flash-read  ;

\ Install the SPI FLASH versions as their implementations.
: use-spi-flash  ( -- )
   ['] spi-flash-write-enable  to flash-write-enable
   ['] spi-reprogrammed        to flash-write-disable
   ['] write-spi-flash         to flash-write
   ['] verify-spi-flash        to flash-verify
   ['] erase-spi-block         to flash-erase-block
   use-spi-flash-read          \ Might be overridden
   h# 10.0000  to /flash
   /spi-eblock to /flash-block
;
use-spi-flash

0 [if]
\ Command support by device
\ Numbers are #address_bytes, #dummy_bytes, #data_bytes
01   write SR          0 0 1   SST  ST  Spansion  WB
02   write byte        3 0 1+  SST1 ST  Spansion  WB
03   read byte         3 0 1+  SST  ST  Spansion  WB
04   write disable     0 0 0   SST  ST  Spansion  WB
05   read SR           0 0 1*  SST  ST  Spansion  WB
06   write enable      0 0 0   SST  ST  Spansion  WB
0b   read bytefast     3 1 1+  SST  ST  Spansion  WB
20   erase 4k          3 0 0   SST                WB
3b   read byte dualout 3 1 1+                     WB
50   ena write SR      0 0 0   SST
52   erase 32k         3 0 0   SST
60   erase all         0 0 0   SST
70   ena busy SO       0 0 0   SST  (For AAI mode)
80   dis busy SO       0 0 0   SST  (For AAI mode)
90   read id           3 0 1/2 SST                WB
9f   read jedec id     0 0 3   SST      Spansion  WB
ab   read id/relpdn    3 3 1+  SST  ST  Spansion1 WB
ab   release pdn       0 0 0        ST  Spansion
ad   AAI word pgm      3 0 2   SST
b9   deep power dn     0 0 0        ST  Spansion  WB
c7   erase all         0 0 0   SST  ST  Spansion  WB
d7   erase sector  PCM
d8   erase 64k         3 0 0   SST  ST  Spansion

SST:
http://www.sst.com/downloads/datasheet/S71296.pdf
SST jedec ID is BF 25 8e
SST returns BF 8e for read ID
page program takes typ 7*256 ~ 2ms
byte program takes typ 7 us max 10us
block erase takes typ 18ms 25ms
bulk erase takes typ 35ms max 50ms
block is 64K, but can also do 4K and 32K erase
BP2-0 are volatile, default to 1 on power up
BP3 is volatile, defaults to 0 on power up.  BP3 is don't care!

ST:
jedec ID not supported or at least not documented
0xAB signature (cmd ab, dummyx3, read) is 13
can program an entire page with cmd 2 by driving additional bytes
wrsr takes 5-15 ms
page program takes typ 1.4 max 5 ms
byte program takes typ 0.4 ms + Nx4us  max 5 ms
block erase takes typ 1s max 3s
bulk erase takes typ 10s max 20s
block is 64K
BP2-0 are non-volatile

Spansion:
http://www.spansion.com/datasheets/s25fl008a_00_b0_e.pdf
jedec ID is 1 2 13
0xAB signature is 13
can program an entire page with cmd 2 by driving additional bytes
Spansion returns 0 0 for read ID, 
page program takes typ 1.5ms max 3ms
byte program takes typ ???
block erase takes typ 0.5s max 3s
bulk erase takes typ 6s max 48s
block is 64K
BP2-0 are non-volatile

Winbond/NexFLASH:
jedec ID is EF 30 14
0xAB signature is 13
http://www.winbond-usa.com/products/Nexflash/pdfs/datasheets/W25X10-20-40-80.pdf
page program takes typ 1.5ms max 5ms
byte program takes typ ???
4k erase takes typ 150ms max 300ms
block erase takes typ 1s max 2s
bulk erase takes typ 10s max 20s
also has 4K chunks
block is 64K
BP2-0 are non-volatile
BP3 is top/bottom protect


Identification:
 AB start-cmd 0 do-cmd read1 end-cmd
   If the result is 13, its either spansion or st
   If the result is BF, its SST

If spansion or st, do
 9f start-cmd read1 read1 read1 end-cmd
   spansion returns 1 2 13
   st returns 0 0 0 I think
 But I'm not sure it matters because they are pretty compatible

[then]
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
