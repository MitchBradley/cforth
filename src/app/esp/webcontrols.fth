marker -webcontrols.fth  cr lastacf .name #19 to-column .( 08-01-2023 ) \ By J.v.d.Ven

needs /circular    extra.fth

VOCABULARY TCP/IP
VOCABULARY HTML HTML DEFINITIONS

: +1html	( char -- )     sp@ 1 +html drop ;
: .Html		( n -- )        (.) +html ;
: <body>	( -- ) +HTML| <body>| ;
: </body>	( -- ) +HTML| </body>| ;
: <br>		( -- ) +HTML| <br>| ;
: <center>	( -- ) +HTML| <center>| ;
: </center>	( -- ) +HTML| </center>| ;
: <fieldset>	( -- ) +HTML| <fieldset>|  ;
: </fieldset>	( -- ) +HTML| </fieldset>| ;
: </font>	( -- ) +HTML| </font>| ;
: <formAction>	( actiontxt cnt -- ) +html| <form action="| +html  [char] " +1html ;
: </form>	( -- ) +html| </form>| ;
: <h2>		( -- ) +HTML| <h2>| ;
: </h2>		( -- ) +HTML| </h2>| ;
: <h3>		( -- ) +HTML| <h3>| ;
: </h3>		( -- ) +HTML| </h3>| ;
: <h4>		( -- ) +HTML| <h4>| ;
: </h4>		( -- ) +HTML| </h4>| ;
: <html>	( -- ) +HTML| <html>| ;
: </html>	( -- ) +HTML| </html>| ;
: <legend>	( -- ) +HTML| <legend>|  ;
: </legend>	( -- ) +HTML| </legend>| ;
: <strong>	( -- ) +HTML| <strong>| ;
: </strong>	( -- ) +HTML| </strong>| ;
: <svg>		( -- ) +HTML| <svg>| ;
: </svg>	( -- ) +HTML| </svg>| ;
: <td>		( -- ) +HTML| <td>|   ;
: <tdR>		( -- ) +HTML| <td valign="center" align="right">| ;
: </td>		( -- ) +HTML| </td>|  ;
: <tr>		( -- ) +HTML| <tr>|   ;
: </tr>		( -- ) +HTML| </tr>|  ;
: </table>	( -- ) +HTML| </table>| ;
: .HtmlSpace	( -- ) +HTML| &nbsp;| ;
: .HtmlBl	( -- ) +HTML|  | ;
: .forth-driven	( -- ) +HTML| <em>Cforth driven<em>| ;

: .HtmlSpaces	( n - )
    abs dup 2 <
      if    drop .HtmlBl
      else  0
            ?do .HtmlSpace
            loop
      then ;

: ms>Html	( ms - )
    #1000 /mod #60 /mod #60 /mod #24 /mod
    .Html  bl swap ##$ +html
    [char] : swap ##$ +html
    [char] : swap ##$ +html
    drop ;

: +Hfile	( filename cnt - )              \ Adding a file to HtmlPage$
    2dup file-exist?
      if    HtmlPage$ /HtmlPage +file
      else  cr type ."  not found."
      then ;

: favicon	( - )  HtmlPage$ off  s" favicon.ico"  +Hfile ;
: SignedDouble	( n - sign dabs ) s>d tuck dabs ;
: h6#		( sign d - )      base @ >r hex  # # # # # #  r> base !  ;
: (H6.)		( n - 6hex cnt )  SignedDouble <#  h6# rot sign #>  ;
: .HtmlZeros	( n - )           0 ?do +HTML| 0| loop ;
: "."		( n - "n" cnt )   SignedDouble <# hold"bl  #s  rot sign  hold" #> ;
: ".%"		( n - "n%" cnt )  SignedDouble <# hold"bl  [char] % hold  #s  rot sign  hold" #> ;
: ".px"		( n - "npx" cnt ) SignedDouble <# [char] x hold [char] p hold #s  rot sign #> ;

: (u.r)Html	( u w -- adr cnt )
    0 swap >r (d.) r> over - 0 max .HtmlZeros  pad place pad count  ;

: 4w.intHtml	( n - )       4 (u.r)Html +html ;

: "#h."		( n - "#6hexnum"$ cnt ) \ format for a color. Eg: Blue="#0000FF"
    SignedDouble <# hold"bl h6# rot sign  [char] # hold  hold" #> ;

: (h.)		( n -- hexnum$ cnt )
    SignedDouble <#  base @ >r hex #s  r> base !  rot sign  #> ;

: <FontSizeColor> ( pxSize RgbColor - )
   +HTML| <font color=| "#h." +html
   +HTML| style="font-size:| .Html +HTML| px" >| ;

: <<FontSizeColor>> ( pxSize RgbColor string cnt - )
   tmp$ place <FontSizeColor>  tmp$  count +html </font> ;

: <#td		( #HtmlCells - )
      +HTML| <td colspan= | dup "." +html
      +HTML| width=| 100 swap / 1 max ".%" +html ;

: <#tdC		( n - )  <#td +HTML| align="center"> | ;

\ Default CSS button as defined in btn at header_styles
: <Btn    ( btnCmd cnt - ) +html| <button NAME="Btn" VALUE="| +html  [char] " +1html ;
: Btn>    ( btntxt cnt - ) +html  +html| </button>| ;
: <CssButton> ( btntxt cnt btnCmd cnt - )  <Btn  +html| " class="btn">|  Btn> ;

