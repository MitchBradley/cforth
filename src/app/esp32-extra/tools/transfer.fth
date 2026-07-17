marker -Transfer.fth lastacf .name #20 to-column .( 07-06-2026 ) \ By J.v.d.Ven
\ Much faster than xmodem. Use: transfer.  

\ Needed in Flash:
needs &favicon.ico tools/webcontrols.fth \ Extra tags and the HTML parser

DECIMAL ALSO HTML DEFINITIONS 

\ ---- Inline files --------------------------------------

create &transfer.html
s" transfer.html" load-bin

create &upload.html
s" upload.html" load-bin

create &download.html
s" download.html" load-bin

\ ---- Helpers outside the tcp/ip dictionary--------------

0 value filename-transfer

: init-transfer ( -- )
   filename-transfer 0= if  
      #44 allocate drop to filename-transfer 
   then
   htmlpage$ 0= if
      init-HtmlPage
   then
 ;

create 2crlf$ 4 c, $0d c, $0a c, $0d c, $0a c,  

#4096 value /chunk
0 value fid-transfer
0 value total-file-size
variable transferred-size
0 value last-chunk
variable #upload-retries

: .statistics-transfer ( -- ) .elapsed space transferred-size @ 0 u,.r ."  bytes." ;
: .elapsed_time ( -- ) ."  elapsed time: " ; 
: transfer-done? ( -- flag ) transferred-size @ total-file-size >= ;

: reset-transfer ( -- )
   init-transfer fid-transfer if
      fid-transfer close-file drop 
   then
   transferred-size off 0 to total-file-size 0 to fid-transfer 
   0 to last-chunk  #upload-retries off 
