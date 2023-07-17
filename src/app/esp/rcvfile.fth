marker -rcvfile.fth  cr lastacf .name #19 to-column  .( 17-05-2023 ) \ By J.v.d.Ven

\ Needed in ROM
needs execute-task  tasking_rtos.fth  \ Note: If no other tasks or servers are used then the receiver
needs /circular      ../esp/extra.fth \       might be started in a task of tasking_rtos.fth

0 [if]
 New:
26-06-2022
Changed the timing for the ESP32.
Added AnswerWsPing

26-06-2022
Adapted for the new webcontrols
[then]

0 value exitRCV \ 1=EXIT after a FILE has been received,  2=QUIT after REBOOT has been hit on the server
                \ 0=EXIT exit UNLESS a key is hit on the MCU and then save is hit on the server

nuser vector-table
nuser &UdpData

esp8266? not [IF]  \ ----- esp32


0 value UdpSocket-fd
2 constant SOCK_DGRAM
2 constant AF_INET
0 constant IPPROTO_IP

#16 constant /sockaddr
/sockaddr buffer: sockaddr \ c.len c.pf bew.port ip[4] padding[8]

: open-udp-socket ( -- socket )
   IPPROTO_IP SOCK_DGRAM AF_INET socket
   dup 0< abort" open-socket failed" ;

: ?posix-err  ( n -- )
   0<  if
      \ EALREADY is not really a problem
      errno  dup #114 =  if  drop exit  then  ( n )
      ." Syscall error " dup .d               ( n )
      strerror cscount type                   ( )
      cr
      abort
   then ;

