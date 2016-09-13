\ User interface versions of some special FCode Functions and tokenizer macros

: fcode-version1  ( -- )  ;
: fcode-version2  ( -- )  ;
: fcode-version3  ( -- )  ;
: end0  ( -- )  [compile] \  source-id  if   begin  refill 0=  until  then  ;

\ headers and headerless are already defined, and their action can be disabled
: external  ( -- )  ;
