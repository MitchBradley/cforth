\needs init-lcd fl rgblcd.fth

: i>seg    ( i -- col row )
   3 /mod  tuck 2* - abs $d + swap
;

\ Draw the spinner segment i (0 to 5)
: draw-spin  ( i -- )
   " /-"(a4)/-"(60)" drop over + c@        ( i spin-char )
   swap i>seg lcd-at lcd-char-mode lcd!
;

\ $a5 is a 'centered dot' character.
: draw-dot  ( i -- )
   i>seg lcd-at
   $a5 lcd-char-mode lcd!
;

0 value spin-pos
: init-spin ( -- )
   0 to spin-pos
   6 0  do  i draw-spin  loop
;

: spin-step ( -- )
   spin-pos draw-spin
   spin-pos 1+ 6 mod to spin-pos
   spin-pos draw-dot
;

: spin ( -- )
   init-spin
   begin
      spin-step
      #100 ms
   key?  until
;