: <CssBlueButton> ( btntxt cnt btnCmd cnt - )
   <Btn +html| " class="btn" style="background-color:#A0A0FF">| Btn> ;

: <CssBlue|GrayButton> ( btntxt cnt btnCmd cnt colorflag - )
      if   <CssBlueButton>
      else <CssButton>
      then ;

: <<TopLink>>	( LinkAdr cnt text cnt - )
   +HTML| <a target="_top" href="|  2swap +HTML +HTML| ">|
   +HTML +HTML| </a> | ;

0 value pagetitle$

: html-header	( -- )
  HtmlPage$ off
   s" HTTP/1.1 200"            +html_line
   s" Content-Type: text/html; charset=utf-8" +html_line
   s" Cache-Control: no-cache" +html_line
   s" Connection: close"       +html_line
   s" X-Content-Type-Options: nosniff" +html_line
   crlf$ +html  +HTML| <!DOCTYPE html><html lang="en">|
   +HTML| <head> |
   +HTML| <meta charset="utf-8">|
   pagetitle$ 0>
     if  +html| <title>| pagetitle$ count +html  +html| </title>|
     then
   +HTML| <meta name="viewport" content="width=device-width, initial-scale=1">|
   +html| <link rel="shortcut icon" href="/favicon.ico" type="image/x-icon">|
   +HTML| <style> #svgelem{ position: relative; left: 2%; } |
   s" fieldset { border:2px solid green;} svg|a:link, svg|a:visited {  cursor: pointer; } " +html
   +HTML| .btn { |             \ The properties are overwritable in the html page
   +HTML| display: block; |
   +HTML| background-color: #e7e7e7; |
   +HTML| border: none; |
   +HTML| color: black; |
   +HTML| padding: 5px 1px; |
   +HTML| text-align: center; |
   +HTML| text-decoration: none; |
   +HTML| display: inline-block; |
   +HTML| cursor: pointer; |
   +HTML| border-radius: 15px;
   +HTML| font-size: 22px; |
   +HTML| width: 80px; |
   +HTML| -webkit-touch-callout: none; |
   +HTML| -webkit-user-select: none; |
   +HTML| -khtml-user-select: none; |
   +HTML| } </style>
   +HTML| </head> | ;

TCP/IP DEFINITIONS


alias HTTP/1.1       noop
alias NoReply-HTTP   noop
alias get            noop
alias words words
alias order order
: +f ( - ) only forth  ;

ALSO HTML

: /favicon.ico	( - ) favicon ; \ loads favicon at htmlpage$

PREVIOUS FORTH DEFINITIONS ALSO HTML

: trim-stack	( ...?   - )
    sp@ sp0 @ 2dup =
       if     2drop
       else  u<  ." Stack "
                 if     ." trimmed."
                 else   ." underflow."
                 then
             sp0 @ sp! cr
      then ;

variable depth-target

: save-stack	( ...ToBeSaved - )
   s" depth-target off  begin depth while >r 1 depth-target +! repeat "
   evaluate ; immediate

: restore-stack	( - ...saved )
   s"  begin depth-target @ while  r> -1 depth-target +! repeat "
   evaluate ; immediate

: cut-line	( adrBuf lenBuf -- adr len ) 2dup $0d scan nip - ;

: evaluate_sealed ( adr len - res-catch )
  #255 min tcp/ip seal evaluate ;

\ evaluating_tcp/ip looks after stack mismatches and syntax errors
: evaluating_tcp/ip { adr len -- }
     save-stack               \ Save/empty the stack here
     adr len ['] evaluate_sealed catch dup 0<>
       if   drop              \ Handle undefined words
       then
     drop only forth
     trim-stack \ The stack should be empty without trimming it
     restore-stack            \ Restore the previous state
 ;

: remove_seperator ( adr len char - ) \ replace them by a space
   -rot bounds
      ?do  i c@ over =
             if   bl i c!
             then
      loop drop ;

: remove_seperators  ( adr len - )
  2dup [char] ? remove_seperator
  2dup [char] = remove_seperator
  2dup [char] _ remove_seperator
       [char] & remove_seperator ;

: see-request ( adrRequest lenRequest -- )
 ." Stack: " .s cr ." Request: " 2dup type
   cut-line  \ Extract the line with GET
   2dup remove_seperators   ." Evaluate: " 2dup type cr
   evaluating_tcp/ip
   50 0 do [char] - emit loop cr
   SendHtmlPage ;

: (handle-request) ( adrRequest lenRequest -- )
   cut-line  \ Extract the line with GET
   2dup remove_seperators
   evaluating_tcp/ip
   SendHtmlPage ;

defer handle-request   ' (handle-request) is handle-request

$fff  constant SOL_SOCKET
$80   constant SO_LINGER
$1006 constant SO_RCVTIMEO

: SetSolOpt	( tcp-sock optval p2 p1 size - )
   >r pad 2! r> pad rot SOL_SOCKET 4 roll setsockopt drop ;

: recv		( sock -- length|-1 )
   dup >r SO_RCVTIMEO #200 1 [ 2 cells ] literal SetSolOpt
   req-buf /req-buf r> lwip-read ;

: http-responder ( sock - )
   dup to lsock  recv dup 0>
     if   req-buf swap handle-request
     else drop
     then
   lsock lwip-close ;

PREVIOUS

\ \s
