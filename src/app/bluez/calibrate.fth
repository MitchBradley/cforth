\ Calibration
: current-mode  ( -- n )
   ncontrol-handle notify-on
   " "(fe 0c)" ncontrol
   #200 $0c wait-ncontrol  if
      ." Can't read mode" cr
      -1
   else  ( adr len )
      drop c@
   then
   ncontrol-handle notify-off
;

\ The orientation codes (second and third bytes in little endian) are
\ 1 - Flex flat, component side down
\ 2 - Flex flat, component side up
\ 3 - Y axis points down
\ 4 - Y axis points up
\ 5 - Ring flat, tab up
\ 6 - Ring flat, tab down

: c@> dup c@ . ca1+ ;
: w>n $10 lshift $10 >>a ;
: w@> dup le-w@ w>n .d wa1+ ;

3 /w* buffer: gyro-buf
3 /w* buffer: accel-buf

: decode-bias-report  ( adr len -- )
   over c@  >r  1 /string  r>   ( adr' len' type )
   case
      0 of
         accel-buf swap cmove
         ." Accel biases: " accel-buf w@> w@> w@> cr  drop
         accel-buf  3 /w*  " AccelBiases" json-short-array
      endof
      1 of
         gyro-buf swap cmove
         ." Gyro biases: "  gyro-buf w@> w@> w@> cr  drop
         gyro-buf  3 /w*  " GyroBiases" json-short-array
      endof
      ( default - adr len type )
         ." Unrecognized bias report: " .x cdump cr
         0 \ Will be dropped by endcase
   endcase
;

: get-bias-report  ( -- )
   #4000 $12 wait-ncontrol  if
      -ncontrol
      true abort" No calibration response"
   then
   decode-bias-report
;

: wait-cal  ( -- )
   get-bias-report   \ Expecting accel bias report
   get-bias-report   \ Expecting gyro bias report
;

: cal-tab-up  ( -- )
   +ncontrol
   #50 ms
   " "(12 05 32 00)" ncontrol
   wait-cal
   -ncontrol
   drain-notifications
;

: cal-tab-down  ( -- )
   +ncontrol
   #50 ms
   " "(12 06 32 00)" ncontrol
   wait-cal
   -ncontrol
   drain-notifications
;

\needs w>n  : w>n  #16 lshift #16 >>a  ;
: @bias  ( adr -- adr' n )  dup wa1+ swap  le-w@ w>n  ;

: .f4  ( n*10000 -- )
   push-decimal
   dup abs u>d <# # # # # '.' hold # rot sign #>  ( adr len )
   type space ( )
   pop-base
;
: .fraction  ( n -- )  #10000 #8192 */  .f4  ;

: (.biases)  ( adr -- )  3 0  do  @bias .fraction  loop  drop  ;

: wait-motion  ( timeout -- true | adr len false )  motion6d-handle wait-handle  ;

: skip-some  ( -- )
   5 0  do
     #100 wait-motion  0=  if  2drop  then
   loop
;

: +motion6d  ( -- )   motion6d-handle notify-on  ;
: -motion6d ( -- )    motion6d-handle notify-off  ;

: .biases  ( -- )
   +motion6d
   skip-some
   #200 wait-motion  if
      ." Can't read motion" cr
   else  ( adr len )
      drop (.biases)
   then

   -motion6d
;

: b:  ( "name" -- )  c:  .biases  bt-disconnect  ;
: show-biases   ( 'bdaddr -- )
   (connect)  .biases  bt-disconnect
;
: biases
   begin
      new-nod?  if
         type space  ['] show-biases catch  if  bt-disconnect  then
         cr
      then
   key-quit?  until
;

#64 buffer: bhhb-buf
#64 buffer: biib-buf
0 value has-bhhb

: test-bist-done
   " NBST BIST Check" test-phase
   \ Units below a0e5e90005b0 don't have BHHB.
   \ And they might not even have read-tag!
   bdaddr bdaddr>flex#                ( flex# )
   $5b0 < if
      " skip, BDA < 5b0" test-progress exit
   then

   0 to has-bhhb
   'BHHB' read-tag 0=  if
      1 to has-bhhb
      bhhb-buf swap move
      " BIST OK" test-progress exit
   then

   " NBST: BIST not done!" test-fail
;

: test-bhhb ( -- )
   has-bhhb 0= if
      " MCAD skipped." test-progress exit
   then

   0
   3 0 do
      accel-buf i /w* + le-w@ w>n
      bhhb-buf i /l* + le-l@ - dup * +
   loop
   dup " adsse: %d" sprintf test-progress
   #2048000 > if
      " MCAD: new bias too different" test-fail
   then
;

: test-biib ( -- )
   0
   3 0 do
      accel-buf i /w* + le-w@ w>n dup *   ( total squared-accel-bias )
      +                                   ( total )
   loop
   dup " acsse: %d" sprintf test-progress
   #2048000 > if
      " MCAN: new bias too high" test-fail
   then
;

: test-motion
   " MCAL Calibrating" test-phase
   " sample MPU 2 secs" test-progress
   ['] cal-tab-down catch  if
      " MCAM: no msg" test-fail
   then
   " read result" test-progress
   'BIIB' read-tag if
      " MCAF: no results" test-fail
   then
   biib-buf swap move

   test-biib

   \ verify change from bhhb to biib is small enough.
   test-bhhb
   operator-delay
;
