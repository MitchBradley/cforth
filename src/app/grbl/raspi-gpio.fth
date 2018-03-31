\ Detect button pushes on Raspberry Pi GPIO17

\needs $system$ fl ../bluez/system.fth

0 value gpio17-fid
: open-gpio17  ( -- )
   " /sys/class/gpio/gpio17/value" h-open-file to gpio17-fid
;

variable xfds  0 xfds !
variable wfds  0 wfds !
variable rfds  0 rfds !
2variable timeval  0 timeval !  #1000 timeval la1+ !

: gpio17-event?  ( ms -- pressed? )
   timeval la1+ !
   1 gpio17-fid lshift xfds !
   0 wfds !  0 rfds !
   timeval xfds wfds rfds gpio17-fid 1+ select  if  ( pressed? )
     0 0 gpio17-fid lseek drop  pad 10 gpio17-fid h-read-file  0>  if
        pad c@  '1' =
     else
        false
     then
   else
      false
   then
;
: setup-gpios  ( -- )
   open-gpio17
   gpio17-fid 0<  if
      " echo 17 >/sys/class/gpio/export" $system$ 2drop
      open-gpio17
      gpio17-fid 0<  abort" Can't open GPIO"
   then

   " raspi-gpio set 17 pu" $system$ 2drop
   " echo 1 >/sys/class/gpio/gpio17/active_low" $system$ 2drop
   " echo rising >/sys/class/gpio/gpio17/edge" $system$ 2drop
   begin  #100 gpio17-event?  0= until
;
