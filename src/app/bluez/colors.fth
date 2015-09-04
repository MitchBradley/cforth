\ Name colors.

: reset-letter-color
   .esc[ '3' (emit '9' (emit 'm' (emit
;

: bold-letter-color  ( color -- )
   \ sanitize color
   8 mod

   .esc[  '3' (emit  '0' + (emit
   ';' (emit '1' (emit
   'm' (emit
;

: color-name$  ( color -- adr len )
   case
      0 of " black"   endof
      1 of " red"     endof
      2 of " green"   endof
      3 of " yellow"  endof
      4 of " blue"    endof
      5 of " magenta" endof
      6 of " cyan"    endof
      7 of " white"   endof
      ( default ) " NOTCOLOR" rot
   endcase
;

: .color  ( color -- )
   dup bold-letter-color   ( color )
   ." [LED] "              ( color )
   color-name$ type        ( )
   \ back to plain
   reset-letter-color
;
