\ Result file tools

#19 buffer: date-buf
: get-date  ( -- )
   " popen:date ""+%Y/%m/%d %H:%M:%S"""
   r/o open-file abort" Can't get date"  ( fd )  >r
   date-buf #19 r@ read-file abort" Can't read date" drop
   r> close-file drop
   date-buf #19
;

#100 buffer: filename-buf
0 value filename-len
: filename$  ( -- adr len )  filename-buf filename-len  ;

: +null  ( adr len -- adr len )  2dup +  0 swap c!  ;

0 value result-fid
: close-result-file  ( -- )
   result-fid close-file drop  0 to result-fid

   \ Force null termination so the kernel's cstring converter does not
   \ have to use 2 buffers - which it doesn't have
   filename$ +null  ( name$ )
   2dup  " %s.txt" sprintf +null    ( name$ name.txt$ )
   rename-file
;

: open-result-file  ( -- )
   bdaddr #12  " %s-Charging" sprintf   ( adr len )
   dup to filename-len                      ( adr len )
   filename-buf swap move                   ( )
   
   filename$ r/o  create-file  abort" Can't create result file"  to result-fid
;
: write-result  ( adr len -- )  result-fid write-file drop  ;
