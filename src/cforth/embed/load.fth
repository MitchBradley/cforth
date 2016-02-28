fload ../misc.fth
fload ../compiler.fth
fload ../control.fth

fload ../postpone.fth
\ fload ../dot.fth
fload ../size.fth
fload ../util.fth

\ fload ../buffer.fth
fload ../rambuffer.fth

fload ../config.fth

fload ../comment.fth	\ Multi-line comments

fload ../case.fth
fload ../th.fth
fload ../format.fth
fload ../words.fth
fload ../dump.fth
fload ../patch.fth

fload ../brackif.fth

patch where xwhere postpone

float? 0= ?\ : fpush ; : e. ; : (fliteral) ;
fload ../decompm.fth
fload ../decomp.fth
fload ../callfind.fth
fload ../needs.fth
fload ../sift.fth
fload ../stringar.fth
fload ../ccalls.fth
fload ../split.fth
fload ../rstrace.fth

fload aliases.fth

" forth.dic" save
