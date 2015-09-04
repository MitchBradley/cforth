\ XXX check the list of environment queries against the current spec

vocabulary environment  environment definitions

#align constant /align
1 chars constant /char
td 255 constant /counted-string
64\  h# 40000
32\  h# 20000
16\  d# 45000
constant /data-space
d# 100 constant /hold
: /pad  origin /data-space +  pad -  ;
d# 132 constant /tib
8 constant address-unit-bits
\ true constant block
\ false constant block-ext
true constant core
true constant core-ext
true constant double
true constant double-ext
true constant file
true constant file-ext
true constant floating
true constant floating-ext
d# 20 constant floating-stack
true constant full
true constant locals
true constant locals-ext	\ ???
\ ?? constant max-float
32\ h# 7fffffff
16\ h#     7fff
constant max-n
32\ h# ffffffff
16\ h#     ffff
constant max-u
max-u max-n constant max-d
max-u max-u constant max-ud
true constant memory-alloc
false constant memory-alloc-ext		\ ???
d# 100 constant return-stack-cells
true constant search-order
true constant search-order-ext
d# 100 constant stack-cells
true constant string
true constant string-ext
\ ?? constant wordlists

forth definitions

: environment?  ( c-addr u -- false | value true )
   ['] environment  search-wordlist  if  execute true  else  false  then
;
