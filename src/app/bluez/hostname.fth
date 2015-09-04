
\ Routines for reading the hostname.

#16 buffer: hostname-buf

: hostname  ( -- adr len )
   " /etc/hostname" r/o open-file
   abort" Can't open /etc/hostname"      ( handle )
   hostname-buf #16 rot read-file
   abort" Error reading hostname file"   ( name-len )
   \ strip trailing newline
   1 - hostname-buf swap                 ( name-buf name-len )
;
