marker -wsping.fth  cr lastacf .name #19 to-column .( 11-11-2023 ) \ By J.v.d.Ven

\ For Web-server-light.f to update ARP caches of the gforth webservers


Also hidden decimal
needs lwip-send rcvfile.fth

0 value prefix$
#201 value master
2variable range-gforth-servers

: dec(.) ( n - adr$ cnt )
   base @ >r decimal (.) r> base ! ;

: connect-udp-neigh? ( ip$ cnt - handle|0 )
  2dup tmp$ place  ipaddr@ ipaddr$ compare
   if    udp-port# dec(.) tmp$ count udp-connect
   else  false
   then ;

: SendUdpMsg+ip ( ip$ cnt msg cnt - )
   2swap connect-udp-neigh? dup 0>
     if    >r  htmlpage$  lplace
           ipaddr@ ipaddr$  htmlpage$  +lplace
           htmlpage$  lcount   space  2dup type
           r@ lwip-write drop
           r> lwip-close
     else  3drop
     then ;

: ForUdpRange  ( from n cfa - )
   cr -rot bounds
      ?do  i prefix$ count pad lplace dec(.) pad +lplace
           pad lcount cr 2dup type
           2 pick execute
      loop
   drop ;

: arpnew ( - )
          prefix$ count tmp$ lplace     master dec(.) tmp$ +lplace
          tmp$ lcount pad place
          pad count    s"  arpnew "     SendUdpMsg+ip ;

: wsPing ( ip$ cnt - ) s" -2130706456 wsping " SendUdpMsg+ip ;
: -arp   ( ip$ cnt - ) s"  -arp "       SendUdpMsg+ip ;
: wsPingRange ( from n - )  ['] wsPing  ForUdpRange ;
: -ArpRange   ( from n - )  [']  -arp   ForUdpRange ;

previous

\ #200 #9 wsPingRange
\ #200 #9 -ArpRange
\ \s
