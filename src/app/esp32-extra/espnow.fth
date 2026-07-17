marker -espnow.fth lastacf .name #20 to-column .( 12-05-2026 ) \ By J.v.d.Ven

#10 constant espnow-overhead \ macadress + count string
#1470 constant max-payload   \ V2

0 value &esp-now-receive-buffer   
0 value &esp-now-data-buffer

\ To all receivers:
create to_all_mac  $FF c, $FF c, $FF c, $FF c, $FF c, $FF c,

\ The first field of &Buffer-Received points to the macadress of the sender. 
: >&CountPayload  ( &Buffer-Received - &CountPayload ) #6 + ; 
  
: .macadress ( &macadress - ) 
   base @ hex swap 5 0 do  
      dup i + c@ (.) type [char] . emit 
   loop 
   5 + c@ . base !
;
: init-esp-receiver ( channel size-buffers - )
   espnow-overhead + [ max-payload espnow-overhead - ] literal min
   dup allocate drop to &esp-now-data-buffer
   allocate drop dup to &esp-now-receive-buffer
   esp-now-open-receiver abort" esp-now-open-receiver failed"
;
: esp-now-read ( - &esp-now-data-buffer|0 )
   esp-now-listen if
      esp-now-get-data dup >&CountPayload @ 
      espnow-overhead + &esp-now-data-buffer swap cmove
      esp-now-release-buffer &esp-now-data-buffer
   else
      false
   then
;
\ \s

