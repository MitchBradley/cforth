\ Use this version for buffers of modest size
: buffer:  ( n -- )  /n round-up ualloc user  ;
