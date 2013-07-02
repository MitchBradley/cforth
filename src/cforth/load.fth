fload basics.fth

fload buffer.fth
fload compat.fth

fload config.fth

fload brackif.fth	\ [IF] and friends

\ fload savefort.fth
fload case.fth
fload th.fth
fload format.fth
fload words.fth
fload dump.fth
fload patch.fth
patch where xwhere postpone
float? ?\ fload floatops.fth
float? 0= ?\ : fpush ; : e. ; : (fliteral) ;
fload decompm.fth
fload decomp.fth
fload callfind.fth
fload id.fth
fload needs.fth
fload sift.fth
fload stringar.fth
fload ccalls.fth

fload environ.fth

\ Some optional wordsets
fload double.fth	\ DOUBLE wordset
fload atxy.fth	\ AT-XY
fload page.fth	\ PAGE
fload marker.fth	\ MARKER
fload locals.fth	\ LOCALS

[ifdef] $command
fload cmdcom.fth
[then]
