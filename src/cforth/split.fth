: lbsplit  ( l -- b.low b.lowmid b.highmid b.high )
   dup  h# ff and  swap   8 >>
   dup  h# ff and  swap   8 >>
   dup  h# ff and  swap   8 >>
        h# ff and
;
: wbsplit  ( l -- b.low b.high )
   dup  h# ff and  swap   8 >>
        h# ff and
;
: bljoin  (  b.low b.lowmid b.highmid b.high -- l )  8 << +  8 << +  8 << +  ;
: bwjoin  (  b.low b.high -- w )  8 << +  ;
