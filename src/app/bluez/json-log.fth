\needs json-{  fload json.fth

-1 value json-log-fid

: json-log-type  ( adr len -- )
   json-log-fid -1 =  if  2drop exit  then
   json-log-fid write-file drop
;
: open-json-log  ( filename$ -- )
   w/o open-file abort" Can't open JSON log file"
   to json-log-fid
   ['] json-log-type to json-type
;
: flush-json-log  ( -- )
   json-log-fid -1 =  if  exit then
   json-log-fid flush-file drop
;
: close-json-log  ( -- )
   json-log-fid -1 =  if  exit then
   json-log-fid close-file drop
   -1 to json-log-fid
   ['] 2drop to json-type
;

: json-status  ( adr len -- )  " Status" json-$  ;
