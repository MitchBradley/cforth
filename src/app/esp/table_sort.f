marker -table_sort.f


0 [IF]

A flexible shellsort.

Testet under Cforth, Win32forth and Gforth.

 Characteristics:
 This version uses relative as pointers. So there is no need
 to generate the same pointers again when they are saved in a file.
 Multiple keys can be used and sorted in one go.
 The number of keys is only limited by the unused size of the stack.
 Each key can be sorted in an ascending or descending way.
 A key may contain a number or a string.
 The sort is case-sensitive for stings.
 Easy to expand to sort doubles etc.
 Multiple tables can be sorted without causing conflicts.

 Tested under Win32Forth Cforth and Gforth.
 Gforth under Linux and Win32Forth are able to sort different tables parallel.
 NOTES: In Win32Forth a source must contain Windows Line endings.

 When mapped files are used:
 1.The table and the pointers must be mapped.
 2.Minimum file size of the table must be 1 byte.
 3.When the table is resized, the table and it's pointers must be re-mapped.
   The pointers must also be re-build.

[THEN]



s" gforth" ENVIRONMENT? [IF] 2drop

: cells+  ( a1 n1 -- a1+n1*cell )      s" cells + "     evaluate ; immediate
: +cells  ( n1 a1 -- n1*cell+a1 )      s" swap cells+ " evaluate ; immediate
: f2dup   ( fs: r1 r2 -- r1 r2 r1 r2 ) s" fover fover " evaluate ; immediate
: f2drop  ( fs: r1 r2 -- )             s" fdrop fdrop " evaluate ; immediate
: dup>r   ( n1 -- n1 ) ( R: -- n1 )    s" dup >r"       evaluate ; immediate
: dms@    ( -- d: u )  utime 1 1000 m*/ ;
: ms@     ( -- ms ) dms@  drop ;

[THEN]

s" cforth" ENVIRONMENT? [IF] drop \ Extended version, may be loaded in ROM
cr lastacf .name #19 to-column .( 30-06-2023 ) \ By J.v.d.Ven

needs /circular      ../esp/extra.fth \ Assuming extra.fth is in ROM
alias >table-aptrs cell+
alias &key-len     cell+

[ELSE]

' cell+ alias >table-aptrs ( &table - &list-adress-pointers )
' cell+ alias &key-len     ( key - &key-len )
: >record-size             ( &table - &size-records )   2 cells+ ;

[THEN]


\ Adressing the table properties:

4 cells value /table        \ The minimal needed size incl. 0

