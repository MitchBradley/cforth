\ Abstract interface to relays.

defer ?open-relays
defer relay-on
defer relay-off

: null-relay-on  ( relay# -- )  ." Activate " . cr  ;

: use-null-relays  ( -- )
   ['] noop to ?open-relays
   ['] null-relay-on to relay-on
   ['] drop to relay-off
;
use-null-relays
