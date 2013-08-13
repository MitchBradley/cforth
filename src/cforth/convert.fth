\ Convert digit characters from addr1, accumulating into ud1,
\ returning result 'ud2' and address of first non-digit 'addr2'
\ CONVERT is obsolescent; >NUMBER is preferred 

: convert  (s ud1 addr1 -- ud2 addr2 )
   begin                             ( ud addr )
      1+  dup  >r                    ( ud addr+1 ) ( r: addr+1 )
      c@  base  @  digit             ( ud digit flag )
   while                             ( ud digit )
      swap base @ um* drop           ( ud.hi digit int1.hi )
      rot  base @ um*                ( digit int1.hi int2.lo int2.hi )
      d+                             ( ud' )
      dpl @ 0>=  if  1 dpl +!  then  ( ud' )
      r>                             ( ud' addr+1 )
   repeat                            ( ud digit ) ( r: addr+n )
   drop  r>
;
