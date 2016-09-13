: gpt?  ( -- flag )
   sector-buf h# 1fe + le-w@  h# aa55  <>  if  false exit  then
   sector-buf h# 1c2 + c@ gpt-type =
;

\ Tasks:
\ Choose a partition based on part# and partition-name$
\ Set sector-offset, size-low, size-high, and partition-type

-1 value the-sector
: get-gpt-info  ( -- error? )
   1 read-hw-sector            ( )
   sector-buf gpt-magic comp  if  true exit  then
   \ XXX should verify CRC
   sector-buf d# 72 + le-x@ to partition-lba0
   sector-buf d# 80 + le-l@ to #gpt-partitions
   sector-buf d# 84 + le-l@ to /gpt-entry
   -1 to the-sector
   false
;
: read-gpt-sector  ( sector# -- )
   dup the-sector =  if  drop exit  then      ( sector# )
   dup to the-sector                          ( sector# )
   read-hw-sector
;

: select-gpt-partition  ( adr -- )
   dup gpt-blk0 x>u to sector-offset                 ( adr )
   gpt-#blks /sector xu*d to size-high  to size-low  ( )
;

: partition-name=  ( adr -- flag )
   d# 56 +                        ( utf16-name-adr )
   partition-name$  bounds  ?do   ( utf16-name-adr )
      dup w@  i c@  <>  if        ( utf16-name-adr )
         drop false unloop exit   ( -- false )
      then                        ( utf16-name-adr )
      wa1+                        ( utf16-name-adr' )
   loop                           ( utf16-name-adr )
   w@ 0=                          ( flag )
;

: >gpt-entry  ( n -- adr )
   /gpt-entry *             ( offset )
   /sector /mod             ( rem quot )
   partition-lba0 x>u +     ( rem sector# )
   read-gpt-sector          ( rem )
   sector-buf +             ( adr )
;
: nth-gpt-partition  ( n -- )
   1- >gpt-entry select-gpt-partition     ( )
;
: gpt-active?  ( adr -- flag )  d# 16 0 bskip  0<>  ;

: named-gpt-partition  ( -- )
   #gpt-partitions 0  ?do
      i >gpt-entry                ( adr )
      dup gpt-active?  if         ( adr )
         dup partition-name=  if  ( adr )
            select-gpt-partition  ( )
	    leave                 ( )
         then                     ( adr )
      then                        ( adr )
      drop                        ( )
   loop                           ( )
;
: gpt-map  ( -- )
   get-gpt-info  abort" Invalid GUID Partition Table"
   #part 1 >=  if
      #part nth-gpt-partition
   else
      named-gpt-partition
   then
;