;
: AskChunk ( chunk# -- ) \  To receive the next chunk of a file
   HtmlPage$ off 
   s" HTTP/1.1 200 OK"  +html_line 
   s" Content-Type: text/plain"  +html_line
   s" "  +html_line
   +HTML| chunk | base @ swap .html base ! 
;
: msg-transfer ( adr count -- )
   HtmlPage$ off 
   s" HTTP/1.1 200 OK"  +html_line 
   s" Content-Type: text/plain"  +html_line
   s" Content-Length: " +html dup (.)  +html_line 
   s" "  +html_line
   +HTML SendHtmlPage
;
: ok-response ( -- ) \ The last chunk of a received file
   s" OK"  msg-transfer
; 
: find-chunk ( -- adr-chunk size flag ) \ Find the data of a received chunk
   req-buf /recv 2crlf$ count search    
   >r #4 /string 0 max r>
;
: check-size-chunk ( data-size -- flag )
   dup /chunk = if 
      drop true
   else
      transferred-size @ + total-file-size =  
   then 
; 
: error-upload ( adr-string cnt -- ) 
   2dup cr type
   transferred-size @ -rot msg-transfer
   reset-transfer ."  Transfer aborted. " 
   to total-file-size 
;
: store-chunk  ( adr-chunk size -- )
   tuck fid-transfer write-file if   
      drop s" Write error" error-upload
   else
      transferred-size +!
   then 
;
: error-download ( -- ) 
   s" "  msg-transfer
   reset-transfer ." Transfer aborted." 
;
: chunk-incomplete ( -- )
   #upload-retries @ #7 <  if
      #upload-retries @ #50 * vtaskdelay last-chunk AskChunk  
   else   
     s" Too many errors" error-upload    
   then
   1 #upload-retries +! 
;
: store-chunks  ( -- ) \ Unpack and add a chunk to a file
    find-chunk if \  adr-chunk size flag
      dup check-size-chunk if
         store-chunk transfer-done? if
            .statistics-transfer reset-transfer ok-response
         else  
            last-chunk 1+ AskChunk 0 #upload-retries ! \  Chunk OK, not all done yet
         then  
      else   
         2drop chunk-incomplete \ Chunk NOT ok, send it again
      then 
   then
;
: make-list-files                        
   0. 2>r 2dup open-dir? ?dup 0<> if     
      begin  
         dup next-file ?dup  
      while  
         >r -rot 2dup here place            
         r@ file-name cscount +html_line rot                  
         2r> + r> 1 + swap 2>r           
       repeat                            
       close-dir  2drop                  
   else 
      2drop
   then
   2r> 2drop
;
: transfer-responder ( timeout -- )  accept-reconnect  0= if http-responder then ;

\ ---- Endpoints for the application ---------------------

ALSO TCP/IP DEFINITIONS

: /ping ( -- ) 
   fid-transfer if
      ." Transfer aborted."
   then
   reset-transfer cr ." Transfer: /ping received, sending pong. "
   s" pong" msg-transfer
;
: /transfer.html ( -- )  \ Send the upload-page upload.html
   reset-transfer &transfer.html lcount +html 
;  
alias /transfer /transfer.html 
\ ---- Upload part ---------------------------------------
: /upload.html ( -- )    \ Send the upload-page upload.html
   reset-transfer &upload.html lcount +html 
;  
: /upload ( -- ) \ Starting to receive a file 
   parse-word 2drop parse-word fid-transfer 0= if 
      filename-transfer place 
   else
      2drop 
   then
;
: chunk ( decimal-n -- ) 
   to last-chunk 
;  
: replace_invalid_chars  ( adr len -- )
   2dup [char] ? [char] _ replace-all-by
   2dup [char] * [char] _ replace-all-by
   2dup [char] : [char] _ replace-all-by
   2dup [char] % [char] _ replace-all-by
   2dup [char] > [char] _ replace-all-by
   2dup [char] < [char] _ replace-all-by
   2dup [char] \ [char] _ replace-all-by
   2dup [char] / [char] _ replace-all-by
   2dup [char] | [char] _ replace-all-by
   2dup [char] " [char] _ replace-all-by
   2dup [char] ' [char] _ replace-all-by
   2dup [char] ` [char] _ replace-all-by
        [char] & [char] _ replace-all-by
;
\ Receiving chunks here. Requests like: 
\ POST /upload?file=ESP32C3.jpg&106=chunk&375921=fsize_upl HTTP/1.1
\ are converted by handle-request in webcontrols.fth to:
\ POST /upload file ESP32C3.jpg 106 chunk 375921 fsize_upl HTTP/1.1 \ and then evaluated by Forth
: fsize_upl ( n -- )  
   fid-transfer 0= if  \ First time for this request?
      time-reset to total-file-size transferred-size off
      filename-transfer count 2dup replace_invalid_chars r/w create-file if
         drop s" Can't create file" error-upload exit
      else 
         to fid-transfer  
         cr ." Receiving --> " filename-transfer count type .elapsed_time
      then
   else 
      drop
   then 
   store-chunks 
;
\ ---- Download part -------------------------------------
: /download.html   \ Send the download-page download.html 
   reset-transfer &download.html lcount +html 
;
: /ok- ( -- ) \ Handle sending chunks after repeating: GET /ok- HTTP/1.1
   HtmlPage$ cell+ /chunk fid-transfer read-file if  
      drop error-download 
   else 
      dup HtmlPage$ ! transferred-size +!  
      transfer-done? if
      .statistics-transfer reset-transfer 
      then
   then
;
: /filesize ( -- ) 
    \ Sends the file size in response to: GET /filesize file <filename> HTTP/1.1
    \ The request format must contain two words after /filesize:
    \   - "file" (literal keyword)
    \   - <filename> (the name of the file to check)
   time-reset reset-transfer safe-parse-word 2drop safe-parse-word 
   2dup filename-transfer place  
   r/o open-file if
      drop cr error-download ." File not found. "
   else
      cr ." Sending --> " filename-transfer count type .elapsed_time 
      dup file-size 2drop 
      swap to fid-transfer
      dup to total-file-size  
      HtmlPage$ off .html
   then     
;
: /filelist ( -- ) \ Sending a list of files
   HtmlPage$ off get-path make-list-files 
; 

: /target-reboot ( -- ) reboot ;

\ ---- Startup --------------------------------------------------------

ALSO HIDDEN DEFINITIONS  

: (transfer)  ( -- )
   base @ >r decimal wifi-connected@ 0=
      if  logon 
   then
   reset-transfer also tcp/ip seal bold ['] .HtmlBl set-page 
   listener-socket -1 = if              \ Is the server already running?
      http-listen                       \ To start the server do not repeat
   else
      cr ." Running the transfer server at: http://" ipaddr@ .ipaddr   
   then
   ." /transfer.html" norm cr
   ['] transfer-responder to responder  \ Accepting the html pages
   #1000 to poll-interval
   serve-http                           \ Contains the loop of the server
   cr only forth also forth             \ Exit on key press (the sockets stay open)
   r> base !
;

ALSO FORTH DEFINITIONS 

: transfer  ( -- )  [']  /transfer.html  to /home  (transfer) ;
\ ' see-request is handle-request \ To see the total received request for debugging
\ ' see-command is handle-request \ To see the command of the received request for debugging

' transfer is s

PREVIOUS PREVIOUS PREVIOUS PREVIOUS PREVIOUS ALSO FORTH       

\ \s
