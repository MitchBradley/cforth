\ CRC-16 table
base @ hex
create crctab
    0000 w,  1021 w,  2042 w,  3063 w,  4084 w,  50a5 w,  60c6 w,  70e7 w,
    8108 w,  9129 w,  a14a w,  b16b w,  c18c w,  d1ad w,  e1ce w,  f1ef w,
    1231 w,  0210 w,  3273 w,  2252 w,  52b5 w,  4294 w,  72f7 w,  62d6 w,
    9339 w,  8318 w,  b37b w,  a35a w,  d3bd w,  c39c w,  f3ff w,  e3de w,
    2462 w,  3443 w,  0420 w,  1401 w,  64e6 w,  74c7 w,  44a4 w,  5485 w,
    a56a w,  b54b w,  8528 w,  9509 w,  e5ee w,  f5cf w,  c5ac w,  d58d w,
    3653 w,  2672 w,  1611 w,  0630 w,  76d7 w,  66f6 w,  5695 w,  46b4 w,
    b75b w,  a77a w,  9719 w,  8738 w,  f7df w,  e7fe w,  d79d w,  c7bc w,
    48c4 w,  58e5 w,  6886 w,  78a7 w,  0840 w,  1861 w,  2802 w,  3823 w,
    c9cc w,  d9ed w,  e98e w,  f9af w,  8948 w,  9969 w,  a90a w,  b92b w,
    5af5 w,  4ad4 w,  7ab7 w,  6a96 w,  1a71 w,  0a50 w,  3a33 w,  2a12 w,
    dbfd w,  cbdc w,  fbbf w,  eb9e w,  9b79 w,  8b58 w,  bb3b w,  ab1a w,
    6ca6 w,  7c87 w,  4ce4 w,  5cc5 w,  2c22 w,  3c03 w,  0c60 w,  1c41 w,
    edae w,  fd8f w,  cdec w,  ddcd w,  ad2a w,  bd0b w,  8d68 w,  9d49 w,
    7e97 w,  6eb6 w,  5ed5 w,  4ef4 w,  3e13 w,  2e32 w,  1e51 w,  0e70 w,
    ff9f w,  efbe w,  dfdd w,  cffc w,  bf1b w,  af3a w,  9f59 w,  8f78 w,
    9188 w,  81a9 w,  b1ca w,  a1eb w,  d10c w,  c12d w,  f14e w,  e16f w,
    1080 w,  00a1 w,  30c2 w,  20e3 w,  5004 w,  4025 w,  7046 w,  6067 w,
    83b9 w,  9398 w,  a3fb w,  b3da w,  c33d w,  d31c w,  e37f w,  f35e w,
    02b1 w,  1290 w,  22f3 w,  32d2 w,  4235 w,  5214 w,  6277 w,  7256 w,
    b5ea w,  a5cb w,  95a8 w,  8589 w,  f56e w,  e54f w,  d52c w,  c50d w,
    34e2 w,  24c3 w,  14a0 w,  0481 w,  7466 w,  6447 w,  5424 w,  4405 w,
    a7db w,  b7fa w,  8799 w,  97b8 w,  e75f w,  f77e w,  c71d w,  d73c w,
    26d3 w,  36f2 w,  0691 w,  16b0 w,  6657 w,  7676 w,  4615 w,  5634 w,
    d94c w,  c96d w,  f90e w,  e92f w,  99c8 w,  89e9 w,  b98a w,  a9ab w,
    5844 w,  4865 w,  7806 w,  6827 w,  18c0 w,  08e1 w,  3882 w,  28a3 w,
    cb7d w,  db5c w,  eb3f w,  fb1e w,  8bf9 w,  9bd8 w,  abbb w,  bb9a w,
    4a75 w,  5a54 w,  6a37 w,  7a16 w,  0af1 w,  1ad0 w,  2ab3 w,  3a92 w,
    fd2e w,  ed0f w,  dd6c w,  cd4d w,  bdaa w,  ad8b w,  9de8 w,  8dc9 w,
    7c26 w,  6c07 w,  5c64 w,  4c45 w,  3ca2 w,  2c83 w,  1ce0 w,  0cc1 w,
    ef1f w,  ff3e w,  cf5d w,  df7c w,  af9b w,  bfba w,  8fd9 w,  9ff8 w,
    6e17 w,  7e36 w,  4e55 w,  5e74 w,  2e93 w,  3eb2 w,  0ed1 w,  1ef0 w,
base !

: updcrc  ( crc c -- crc' c )
   dup rot            ( c c crc )
   wbsplit  >r        ( c c low r: high )
   bwjoin             ( c low|c r: high )
   crctab  r> wa+ w@  ( c low|c table-entry )
   xor swap           ( crc' c )
;

: crc-send  ( crc adr len -- crc' )
   bounds  ?do  i c@ updcrc m-emit  loop
;

\ Assumes 0<len<64K
: crc-receive  ( crc adr len timeout -- true | crc' false )
   timer-init !
   bounds  ?do  timed-in  if  drop true unloop  exit  then  i c!  loop
;

: checksum-send  ( sum adr len -- sum' )
   bounds ?do  i c@ dup m-emit  +  loop
;

\ : tm  " This is a dadgum test"n"  ;
\ : t 0  tm  bounds  ?do  i c@ updcrc drop  loop  u.  ;
