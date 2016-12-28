\ reset the system
\ a write to the watchdog unlock register that isn't the magic values
\ will force a watchdog interrupt-then-reset.
: wd  0 4005200e !  ;
