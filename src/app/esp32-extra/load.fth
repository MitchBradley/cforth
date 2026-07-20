fload basics.fth

fload rambuffer.fth

fload config.fth

fload brackif.fth	\ [IF] and friends

\ fload savefort.fth
fload case.fth
fload th.fth
fload stresc.fth
\  alias " s"    \ In case stresc.fth is omitted
fload format.fth
fload words.fth
fload dump.fth
fload patch.fth
\ fload brackif.fth
patch where xwhere postpone
float? ?\ fload floatops.fth
float? 0= ?\ : fpush ; : e. ; : (fliteral) ;
fload ansiterm.fth
fload double.fth	\ DOUBLE wordset
fload split.fth
fload decompm.fth
fload decomp2.fth
\ fload atxy.fth	\ AT-XY
\ fload decomp.fth
fload callfind.fth
fload needs.fth
fload sift.fth
fload strings.fth
fload stringar.fth
fload ccalls.fth
fload rstrace.fth

fload environ.fth

\ Some optional wordsets
\ fload page.fth	\ PAGE
fload marker.fth	\ MARKER
fload locals.fth	\ LOCALS

[ifdef] $command
fload cmdcom.fth
[then]
fload debug.fth

" forth.dic" save
