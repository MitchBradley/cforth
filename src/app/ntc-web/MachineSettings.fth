marker -MachineSettings.fth  cr lastacf .name #19 to-column .( 07-01-2023 ) \ By J.v.d.Ven

s" 192.168.0.201" dup 1+ allocate drop dup to time-server$ place

[ifdef] Rpi1-server$
s" 192.168.0.201" dup 1+ allocate drop dup to Rpi1-server$ place \ For a sensorweb
s" 192.168.0.212" dup 1+ allocate drop dup to ESP2-server$ place \ For a message board
[then]

also html

: SitesIndex ( -- )
    s" http://192.168.0.201:8080/SitesIndex" s" Index"  <<TopLink>> ;

previous

\ \s
