[ifdef]    -enow_send.fth   bye  [then]
marker     -enow_send.fth cr lastacf .name #19 to-column .( 24-05-2022 )

[ifndef] esp-channel
   1 constant esp-channel
[then]

[ifndef] start-esp-now
: start-esp-now ( - ) \ Works if NOT connected to a wifi of a router/access point
   esp-channel esp-now-open  if ." esp-now-open failed" then
   esp-now-init              if ." esp-now-init failed" then ;
[then]

\ To all receivers:
create to_all_mac  $FF c, $FF c, $FF c, $FF c, $FF c, $FF c,

: add-peer      ( &MacPeer - )  0 false rot esp-now-add-peer ;

: enow-send$ ( adr cnt esp_mac - )
    >r swap r> esp-now-send
       if ." Peer not found/added.  enow-send$ failed " quit then ;

\ \s
