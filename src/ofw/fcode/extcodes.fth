purpose: FCode token number definitions for Firmworks extensions

hex
vfw    070 2 byte-code: lock[		( -- )
vfw    071 2 byte-code: ]unlock		( -- )

vfw    072 2 byte-code: debug-me
vfw    073 2 byte-code: new-instance      ( args-adr args-len -- )
vfw    074 2 byte-code: destroy-instance  ( -- )
vfw    075 2 byte-code: set-default-unit  ( -- )

vfw    076 2 byte-code: $instructions     ( name$ -- )
vfw    077 2 byte-code: instructions-done ( -- )
vfw    078 2 byte-code: instructions-idle ( -- )

vfw    079 2 byte-code: us ( -- )
