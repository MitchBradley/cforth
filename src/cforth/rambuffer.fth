\ buffer: that is compatible with ROM dictionaries

\ Use this version for buffers of modest size
\ : buffer:  ( n -- )  /n round-up ualloc user  ;

/n constant /user#

nuser buffer-link
0  buffer-link !

: user#,  ( size -- adr )
   #user @ dup ,     ( size user# )
   swap #user +!     ( user# )
   up@ +
;
: make-buffer  ( size -- )
   here body> swap     ( acf size )
   0 /n user#,  !      ( acf size )
   ,                   ( acf )
   buffer-link link@  link,  buffer-link link!
;

: alloc-mem4  ( len -- adr )  4 +  alloc-mem  4 round-up  ;

: do-buffer  ( apf -- adr )
   dup >user @  if          ( apf )
      >user @               ( adr )
   else                     ( apf )
      dup /user# + @        ( apf size )
      dup alloc-mem4        ( apf size adr )
      dup rot erase         ( apf adr )
      dup rot >user !       ( adr )
   then
;
: (buffer:)  ( size -- )
   create-cf  make-buffer  does> do-buffer
;

: buffer:  \ name  ( size -- )
   header (buffer:)
;

: >buffer-link ( acf -- link-adr )  >body /user# + 1 na+  ;

: clear-buffer:s ( -- )
   buffer-link                         ( next-buffer-word )
   begin  another-link?  while         ( acf )
      dup >body  >user  off            ( acf )
      >buffer-link                     ( prev-buffer:-acf )
   repeat                              ( )
;
warning @  warning off
: save  ( adr len -- )  clear-buffer:s save  ;
warning !

: .buffers ( -- )
   buffer-link                         ( next-buffer-word )
   begin  another-link?  while         ( acf )
      dup .name
      dup >body /user# + @ . cr
      >buffer-link                     ( prev-buffer:-acf )
   repeat                              ( )
;
