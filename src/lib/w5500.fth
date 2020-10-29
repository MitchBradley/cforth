\ SPI mode 1 or 3, bit endian
\ 16-bit address, 8-bit control, variable length data
\ Control: bbbbbWmm bbbbb is reg#, W is 1 for write, mm is mode:
\   0 - variable length controlled by CS
\  with CS always low:
\   1 - 1 byte data
\   2 - 2 bytes data
\   3 - 4 bytes data

\ In variable mode, the address autoincrements so you can send multiple
\ data in one frame.

\ Control values
0 constant Wcommon

0 value socket#
: >reg  ( write? offset -- reg# )  socket# 4 *  +  3 lshift  swap 4 and or  ;
: sock-reg  ( write? -- reg# )   1 >reg  ;
: tx-reg  ( write? -- reg# )  2 >reg  ;
: rx-reg  ( write? -- reg# )  3 >reg  ;

\ Offsets in common register space
$00 constant MR        \ 1 Mode
$01 constant GAR       \ 4 Gateway address
$05 constant SUBR      \ 4 Subnet mask
$09 constant SHAR      \ 6 Source MAC address
$0f constant SIPR      \ 4 Source IP address
$13 constant INTLEVEL  \ 2 Interrupt low level timer
$15 constant IR        \ 1 Interrupt
$16 constant IMR       \ 1 Interrupt mask
$17 constant SIR       \ 1 Socket interrupt
$18 constant SIMR      \ 1 Socket Interrupt mask
$1a constant RTR       \ 2 Retry time
$1b constant RCR       \ 1 Retry count
$1c constant PTIMER    \ 1 PPC LCP Request Timer
$1d constant PMAGIC    \ 1 PPP LCP Magic number
$1e constant PHAR      \ 6  PPP Destination Mac
$24 constant PSID      \ 2 PPP Session ID
$26 constant PMUR      \ 2 PPP Max Segment Size
$28 constant UIPR      \ 4 Unreachable IP address
$2c constant UPORTR    \ 2 Unreachable Port
$2e constant PHYCFGR   \ 1 PHY config
$39 constant VERSIONR  \ 1 Chip version

\ Socket register block
$00 constant sMR       \ 1 Mode
$01 constant CR        \ 1 Command
$02 constant IR        \ 1 Interrupt
$03 constant SR        \ 1 Status
$04 constant PORT      \ 2 Source Port
$06 constant DHAR      \ 6 Destination MAC
$0c constant DIPR      \ 4 Destination IP
$10 constant DPORT     \ 2 Destination Port
$12 constant MSSR      \ 2 Maximum Segment Size
$15 constant TOS       \ 1 Type of Service
$16 constant TTL       \ 1 Time to Live
$1e constant /RxBUF    \ 1 Rx buffer size
$1f constant /TxBUF    \ 1 Tx buffer size
$20 constant TxFSR     \ 2 Tx Free Size
$22 constant TxRD      \ 2 Tx Read Pointer
$24 constant TxWR      \ 2 Tx Write Pointer
$26 constant RxRSR     \ 2 Rx Received Size
$28 constant RxRD      \ 2 Rx Read Pointer
$2a constant RxWR      \ 2 Rx Write Pointer
$2c constant sIMR      \ 1 Interrupt Mask
$2d constant FRAG      \ 2 Fragment Offset
$2f constant KPALTR    \ 1 Keepalive Timer


#1024 buffer: Wbuf

: Wstart  ( addr -- )
   
   Wspi-start
   

: Wb!  ( b addr -- )
  
   set-addr
