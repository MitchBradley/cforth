0 value numfont-#chars
0 value numfont-width
0 value numfont-height

: pixels>bytes  ( pix -- bytes )  7 + 8 /  ;
: >glyph  ( n 'font -- adr )
   swap numfont-width *  numfont-height pixels>bytes *  +
;

: drawnum  ( 0-9 'font -- )
   >glyph
   line# line#>page  numfont-height pixels>bytes  bounds  ?do  ( adr )
      column# numfont-width *  ssd-set-col  ( adr )
      i ssd-set-page                        ( adr )
      ssd-ram{                              ( adr )
      numfont-width 0  ?do                  ( adr )
         dup c@ ssd-ram!                    ( adr )
         ca1+                               ( adr' )
      loop                                  ( adr )
      }ssd-ram                              ( adr )
  loop                                      ( adr )
  drop                                      ( )
;

: @+  ( adr -- adr' n )  dup cell+  swap @  ;
: (ssd-font)  ( n 'font -- )
   @+ to numfont-#chars
   @+ to numfont-height
   @+ to numfont-width  ( 0..9 adr )
   drawnum
;
: ssd-font: ( "name" width height #chars -- )
   create  ( width height #chars )
   dup to numfont-#chars ,
   dup to numfont-height ,
   dup to numfont-width  ,
   does>  ( 0..9 adr )
   (ssd-font)
;

: getnum  ( -- )
  begin
     parse-word  dup 0=  ( adr len flag )
  while                  ( adr len )
     2drop               ( adr len )
     refill 0= abort" end of file"
  repeat                 ( adr len )
  $number?  0= abort" Bad number" drop
;

: glyph  ( n -- )
   drop
   push-hex
   numfont-height pixels>bytes  numfont-width * 0  do  getnum c,  loop
   pop-base
;

