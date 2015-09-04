defer json-type   ( adr len -- )
' 2drop to json-type

0 value opened?

\ Object encoding
: json-{  ( -- )  " {"n" json-type  true to opened?  ;
: json-}  ( -- )  " "n}"n" json-type  ;
: json-next-pair  ( -- )
   opened?  if
      false to opened?
   else
      " ,"n" json-type
   then
;

\ Array encoding
: json-[  ( -- )  " [" json-type  true to opened?  ;
: json-]  ( -- )  " ]" json-type  ;
: json-next-value  ( -- )
   opened?  if
      false to opened?
   else
      " , " json-type
   then
;

: json-emit$  ( adr len -- )  " """ json-type  json-type  " """ json-type  ;
: json-emit-name  ( name$ -- )  json-next-pair json-emit$ " : " json-type  ;
: json-emit-int  ( n -- )  push-decimal (.) json-type pop-base  ;
: json-preformatted  ( value$ name$ -- )  json-emit-name json-type  ;

: json-$  ( value$ name$ -- )  json-emit-name json-emit$  ;
: json-int  ( n name$ -- )  json-emit-name json-emit-int ;
: json-flag  ( flag name$ -- )
   json-emit-name  if  " true"  else  " false"  then  json-type
;
: json-null  ( name$ -- )  json-emit-name  " null" json-type  ;
: json-int-array  ( adr len name$ )
   json-emit-name  json-[   ( adr len )
   bounds ?do
      json-next-value  i @ json-emit-int
   /n +loop
   json-]
;
: json-short-array  ( adr len name$ )
   json-emit-name  json-[   ( adr len )
   bounds ?do
      json-next-value  i <w@ json-emit-int
   /w +loop
   json-]
;

0 [if]

   Example:

   json-{
   true " SFC" json-flag
   workorder$ " WorkOrder" json$
   get-date  " StartTime" json$
   accel-bias-array  " AccelBiases" json-int-array
   gyro-bias-array  " GyroBiases" json-int-array
   status$ " Status" json$
   json-}

[then]
