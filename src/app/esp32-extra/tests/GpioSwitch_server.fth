marker -GpioSwitch_server.fth  cr lastacf .name #19 to-column .( 01-07-2026 ) \ By J.v.d.Ven

\ Needed in ROM:
needs logon wifi.fth
needs HTML	      webcontrols.fth

DECIMAL ALSO HTML

\ ---- Settings -----------------------------------------------

#33 value GpioSwitch  cr .(  Used GPIO number: ) GpioSwitch .

\ ---- Application space --------------------------------------

3 constant GPIO_MODE_INPUT_OUTPUT \ For reading AND writing to a GPIO port
: ip-last-octet ( -- addr len ) ipaddr@ ipaddr$ 10 /string ;

: init-GpioSwitch ( -- ) 0 GPIO_MODE_INPUT_OUTPUT GpioSwitch gpio-mode ;
: switch-gpio ( on/off -- ) GpioSwitch gpio-pin! ;

\ ---- Create the static html for the application ---------------------

: TopStart ( -- )
   <br> <h3> 
   s" /transfer.html" s" Transfer" <<TopLink>> 
   +HTML| - | ip-last-octet +html                 
   </h3> 
;
: ApplicationPart ( -- ) \ The buttons, etc. for the application
   <br> <center> <h2> s" /home" s" Switch" <<TopLink>> </h2> 
   <h3> 
   <br> .HtmlSpace
   <br> s" On"  s" SwitchOnBtn" GpioSwitch gpio-pin@ <CssBlue|GrayButton>
   <br> <br> s" Off" s" SwitchOffBtn" GpioSwitch gpio-pin@ 0= <CssBlue|GrayButton>
   <br> <br> +html| GPIO | GpioSwitch .html +html|  is: | GpioSwitch gpio-pin@ if 
      +html| on|
   else
      +html| off|
   then
  </h3>
;

\ /home-page builds the home-page at HtmlPage$ after /home is evaluated by handle-request in http-responder
: /home-page ( -- ) 
   s" Gpio-switch" html-header
   +HTML| <body bgcolor="#FEFFE6">|
   s" BForm" <formAction>  \ Needed for the css buttons
   TopStart         \ The part at the top of the page
   ApplicationPart  \ The buttons etc
   </form>          \ Closing the form  
   </body> </html>  \ Ending the html page.
;                   \ Then http-responder will send the built page to the client

\ ---- Requests to evaluate  ------------------------------------------

ALSO TCP/IP DEFINITIONS \ Requests are limited to the tcp/ip dictionary

' /home-page is /home
alias /BForm noop \ Needed for the html buttons.

: SwitchOnBtn  ( -- ) 1 switch-gpio /home ;
: SwitchOffBtn ( -- ) 0 switch-gpio /home ;

FORTH DEFINITIONS ALSO TCP/IP 

: http-responder-switch ( timeout -- )
    timed-accept 0=
       if   http-responder
       then ;

\ ---- Startup --------------------------------------------------------

: start-switch-server  ( -- )
   htmlpage$ 0= if  init-HtmlPage  then
   ['] /home-page is /home 
   wifi-connected@ 0= if cr logon then
\  1800 SleepIfNotConnected                  \ Uncomment to sleep 30 min on no WiFi
   wifi-connected@ 0= if quit then           \ Quit if no WiFi
   cr ." Starting the web server... "
   init-GpioSwitch
   also tcp/ip seal 0 switch-gpio 
   bold  listener-socket -1 = if      \ Is the server already running?
      http-listen                     \ To start the server do not repeat
   else
      cr ." Running the web server at: http://" ipaddr@ .ipaddr   
   then
    ." /home" norm cr ['] http-responder-switch to responder
   #1000 to poll-interval
   serve-http                         \ Runs the loop of the server
   +a cr order                        \ Exit on key press (the sockets stay open)
; 

PREVIOUS PREVIOUS PREVIOUS

\ ' see-request is handle-request \ To see the total received request for debugging
\ ' see-command is handle-request \ To see the command of the received request for debugging

cr .free 
' start-switch-server is s \ Setting the short cut to restart the web server.
start-switch-server
\ \s