: init-table                ( /table - &table ) dup allocate throw tuck swap erase ;
\ : >record-list            ( &table - &list-records ) ; immediate
\ >table-aptrs              ( &table - &list-adress-pointers ) cell+ ; \ Forth-depended defined
\ : >record-size            ( &table - &size-records )   2 cells+ ;    \ Forth-depended defined
: >#records                 ( &table - &number-records ) 3 cells+ ;
: table-size                ( &table - #bytes ) dup >#records @ swap >record-size @ * ;
: get-sizes                 ( &table -- $list-records table-size record-size )
                                                dup>r @  r@ table-size r> >record-size @  ;

: .table-props ( &table - ) \ All fields of a table need to be filled.
  dup cr ." &List-records:" ?
  dup cr ."   &List-aptrs:" >table-aptrs ?
  dup cr ."      #records:" >#records ?
  dup cr ."   record-size:" >record-size ?
      cr ."    table-size:" table-size u. ;

\ Adressing the pointers and records:

: nt>aptr       ( n &table - record# )          s" cell+ @ +cells " evaluate ; immediate
: rt>record     ( rel-addr &table - &record )   s" @ + "            evaluate ; immediate
: >table-record ( #record &table - &record ) s" tuck >record-size @ * swap rt>record " evaluate ; immediate
: nt>record     ( n &table - &record )            s" tuck nt>aptr @   swap rt>record " evaluate ; immediate

: xchange       ( a1 a2 - )        s" dup>r @ over @ r> ! swap ! " evaluate ; immediate
: >key          ( ra - key-start ) s" by @ + "        evaluate ; immediate
: key-len       ( ra - cnt )       s" by &key-len @ " evaluate ; immediate

\ Sorting

: <>=      ( n1 n2 - -1|0|1 )
    s" 2dup = if  2drop 0  else <  if 1 else  true  then  then " evaluate ; immediate

: f<>=      ( f1 f2 - -1|0|1 )
    s" f2dup f= if  f2drop 0  else f<  if 1 else  true  then  then " evaluate ; immediate

: cmp-cells  ( cand1 cand2 by - n )  locals| by |  >key @ swap >key @ <>= ;
: cmp-floats ( cand1 cand2 by - n )  locals| by |  >key f@ >key f@ f<>=   ;

: cmp$     ( cand1 cand2 by - n )
   locals| by |  swap >key swap >key key-len tuck compare ;

: mod-cell    ( n adr offset - ) >r swap r> cells+ ! ;
: Ascending   ( key - key ) dup  0 2 mod-cell ;
: Descending  ( key - key ) dup -1 2 mod-cell ;
: $sort       ( key - )     ['] cmp$       3 mod-cell ;
: bin-sort    ( key - )     ['] cmp-cells  3 mod-cell ;
: float-sort  ( key - )     ['] cmp-floats 3 mod-cell ;

: Descending? ( key - )      s" 2 cells+ @ " evaluate ; immediate

\ The following 3 definitiones must be used in RAM
\ Ascending and cmp$ are default in key:
: key: \ Compiletime: ( start len -< name >- )  Runtime: ( - adr-key )
   create swap , , 0 , ['] cmp$ , ;

: by[ ( R: -  #stack )                 postpone depth postpone >r ; immediate
: ]by ( - #stack-inc) ( R: #stack - )  postpone depth postpone r> postpone - ; immediate

: CmpBy  ( cand1 cand2  bystacktop #keys - f )
   true   locals| flag #keys  bystacktop cand2 cand1 |
   #keys 0
        do   cand1 cand2  bystacktop i cells+ @ dup 3 cells+ @ execute
             dup 0=
                if    drop
                else   bystacktop i cells+ @ Descending?
                        if    0<
                        else  0>
                        then
                      to flag leave             \ 0=exch
                then
        loop
   flag ;

: xdrop  ( nx..n1 #n - )  >r   sp@ r> 1- 0 max cells+ sp! drop ;
: gap*3  ( #records - #records gap )  1  begin  3 * 1+ 2dup 1+ u< until  ;

: table-sort  ( keyx..key1 #keys &table -- )  \ Uses a shellsort.
    sp@ 2 cells+ rot locals| #keys by &table |
    &table >table-aptrs @
    &table >#records @ dup 2 <
      if    2drop
      else  gap*3
            begin  3 / dup
            while  2dup - >r dup cells r> 0
                      do  dup 4 pick dup i cells +
                            do  dup i + dup @  &table rt>record
                                i tuck @ &table rt>record  by #keys CmpBy
                                    if    2drop  leave
                                    then
                                xchange dup negate
                            +loop  drop
                       loop  drop
           repeat  2drop drop
      then
    #keys xdrop ;

: create-file-ptrs ( name -- )
   count r/w bin create-file abort" Can't create index file."  close-file throw ;

: open-file-ptrs   ( name -- hndl )
   count r/w bin open-file abort" Can't open index file." ;

s" cforth" ENVIRONMENT? 0= [IF]

: extend-file   ( size hndl - )
    dup>r file-size drop d>s +
    s>d r@ resize-file abort" Can't extend file."
    r> close-file  drop ;
[ELSE]  drop
[THEN]

: add-ptrs      ( record-size aptrs  #start #end - )
      do  2dup i * swap   i cells + !
      loop 2drop ;

: build-ptrs    ( aptrs record-size #records -- )  0  add-ptrs ;
: allocate-ptrs ( #records -- &aptrs )
    cells allocate
       if   cr ." The allocation of address pointers failed."  quit
       then ;

\ \s
