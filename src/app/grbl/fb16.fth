\ Simple driver for 320x240x16 frame buffer

#320 constant width
#240 constant height
width height *  2*  constant /fb

0 value fb-ih
0 value fb-adr
: open-fb  ( -- )
   fb-ih  0>  if  exit  then
   " /dev/fb1" h-open-file to fb-ih
   fb-ih 0< abort" Can't open display"
   0 /fb fb-ih mmap to fb-adr
;
: wfill  ( adr len w -- )
   -rot
   bounds  ?do  dup i w!  /w +loop
   drop
;
: fill-fb  ( color -- )  fb-adr /fb rot wfill  ;

$0000 constant black16
$f800 constant red16
$07c0 constant green16
$003f constant blue16
red16 blue16 or constant magenta16
red16 green16 or constant yellow16
green16 blue16 or constant cyan16
red16 blue16 or green16 or constant white16


: fb-red  ( -- )  red16 fill-fb  ;
: fb-blue  ( -- )  blue16 fill-fb  ;
: fb-green ( -- )  green16 fill-fb  ;
: fb-black  ( -- )  black16 fill-fb  ;
: fb-white  ( -- )  white16 fill-fb  ;
: fb-cyan  ( -- )  cyan16 fill-fb  ;
: fb-magenta  ( -- )  magenta16 fill-fb  ;
: fb-yellow  ( -- )  yellow16 fill-fb  ;
