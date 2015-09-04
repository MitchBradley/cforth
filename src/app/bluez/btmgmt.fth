\ Bluetooth Management Interface
\ Requires Linux 3.11, tested with 3.18

-1 value btmgmt-fh

: btmgmt-open  ( -- )
   btmgmt-fh -1 <>  if  exit  then
   1 $80003  #31 socket  dup ?posix-err  to btmgmt-fh  \ 1 BTPROTO_HCI   $80000 SOCK_CLOEXEC  3 SOCK_RAW   #31 PF_BLUETOOTH
   pkt{ #31 pkt-w,   $ffff pkt-w,  3 pkt-w,  }pkt ( adr len )   \ AF_BLUETOOTH, HCI_DEV_NONE, HCI_CHANNEL_CONTROL
   swap btmgmt-fh bind  ?posix-err

;

: btmgmt-close  ( -- )
   btmgmt-fh -1 =  if  exit  then
   btmgmt-fh h-close-handle
   -1 to btmgmt-fh
;

\ Assigning LE functionality to the in-kernel bluetooth management will
\ persist until the next reboot.  It is required for secure-level to
\ have an effect on connection authentication/encryption on Linux.
: btmgmt-enable-le  ( -- )
   btmgmt-open
   pkt{ $d pkt-w, 0 pkt-w, 1 pkt-w, 1 pkt-b, }pkt
   btmgmt-fh h-write-file ?posix-err

   btmgmt-close
;
