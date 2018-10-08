\ test-socket.fth
\ Example code for using client sockets
\ Connects to an SSH server (port 22) on localhost (127.0.0.1)
\ and reads/displays the identification message

1 constant SOCK_STREAM \ from /usr/include//bits/socket_type.h
2 constant PF_INET \ from /usr/include//bits/socket.h
0 constant IPPROTO_IP \ from /usr/include/netinet/in.h

#16 constant /sockaddr
/sockaddr buffer: sockaddr \ c.len c.pf bew.port ip[4] padding[8]

-1 value socket-fd

: open-socket ( -- )
   IPPROTO_IP SOCK_STREAM PF_INET socket to socket-fd
   socket-fd 0< abort" open-socket failed"  \ !
;
: close-socket ( -- )
   socket-fd 0>= if
      socket-fd lwip-close  \ !
      -1 to socket-fd
   then
;

[ifndef] cscount
: cscount  ( adr -- adr len )
   dup                               ( adr cur-adr )
   begin  dup c@  while  1+  repeat  ( adr end-adr )
   over -                            ( adr len )
;
[then]
: ?posix-err  ( n -- )
   0<  if
      \ EALREADY is not really a problem
      errno  dup #114 =  if  drop exit  then  ( n )
      ." Syscall error " dup .d               ( n )
      strerror cscount type                   ( )
      cr
      abort
   then
;

: connect-socket ( 'ip port -- )
   sockaddr /sockaddr '0' fill ( 'ip port )

   \ Linux and LWIP have different defs for sockaddr:
   \  Linux:  struct sockaddr_in { unsigned short sin_family; ... }
   \  LWIP:   struct sockaddr_in { u8_t sin_len; u8_t sin_family; ... }

   /sockaddr sockaddr c!    ( 'ip port )
   PF_INET sockaddr ca1+ !  ( 'ip port )

   sockaddr wa1+ be-w! ( 'ip )
   sockaddr 2 wa+ 4 move ( )
   /sockaddr sockaddr socket-fd connect
   ?posix-err
;

create host #192 c, #168 c, #2 c, #100 c,
#22 constant ssh-port

: probe-ssh  ( -- )
   open-socket
   host ssh-port connect-socket
   pad $100 socket-fd lwip-read    ( actual )
   dup ?posix-err                  ( actual )
   pad swap type                   ( )
   close-socket                    ( )
;
