: lbsplit  ( l -- b.low b.lowmid b.highmid b.high )
   dup  h# ff and  swap   8 >>
   dup  h# ff and  swap   8 >>
   dup  h# ff and  swap   8 >>
        h# ff and
;
: wbsplit  ( w -- b.low b.high )
   dup  h# ff and  swap   8 >>
        h# ff and
;
: lwsplit  ( l -- w.low w.high )
   dup  h# ffff and  swap   #16 >>
        h# ffff and
;
: bljoin  (  b.low b.lowmid b.highmid b.high -- l )  8 << +  8 << +  8 << +  ;
: bwjoin  (  b.low b.high -- w )  8 << +  ;
: wljoin  ( w.low w.high -- l )  #16 lshift or  ;
