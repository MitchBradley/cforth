marker -i2c.fth lastacf .name #20 to-column .( 30-04-2026 )

0 [if]

It uses the new I2C API. The functions handle the entire transaction (START, data, STOP) and always issue a STOP-bit.
By always concluding a transaction with a STOP condition, the bus is properly released. 
This prevents hangs and ensures predictable behavior for other devices on the same bus.
Slave addresses need to be unique for each device even when multiple buses are used.
i2c-open has been replaced by:  i2c-open-device ( scl sda #slave speed -- device-handle )  

[then]

\ Number of devices reserved
8 value #i2c-max-devices     \ increase when needed.

\ Default bus parameters
variable i2c-pullup true i2c-pullup !
variable i2c-glitch 7 i2c-glitch !

\ Default device parameters
variable i2c-speed #100000 i2c-speed !  
variable i2c-tenbit 0 i2c-tenbit !
variable i2c-wait 0 i2c-wait !
      
variable i-new-data 0 i-new-data !
variable i2c-bus-handle 0  i2c-bus-handle ! \ 0 indicates a new bus-handle is needed to store in &i2c-devices 

#128 constant #i2c-indexes \ Do not change.   
2 cells 2 + constant /i2c-device     
#i2c-indexes cells buffer: &i2c-indexes \ Contains pointers to the following i2c-devices
#i2c-max-devices /i2c-device * buffer: &i2c-devices \ Map: &i2c-dev-handle,  i2c-bus-handle, SDA-byte, SCL-byte

: >i2c-device      ( c-index - &i2c-dev ) /i2c-device * &i2c-devices + ;
: >i2c-index       ( slave - &c-index ) &i2c-indexes + ;
: >&i2c-dev-handle ( &i2c-dev - &i2c-dev-handle ) ; immediate
: >i2c-bus-handle  ( &i2c-dev - &i2c-bus-handle-ptr ) cell+ ;
: >sda-byte        ( &i2c-dev - &sda-byte ) 2 cells+ ;
: >scl-byte        ( &i2c-dev - &scl-byte ) 9 + ;

: i2c-default-parms-device (  slave bus-handle -  bus-handle i2c-tenbit slave i2c-speed i2c-wait ) 
   i2c-tenbit @ rot i2c-speed @ i2c-wait @ ;

: .i2c-dump-header ( -- )  cr ." c-index link-adr dev-hndl bus-hndl sda scl" ;

: .i2c-dev ( c-index -- ) 
   base @ swap hex dup . 
   >i2c-device dup .
   dup >&i2c-dev-handle  ?  
   dup >i2c-bus-handle ? 
   dup >sda-byte c@ .
   >scl-byte c@ dup 0> if 
      space 
   then 
   . base ! 
;      
: .i2c-dump ( - )
   .i2c-dump-header #i2c-max-devices 0 do
      cr 6 spaces i .i2c-dev         
   loop
;
: get-latest-bushandle ( pullup/down scl sda - bushandle )
   i2c-bus-handle dup @ 0= if 
      >r i2c-glitch @ i2c-bus-init dup r> ! 
   else  
      nip nip nip @ 
   then
;
: get-device-handle ( slave - device-handle )
   >i2c-index c@ >i2c-device @
;

: i2c-open ( Scl Sda - ) cr 2drop ." Use i2c-open-device instead of i2c-open. See i2c.fth" quit ;
  
: i2c-open-device ( scl sda #slave -- device-handle )  
   #i2c-max-devices  i-new-data @ < abort" i2c tabel full, increase #i2c-max-devices." 
   dup here ! 
   >i2c-index i-new-data @ swap c! 2dup \ store the index byte
   i-new-data @ >i2c-device  dup >r >scl-byte c! 
   r@ >sda-byte c! 
   i2c-pullup @ -rot get-latest-bushandle dup 0= abort" i2c-open failed" dup i2c-bus-handle !
   dup i-new-data @ >i2c-device  >i2c-bus-handle !    
   here @ swap i2c-default-parms-device i2c-device-add dup
   r> ! \ store device handle   
   1 i-new-data +! \ next free entry
;
: i2c-close ( slave -- ) 
   >i2c-index c@ >i2c-device dup @ i2c-device-delete 0 swap ! 
;
: i2c-bus-close ( slave -- ) 
   >i2c-index c@ >i2c-device >i2c-bus-handle dup @ i2c-bus-delete  0 swap ! 
;
: be->le ( n -- n' ) dup $FF and 8 lshift swap 8 rshift or ;
: i2c-b! ( value reg slave -- error? ) get-device-handle i2c-master-write-byte  ;
: i2c-b@ ( reg slave stop -- byte ) drop get-device-handle i2c-master-read-byte ;
: i2c-be-w@ ( register slave stop -- BigEndian ) drop get-device-handle i2c-master-read-word ;
: i2c-le-w@ ( register slave stop -- LittleEndian ) i2c-be-w@ be->le ;
: i2c-be-w! ( i.value reg slave -- error? ) get-device-handle i2c-master-write-word ;
: i2c-le-w! ( value reg slave -- Error? ) >r rot be->le -rot r> i2c-be-w! ;
: i2c-write-read  ( &wbuf wsize &rbuf rsize slave stop - err )
   drop get-device-handle i2c-master-write-read  
;
\ \s
