h# 20000 value dropin-offset

\ Use high addresses to avoid ITCM and DTCM alias regions
h# 800.0000 constant di-buffer
h# 900.0000 constant 'compressed
h# a00.0000 value workspace

: itcm-on   ( -- )  control@ h# 1000 or control!  ;  \ Enable ITCM
: itcm-off  ( -- )  control@ h# 1000 invert and control!  ;  \ Disable ITCM
: cforth>itcm  ( -- )  h# d100.0000 0 h# 8000 move  ;   \ Copy CForth into ITCM
: slow-inflate  ( comp-adr exp-adr -- exp-len )
   false workspace (inflate)
;
: fast-inflate  ( comp-adr exp-adr -- exp-len )
   itcm-on
   cforth>itcm
   false workspace " aiaa-i" drop  inflate-adr h# 7fff and  acall
   itcm-off
;
defer inflate ' fast-inflate to inflate
\ fast-inflate doesn't work yet; it returns an error code

[ifndef] $=
: $=  ( adr1 len1 adr2 len2 -- flag )
   rot over =  if   ( adr1 adr2 len2 )
      comp 0=       ( flag )
   else             ( adr1 adr2 len2 )
      3drop false   ( flag )
   then
;
[then]
: clip-name  ( adr len -- adr len' )  d# 16 min  ;
: di-name$   ( -- adr len )  di-buffer h# 10 + cscount clip-name  ;
: di-name=  ( adr len -- flag )  clip-name di-name$ $=  ;
: di-magic?  ( -- flag )  di-buffer 4  " OBMD" $=  ;
: drop-in-location  ( name$ -- data-offset base-len expanded-len )
   2>r                                 ( offset r: name$ )
   dropin-offset  begin                ( offset r: name$ )
      di-buffer h# 20 2 pick spi-read  ( offset )
      di-magic?                        ( offset more? )
   while                               ( offset )
      2r@ di-name=  if                 ( offset )
         2r> 2drop                     ( offset )
         h# 20 +                       ( data-offset )
         di-buffer h# 4 + be-l@        ( data-offset base-len )
         di-buffer h# c + be-l@        ( data-offset base-len expanded-len )
         exit                          ( -- data-offset base-len expanded-len )
      then                             ( offset )
      di-buffer 4 + be-l@ 4 round-up + ( offset' )
      h# 20 +                          ( offset' )
   repeat                              ( offset )
   ." Can't find dropin " 2r> type cr  ( )
   drop abort
;

: test-checksum  ( -- )
   'compressed di-buffer h# 4 + be-l@     ( adr len )
   byte-checksum                          ( sum )
   dup  di-buffer h# 8 + be-l@   <>  if   ( sum )
      ." !!! Dropin checksum mismatch !!!" cr         ( sum )
      ." Stored checksum: " di-buffer h# 8 + be-l@ .  ( sum )
      ."   Computed checksum: " .  cr                 ( )
      abort
   else
      drop
   then
;
variable drop-in-size
: load-drop-in  ( adr name$ -- )
   drop-in-location   ( adr offset base-len expanded-len )
   dup  if            ( adr offset base-len expanded-len )
      ." Reading ... "
      drop-in-size !           ( adr offset base-len )
      'compressed swap rot     ( adr compressed-adr base-len offset )
      spi-read                 ( adr )
      ." Checksumming ... "
      test-checksum            ( adr )
      ." Decompressing "
      'compressed swap inflate     ( inflated-len )
      drop-in-size @  <> abort" Inflated dropin was the wrong size"   ( )
      cr
   else                            ( adr offset base-len expanded-len )
      drop  tuck  drop-in-size !   ( adr base-len offset )
      spi-read                     ( )
   then                            ( )
;
