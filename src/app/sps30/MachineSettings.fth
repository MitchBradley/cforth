marker -MachineSettings.fth  cr lastacf .name #19 to-column .( 11-11-2023 ) \ By J.v.d.Ven


s" 192.168.0."    dup 1+ allocate drop dup to prefix$ place \ For the Gforth-servers

\ Other involved servers. Edit/dissable the following 5 lines:
s" 192.168.0.201" dup 1+ allocate drop dup to time-server$ place
s" 192.168.0.201" dup 1+ allocate drop dup to sensor-web$ place
s" 192.168.0.212" dup 1+ allocate drop dup to msg-board$ place
#200 #9 range-Gforth-servers 2!

also html

: SitesIndex ( -- )
    s" http://192.168.0.201:8080/SitesIndex" s" Index"  <<TopLink>> ;

previous

\ \s
