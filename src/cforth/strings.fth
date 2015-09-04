: cscount  ( 'cstr -- adr len )  dup  begin  dup c@  while  1+  repeat  over -  ;

: left-parse-string  ( $ delim -- tail$ head$ )
   split-string  dup  if  1 /string  then  2swap
;
