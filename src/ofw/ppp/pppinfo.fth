\ See license at end of file
purpose: Interface to PPP information package

0 value ppp-info-ih
: close-ppp-info  ( -- )  ppp-info-ih close-package  0 to ppp-info-ih  ;
: open-ppp-info  ( package-name$ -- )
   ppp-info-ih  if  close-ppp-info  then   ( package-name$ )
   [char] : left-parse-string $open-package  to ppp-info-ih
   ppp-info-ih 0= abort" Can't open PPP info"
;

: ?open-ppp-info  ( -- )
   ppp-info-ih 0=  if  " ppp-info" open-ppp-info  then
;

: $ppp-info  ( ??? name$ -- ??? )  ?open-ppp-info ppp-info-ih $call-method  ;

: save-ppp-info  ( -- )  " save" $ppp-info  ;
: set-ppp-info-field  ( value$ name$ -- )
   $ppp-info 2drop  " replace-last" $ppp-info
;
: clear-ppp-info  ( -- )
   " ppp-info:repair" open-ppp-info
   " reset" $ppp-info
   save-ppp-info
   close-ppp-info
;
: set-default-ppp-info  ( -- )
   clear-ppp-info
   " 3"                " #retries"          set-ppp-info-field
   " 38400"            " baud"              set-ppp-info-field
   " Others"           " modem-name"        set-ppp-info-field
   " ATZ"              " modem-init$"       set-ppp-info-field
   " ATDT"             " modem-dial$"       set-ppp-info-field
   " +++"              " modem-interrupt$"  set-ppp-info-field
   " ATH"              " modem-hangup$"     set-ppp-info-field
   " Others"           " modem-name"        set-ppp-info-field
   " No Login Script"  " script"            set-ppp-info-field
   save-ppp-info
;

: ?save-ppp-info  ( -- )
   " Save changes in CMOS RAM?" confirmed?  if  save-ppp-info  then
;
: $edit-item  ( name$ -- )
   2dup type ." : " $ppp-info $edit  " replace-last" $ppp-info
;

: edit-ppp-info  ( -- )
   " phone#"             $edit-item
   " #retries"           $edit-item
   " baud"               $edit-item
   " dns-server0"        $edit-item
   " dns-server1"        $edit-item
   " domain-name"        $edit-item
   " javaos-config-url"  $edit-item
   " client-ip"          $edit-item
   " modem-name"         $edit-item
   " modem-init$"        $edit-item
   " modem-dial$"        $edit-item
   " modem-interrupt$"   $edit-item
   " modem-hangup$"      $edit-item
   " script"             $edit-item
   " expect$1"           $edit-item
   " expect$2"           $edit-item
   " expect$3"           $edit-item
   " expect$4"           $edit-item
   " expect$5"           $edit-item
   " send$1"             $edit-item
   " send$2"             $edit-item
   " send$3"             $edit-item
   " send$4"             $edit-item
   " send$5"             $edit-item
   " pap-id"             $edit-item
   " pap-password"       $edit-item
   " chap-name"          $edit-item
   " chap-secret"        $edit-item

   ?save-ppp-info
;
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