: bind-socket ( 'ip port fd -- )  \ create-socket
   >r sockaddr /sockaddr '0' fill ( 'ip port )

   \ Linux and LWIP have different defs for sockaddr:
   \  Linux:  struct sockaddr_in { unsigned short sin_family; ... }
   \  LWIP:   struct sockaddr_in { u8_t sin_len; u8_t sin_family; ... }

   /sockaddr sockaddr c!    ( 'ip port )
   AF_INET sockaddr ca1+ !  ( 'ip port )

   sockaddr wa1+ be-w! ( 'ip )
   sockaddr 2 wa+ 4 move ( )
   /sockaddr sockaddr r> bind
   ?posix-err ;

: start-udp-server ( port - socket )
   open-udp-socket >r  ipaddr@ swap r@ bind-socket r> ;

[THEN]


also hidden definitions

#8899 constant udp-port#             \ To receive data and commands
: TcpPORT$ ( -- adr cnt ) " 8080" ;  \ To send info and feedback

#8                      constant >UdpPacket \ need 8 bytes extra
#12                     constant /num
/num                    constant DataOffset
#768                    constant /UdpData
/UdpData   DataOffset + constant /UdpPacket

0 value rcv-interactive?
0 value &UdpBuffer
0 value &UdpPacket
0 value &LastUdpByte

0 value flash-server$  #16       constant /flash-server
0 vector-table !       #7  cells constant /vector-table
0 value &TcpBuffer     #30       constant /TcpBuffer

: allocate-udp-buffers   \ allocate-buffers  free-buffers
    /TcpBuffer allocate throw to &TcpBuffer
    &TcpBuffer /TcpBuffer  0 fill
    /UdpPacket >UdpPacket + allocate throw to &UdpBuffer
    &UdpBuffer >UdpPacket + to  &UdpPacket
    &UdpPacket DataOffset + &UdpData !
    &UdpData @  /UdpData +  1- to &LastUdpByte
    /flash-server allocate throw to flash-server$
    /vector-table allocate throw vector-table ! ;

: free-udp-buffers
   &TcpBuffer    free throw
   &UdpBuffer    free throw
   flash-server$ free throw
   vector-table @  free throw 0 vector-table ! ;

variable #done
nuser udp-socket      udp-socket off
variable tcp-server   tcp-server off
#1 constant TcpTimeout

: set-flash-server ( - )  &UdpData @ /num 2 * + #13 flash-server$ place ;

: connect-server ( - )
    #1000 TcpPORT$  flash-server$ count stream-connect
    tcp-server ! ;

: disconnect-server ( - )
    tcp-server @ dup
       if    lwip-close  tcp-server off
       else  drop
       then ;

: write-flash-server ( adr count - )
    disconnect-server
    connect-server
    tcp-server @  lwip-write  \ err?
    TcpTimeout ms drop  disconnect-server ;


: lwip-send ( send$ cnt UdpSock - )
   >r r@ lwip-write drop
   r> lwip-close ;

: AnswerWsPing ( - )
   &UdpPacket 40  s" wsping " dup >r search
     if    &TcpBuffer off s" -2130706460 PingReply " &TcpBuffer lplace
           ipaddr@ ipaddr$  &TcpBuffer +lplace
           r> /string 2dup  0 scan nip -
           udp-port# (.) 2swap udp-connect
           &TcpBuffer lcount rot lwip-send
     else  2drop r> drop
     then ;

: rcv-prompt ( - )  cr  rcv-interactive? if ." > "  else ."  ok " then  ;

: RetChkCmd ( - )
    set-flash-server sysledOn
    ." Report to: " flash-server$ count type rcv-prompt
    &TcpBuffer off s" RemoteOk"  &TcpBuffer +lplace
    &TcpBuffer lcount  write-flash-server  sysledOff   ;

#30 constant /MaxFilenameLengthRcv
#48 constant >filenameRcv
variable fsize
0 value fd-file

: GetFilename ( - adr cnt flag )
    &UdpData @ >filenameRcv + /MaxFilenameLengthRcv bl NextString
    dup 1 /MaxFilenameLengthRcv between ;

: CreateFileSpace ( size - fd )
    GetFilename
     if     2dup type ."  Receiving >f" r/w create-file 0=
               if     to fd-file drop                \  fd
               else  ."  --- FAILED ---" 2drop fsize off
               then
     else  3drop drop fsize off
     then fd-file ;

variable #retries
variable msStartFlash

: prep-flash ( - )  &UdpPacket off    #retries off #done off ;

: start-flash  ( - )
    &TcpBuffer off
    s" /udpf "  &TcpBuffer +lplace  "  "  &TcpBuffer +lplace  9  (.) &TcpBuffer +lplace
    &TcpBuffer lcount write-flash-server
    [char] t emit get-msecs ( ms@ ) msStartFlash !  ;

: start-flash-session ( - )
    &UdpData @  /num + /num bl GetValue   \ Get the filesize
                if   dup fsize ! set-flash-server
                      CreateFileSpace  to fd-file ." e"
                      prep-flash start-flash \ start a flash session
                else  drop cr ." Invalid size." cr
                then ;

: .modk ( n div1000 - )
    /mod (.) type dup #999 >
       if  #1000 /
       then s>d
    <# # # # [char] . hold #> type ;

: ask-missing-packet  ( i - )
   /UdpData *    &TcpBuffer off
   " /udp "  &TcpBuffer +lplace   (.) &TcpBuffer +lplace  "  "  &TcpBuffer +lplace
   9  (.) &TcpBuffer +lplace      \ &TcpBuffer lcount type-counted
   &TcpBuffer lcount  write-flash-server ;

: .report ( - )
    get-msecs  msStartFlash @ - dup ." <" 9 emit 1000 .modk ."  sec. " \ And report
    fsize @  dup #1000 .modk ."  kB " \ 1kB=1000 bytes here
    #8 * swap .modk ."  kbit/s"
    fsize off sysledoff  disconnect-server rcv-prompt ;


: SetAppFile ( NameSource cnt - )
    s" _appname.txt" file-exist? not
       if    s" -dummy-" set-app
       then
    here off  s" _appname.txt" here #255  +file
    2dup here lcount compare
       if    set-app 1 ms
       else  2drop
       then ;

: UdpLoad ( - )
    GetFilename
       if  2dup file-exist?
             if     SetAppFile bye \ Restarts Forth and compiles the startfile
             else   cr type ."  does not exist."
        else  ." Error at:" type
        then then ;

: Reboot ( - )  bye ;

\ 1 value dmp

: CloseRcv  ( - ) \ A possible alternative for reboot at the end of a received file.
   cr HEX free-udp-buffers udp-socket @ lwip-close disconnect-server  ;

: QuitRcv ( - ) CloseRcv quit ;

: repair  ( - )     \ For dropped packets.
    fsize @ dup 0>
       if   /UdpData /mod swap if 1+ then
              0
               do  i  /UdpData *  [ /UdpData 1 - ] literal + fsize @ 1- min  \ last byte in packet in file
                   s>d fd-file reposition-file drop
                   &TcpBuffer off fd-file file-size  1 ms 3drop
                   &TcpBuffer 1 fd-file read-file 2drop &TcpBuffer c@ 0=  \ find missing packets
                      if    \ cr i cr ." 1>>" . true to dmp
                              [char] r emit
                             1 #retries +! i ask-missing-packet  \ then the upd-command should
                             unloop  exit                        \ get the missing packet
                       then
               loop
             sysledon fd-file dup flush-file drop close-file drop
             0 to fd-file .report -1 #done ! 1 ms sysledoff
       else drop
       then
    -1 ask-missing-packet ;

0 value last-vector
: fill-vector-table ( - last-adr )  \  Can't use: create vector-table  ' start-flash-session , \ etc in ROM
   vector-table @                        \ On server buttons:
          ['] start-flash-session  over ! \ Flash
   cell+  ['] UdpLoad      over !         \ Load
   cell+ exitRCV 2 =                      \ Reboot/Quit
     if   ['] QuitRcv                     \    Quit
     else ['] Reboot                      \    reboot
     then   over !
   cell+  ['] RetChkCmd    over !         \ Save
   cell+  ['] repair       over !         \ Internal
   cell+  ['] noop         over ! \ For external applications ( cmd= -2130706452 ) at: 5 cells +
   cell+  ['] AnswerWsPing over !         \ WsPing string is received  ( cmd= -2130706456 )
   cell+  ['] noop         over !         \ Reserved -2130706460 to handle answered wsPings
 ;

$7f000000 constant first-vector

: exe-vector ( -vector|Unknown - )
    abs dup first-vector  last-vector between \ See also UdpSender.f
      if    first-vector -  vector-table @ + @ execute
      else  drop
      then ;

 /UdpData #16 * constant blinkchar

: blink ( - )
   #done @ blinkchar /mod drop 0=   if   [char] . emit   else   sysledon then sysledoff ;

: StripOverSized  ( #towrite position-in-file - #towrite-new )
   s" /UdpData + fsize @ >   if   drop fsize @  /UdpData /mod drop   then"  evaluate ;  immediate

: write-in-file  ( buffer #towrite position-in-file -- )
   dup >r  StripOverSized r>
   s>d fd-file reposition-file drop fd-file file-size 1 ms 3drop fd-file write-file drop
   0 &LastUdpByte c! ;

variable /UdpSize
: receive-udp-packets ( -- )
    &UdpPacket off &UdpPacket /UdpPacket udp-socket @ lwip-read dup 0>   ( - #read flag )
        if  &UdpPacket /num bl GetValue             \ ( - #read positon|size|vector flag )
\   dmp if  cr .s ." --2>> " cr &UdpPacket 50 dump  then
              if  dup  0>=                           \ A vector is negative ( - #read position flag )
                    if    >r &UdpPacket swap DataOffset /string
                          dup #done +! 0 max
                          r>  write-in-file blink exit  \ Write the received packet at it's position
                    else swap /UdpSize !  exe-vector \ Execute the vector
                    then
              else 2drop [char] O emit              \ No position or vector found in packet
              then
\        else    [char] - emit                      \ 0 packet or disconected
        then   ;


also forth definitions

: upd-init ( -- )
    sysled gpio-is-output sysledOn  DECIMAL
    vector-table @ 0=
       if   allocate-udp-buffers
            fill-vector-table   vector-table @ - first-vector + to last-vector
            &UdpBuffer /UdpPacket erase
            udp-port# start-udp-server dup 0< abort" Cannot create UDP socket."
            udp-socket !
       then
    sysledOff  #done off ;

: stop-receiver?  ( - flag )   #done @ -1 = exitRCV 1 = and  ;

: receiver-msg
   bold ." The receiver" norm ."  is waiting for a file on UDP port: "  udp-port# .d
        ." at: " ipaddr@ .ipaddr cr ;

s" switch-regs"      $find nip [IF] \ Check for preemptive multitasking

: receiver-in-task ( -- )  \ To receive a file using the UDP protocol in a task.
    false to rcv-interactive?   0 vector-table ! \ It assumes you are logged on
    upd-init   bold ." BG: " norm   receiver-msg \ to a wifi network.
       begin   receive-udp-packets
       again
    end-task ;

: restart-msg ( - ) ." Restart cforth" ;
: +rcv  ( - )   s" receiver" s" _receiver_bg.txt" file-it     restart-msg ;
: -rcv  ( - )                s" _receiver_bg.txt" delete-file restart-msg ;

[THEN]

: receiver ( -- )  \ To receive a file using the UDP protocol interactive.
    true to rcv-interactive?
    wifi-logon-state  -2 =
        if  #500000 us logon
        then
    upd-init receiver-msg rcv-prompt
       begin  receive-udp-packets  stop-receiver? key? or
       until
    CloseRcv ;

alias r receiver

previous previous

\ \s
