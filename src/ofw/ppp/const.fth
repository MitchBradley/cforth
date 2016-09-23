\ See license at end of file
purpose: PPP global constants

decimal

2	constant CILEN_VOID

\ Values for phase - used inline:
\ 0	constant PHASE_DEAD
\ 1	constant PHASE_ESTABLISH
\ 2	constant PHASE_AUTHENTICATE
\ 3	constant PHASE_NETWORK
\ 4	constant PHASE_TERMINATE

\ Packet header = Code, id, length.
4	constant HEADERLEN

\  CP (LCP, IPCP, etc.) codes.
1	constant CONFREQ	\ Configuration Request
2	constant CONFACK	\ Configuration Ack
3	constant CONFNAK	\ Configuration Nak
4	constant CONFREJ	\ Configuration Reject
5	constant TERMREQ	\ Termination Request
6	constant TERMACK	\ Termination Ack
7	constant CODEREJ	\ Code Reject

string-array >msg-name
   ," confreq"
   ," confack"
   ," confnak"
   ," confrej"
   ," termreq"
   ," termack"
   ," coderej"
end-string-array
: .msg-name  ( msg -- )  1- >msg-name count type space ;

\ Link states.
0	constant INITIAL	\ Down, hasn't been opened
1	constant STARTING	\ Down, been opened
2	constant CLOSED		\ Up, hasn't been opened
3	constant STOPPED	\ Open, waiting for down event
4	constant CLOSING	\ Terminating the connection, not open
5	constant STOPPING	\ Terminating, but open
6	constant REQSENT	\ We've sent a Config Request
7	constant ACKRCVD	\ We've received a Config Ack
8	constant ACKSENT	\ We've sent a Config Ack
9	constant OPENED		\ Connection available
\ Auth states
10	constant AUTHREQ	\ We've sent an Authenticate-Request
11	constant BADAUTH	\ We've received a Nak
12	constant PENDING	\ Auth us to peer when lower up
13	constant LISTEN		\ Listening for a challenge
14	constant RESPONSE	\ Sent response, waiting for status

string-array >state-name
   ," INITIAL"
   ," STARTING"
   ," CLOSED"
   ," STOPPED"
   ," CLOSING"
   ," STOPPING"
   ," REQSENT"
   ," ACKRCVD"
   ," ACKSEND"
   ," OPENED"
   ," AUTHREQ"
   ," BADAUTH"
   ," PENDING"
   ," LISTEN"
   ," RESPONSE"
end-string-array
: .state-name  ( state -- )  >state-name count type space ;

\ Timeouts.
8	constant DEFTIMEOUT	\ Timeout time in seconds
\ 3	constant DEFTIMEOUT	\ Timeout time in seconds
2	constant DEFMAXTERMREQS	\ Maximum Terminate-Request transmissions
10	constant DEFMAXCONFREQS	\ Maximum Configure-Request transmissions
5	constant DEFMAXNAKLOOPS	\ Maximum number of nak loops

1500	constant DEFMRU		\ Try for this
128	constant MINMRU		\ No MRUs below this
16384	constant MAXMRU		\ Normally limit MRU to this

\ Default number of times we receive our magic number from the peer
\   before deciding the link is looped-back.
5	constant DEFLOOPBACKFAIL

\ Definitions for PPP Compression Control Protocol.
\ Bits in auth_pending
1	constant UPAP_WITHPEER
4	constant CHAP_WITHPEER

4	constant PPP_HDRLEN	\ octets for standard ppp header
1500	constant PPP_MRU	\ default MRU = max length of info field

h# 21	constant PPP_IP			\ Internet Protocol
h# 2d	constant PPP_VJC_COMP		\ VJ compressed TCP
h# 2f	constant PPP_VJC_UNCOMP		\ VJ uncompressed TCP
h# fd	constant PPP_COMP		\ compressed packet
h# 8021	constant PPP_IPCP		\ IP Control Protocol
h# c021	constant PPP_LCP		\ Link Control Protocol
h# c023	constant PPP_PAP		\ Password Authentication Protocol
h# c025	constant PPP_LQR		\ Link Quality Report protocol
h# c223	constant PPP_CHAP		\ Cryptographic Handshake Auth. Protocol
h# 80fd	constant PPP_CCP		\ Compression Control Protocol
h# fd	constant PPP_CCPD		\ Compression Control Protocol, data

h# f0b8	constant PPP_GOODFCS		\ Good final FCS value
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
