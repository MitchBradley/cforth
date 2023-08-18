marker table_test.f  \ 29-06-2023 by J.v.d.Ven

s" cforth" ENVIRONMENT? [IF] drop \ For the extended version on an ESP32
DECIMAL                           \ table_test.f must loaded in RAM on an ESP32

needs table-sort table_sort.f
2000 value #test-records          \ Only small tables are possible

[ELSE]

needs table_sort.f

variable seed

: Rnd        ( -- rnd )
    seed @ dup 0= or   dup 13 lshift xor   dup 17 rshift xor
    dup 5 lshift xor dup seed ! ;

: init-seed  ( - )   Rnd  seed ! ;
: RandomLim  ( limit - random )   Rnd swap /mod drop ;

200000 value #test-records

[THEN]


s" gforth" ENVIRONMENT? [IF] 2drop

needs unix/pthread.fs -status

[THEN]


s" win32forth" ENVIRONMENT? [IF] DROP

needs MultiTaskingClass.f

wTasks myTasks    Start: myTasks

:  execute-task ( xt - IdThread )  submit: myTasks  FindThread: myTasks  ;


[THEN]


0 value &table1

: >sort-time        ( &table - &sort-time )   4 cells+ ;

8 constant #chars 3 constant GrouplLimit

\ 2 fields in the records of each table:
: >test.chars       ( &record - &test.chars )  ; immediate
: >test.group       ( &record - &Option# )  s" #chars + " evaluate ; immediate


: chars!            ( &test.chars -- )
   #chars 0 do 26 randomlim [char] a +  over c! char+ loop drop ;

: randomize-records ( &table -- )   \ fills the records randomly
    get-sizes -rot       2dup  BL FILL  bounds
       do   i dup >test.chars chars!
                  >test.group GrouplLimit RandomLim swap !   dup
       +loop drop ;

: .record           ( &record -- )
    dup   >test.chars #chars type space
          >test.group ? ;

: .records          ( &table -- )
    get-sizes 0 2swap   bounds
       do cr dup . 1+  I  .record over +loop 2drop ;

: .records-sorted   ( &table -- )
    dup >#records @ 0
       do cr I . i over nt>record  .record loop drop ;

0 >test.chars  #chars key: test-chars   test-chars Ascending $sort
0 >test.group 1 cells key: test-group   test-group Ascending bin-sort

: sort-test         ( &table -- )
   >r by[ test-chars test-group ]by r> table-sort ;

: nt>test.group ( n &table - &sorted-test.group ) nt>record >test.group ;
: nt>test.chars ( n &table - &sorted-test.chars ) nt>record >test.chars ;

: check-keys  { &tbl -- }
    &tbl >#records @ 1- 0
    do   i    &tbl nt>test.group @
         i 1+ &tbl nt>test.group @  2dup =
              if   2drop      \ The same group
                   i     &tbl nt>test.chars
                   i 1+  &tbl nt>test.chars  #chars tuck compare 0>
                        if i 1+ . ." #chars UN" leave
                        then
              else  >
                       if i 1+ . ." group UN"  leave
                       then
              then
    loop ." sorted "  ;

: init-test-table   ( &table #records  - )
   >r #chars 1 cells + over >record-size !
   r> over >#records ! >r
   r@ table-size   allocate            \ allocates the records
        if cr ." The allocation of records failed. " quit
        then  r@ !
   r@ >#records @  allocate-ptrs       \ allocates the the address pointers
   dup r@ >table-aptrs !
   r@ >record-size @ r> >#records @  build-ptrs ;

/table cell+ init-table to &table1
&table1 #test-records  init-test-table

cr cr &table1 .table-props

s" cforth" ENVIRONMENT? [IF] drop

: sort1  ( - )
  cr ." Sorting the table takes "
  &table1 ms@ over  sort-test ms@  swap - . ." ms. " check-keys ;

cr sort1 cr quit
[THEN]

0 value &table2
/table cell+ init-table to &table2
&table2 #test-records  init-test-table

0 value &table3
/table cell+ init-table to &table3
&table3 #test-records  init-test-table

0 value &table4
/table cell+ init-table to &table4
&table4 #test-records  init-test-table

4 constant all-done
0 value ms-done
variable #all-done

: .all-done ( - )
     cr ." Needed sort time for each table with " #test-records .
          ." records in each table"
     cr &table1  >sort-time ?
        &table2  >sort-time ?
        &table3  >sort-time ?
        &table4  >sort-time ? ." ms READY!" ;

: check-4tables  ( - )
   cr &table1 ." 1:" check-keys   &table2 ." 2:" check-keys
      &table3 ." 3:" check-keys   &table4 ." 4:" check-keys  ;

: sort-done ( &table time - )
   swap - swap >sort-time !
   1 #all-done +!
   #all-done @ all-done >=
     if  .all-done  ms@ ms-done - dup to ms-done
         cr ." Total needed time: " . ." ms " cr
         check-4tables
     then ;

: sort1  ( - ) &table1  ms@  over sort-test ms@ sort-done ;
: sort2  ( - ) &table2  ms@  over sort-test ms@ sort-done ;
: sort3  ( - ) &table3  ms@  over sort-test ms@ sort-done ;
: sort4  ( - ) &table4  ms@  over sort-test ms@ sort-done ;

: random-4tables ( - )
   &table1 randomize-records &table2 randomize-records
   &table3 randomize-records &table4 randomize-records ;


: sort-all ( - )
   -100 #all-done !
   cr random-4tables
   cr ." Sorting 4 tables one at the time " ms@ >r
   sort1 sort2 sort3 sort4
   ms@ r> -  .all-done
   cr ." Total time: " . ." ms " check-4tables ;

cr sort-all

: sort-all-parallel
   cr ." Parallel sorting 4 tables in the background moment: "
   cr ms@ to ms-done  #all-done off
      ['] sort1 execute-task drop  ['] sort2 execute-task drop
      ['] sort3 execute-task drop  ['] sort4 execute-task drop ;

random-4tables
cr sort-all-parallel


cr .( >>> Hit a key when the NEXT sort below is ready:)  key drop
cr cr .( Changing 1 record in table1 and sorting again....)

0 &table1 >#records @ 2/  &table1 nt>test.group !
sort-all-parallel cr

0 [if] \ Some results:



--------------------------

Cforth on an ESP32 @ 240 Mhz
&List-records:1073549784
  &List-aptrs:1073573792
     #records:2000
  record-size:12
   table-size:24000
Sorting the table takes 755 ms. sorted.

--------------------------

\ Under a 64 bits gforth-fast version 0.7.9_20220713
\ on the "Bookworm" with an i5-4200U CPU @ 1.60GHz I get:

&List-records:140434665824272  
 &List-aptrs:140434664222736  
    #records:200000  
 record-size:16  
  table-size:3200000  


Sorting 4 tables one at the time  
Needed sort time for each table with 200000 records in each table
719 679 687 697 ms READY!
Total time: 2782 ms  
1:sorted 2:sorted 3:sorted 4:sorted  

Parallel sorting 4 tables in the background moment:  

>>> Hit a key when the NEXT sort below is ready:
Needed sort time for each table with 200000 records in each table
1451 1462 1480 1469 ms READY!
Total needed time: 1481 ms  

1:sorted 2:sorted 3:sorted 4:sorted  

Changing 1 record in table1 and sorting again....
Parallel sorting 4 tables in the background moment:  

ok

Needed sort time for each table with 200000 records in each table
443 449 443 451 ms READY!
Total needed time: 453 ms  

1:sorted 2:sorted 3:sorted 4:sorted
--------------------------

Under Win32Forth on W11 with an i9-12900 CPU @ 5.1 GHz I get:


&List-records:173211696
  &List-aptrs:175697968
     #records:200000
  record-size:12
   table-size:2400000


Sorting 4 tables one at the time
Needed sort time for each table with 200000 records in each table
544 582 553 560 ms READY!
Total time: 2239 ms
1:sorted 2:sorted 3:sorted 4:sorted

Parallel sorting 4 tables in the background moment:

>>> Hit a key when the NEXT sort below is ready:
Needed sort time for each table with 200000 records in each table
566 554 545 589 ms READY!
Total needed time: 592 ms

1:sorted 2:sorted 3:sorted 4:sorted

Changing 1 record in table1 and sorting again....
Parallel sorting 4 tables in the background moment:

 ok

Needed sort time for each table with 200000 records in each table
122 120 118 119 ms READY!
Total needed time: 127 ms
1:sorted 2:sorted 3:sorted 4:sorted

[then]


\ \s
