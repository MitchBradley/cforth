: (buffer:)  ( #bytes -- )  create-cf allot  ;
: buffer:  ( #bytes "name"-- )  header (buffer:)  ;
