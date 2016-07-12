\needs flash-backspin  fl download.fth

0 value backspin-handle
\ See https://msdn.microsoft.com/en-us/library/windows/desktop/ms645505(v=vs.85).aspx
\ for message box type values and return codes
0 constant mb-ok
1 constant mb-ok-cancel

1 constant mb-id-ok
2 constant mb-id-cancel

: choose-backspin-bin-file  ( -- a.filename )
   " Backspin Firmware Files"(00)backspin*.bin"(00 00)" drop
   choose-file
;

: fatal-error  ( msg$ -- )
   " Error" 2swap mb-ok message-box drop  bye
;
: gui-show-progress  ( offset -- )
   dup text-show-progress
   pb-show  key?  if  key drop  then
;
: gui-set-range  ( high low -- )
   2dup text-set-range  pb-set-range
;
: gui-show-phase  ( msg$ -- )
   2dup text-show-phase  pb-set-title
;

: setup-gui  ( -- )
   pb-start
   ['] gui-set-range      to set-progress-range
   ['] gui-show-progress  to show-progress
   ['] gui-show-phase     to show-phase
;

false value use-gui?
: use-gui  true to use-gui?  ;

: gui-flash-backspin  ( filename$ -- )

   ['] open-bin-file catch  if
      " Cannot open Backspin program file" fatal-error
   then   ( )

   use-gui?  if  setup-gui  then
   flash-backspin
   " Done" show-phase

   use-gui?  if  #2000 ms  pb-end  then
;

: program-backspin  ( -- )
   \ If index 1 can be opened there is more than one Backspin
   $4e4d 1 ft-open-com  ?dup  if  ( handle )
      close-com
      " Disconnect all Backspins"nexcept for the one to program" fatal-error
   then

   \ Try to open the only Backspin
   $4e4d 0 ft-open-com  to serial-ih
   serial-ih 0=  if
      " Please connect a Nod Backspin to program" fatal-error
   then

\   " Proceed?"
\   " Program the Backspin?"
\   mb-ok-cancel message-box mb-id-cancel =  if  bye  then

   choose-backspin-bin-file  ?dup  if  ( a.filename )
      cscount gui-flash-backspin
   then
   bye
;

" backspin-programmer.dic" save
