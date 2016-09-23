\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: nvalias.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
id: @(#)nvalias.fth 1.3 98/04/08
purpose: Implements the nvalias persistent devalias feature
copyright: Copyright 1992-1998 Sun Microsystems, Inc.  All Rights Reserved

\ "Permanent" devaliases

only forth also hidden also
hidden definitions
headerless

: next-field  ( str -- rem-str first-str )  -leading  bl left-parse-string  ;

\ True if the current line contains a devalias command with the
\ same name as the one we're looking for.

: this-alias?  ( name-str -- name-str flag )
   after  next-field          ( name-str rem-str first-field-str )
   " devalias" $=  if         ( name-str rem-str )
      next-field              ( name-str rem-str' 2nd-field-str )
      5 pick  5 pick  $=  if  ( name-str rem-str' )
         2drop  true  exit    ( name-str true )
      then                    ( name-str rem-str' )
   then                       ( name-str rem-str )
   2drop false                ( name-str false )
;

\ delete-old-alias leaves the cursor at the beginning of an empty line.
\ If there was already an alias of the indicated name, it is deleted
\ and the cursor is left on that line.  Otherwise, a new line is
\ created at the end of the file, and the cursor is left on that line.

: delete-old-alias  ( name-str -- )
   buflen 0=  if  2drop exit  then
   begin
      this-alias?  if                       ( name-str )
         2drop                              ( )
         kill-to-end-of-line
         kill-to-end-of-line   exit
      then                                  ( name-str )
   last-line? 0=  while                     ( name-str )
      next-line  beginning-of-line          ( name-str )
   repeat                                   ( name-str )
   2drop                                    ( )
   beginning-of-file
;

: safe-insert  ( adr len -- )
   tuck  (insert-characters)     ( len actual )
   dup forward-characters        ( len actual )
   <>  if  -1 throw  then  ( len )
;
: make-new-alias  ( name-str path-str -- )
   " devalias " safe-insert   ( name-str path-str )
   2swap safe-insert          ( path-str )
   "  " safe-insert           ( path-str )
   safe-insert                ( )
   split-line                 ( )
;

: get-field  ( adr len -- rem-adr rem-len name-adr name-len )
   next-field  dup  0= abort" Usage: nvalias name path"
;

: edit-nvramrc  ( -- )
   nvramrc-buffer  if
      ." 'nvalias' and 'nvunalias' cannot be executed while 'nvedit' is in progress." cr
      ." Use 'nvstore' or 'nvquit' to finish editing nvramrc, then try again." cr
      abort
   then

   allocate-buffer

   [ also hidden ]

   nvbuf /nvramrc-max 0 0 false start-edit
;

forth definitions
headers

\ Creates a "devalias <name> <path>" command line in nvramrc, with name
\ and path fields given by the two strings on the stack.  If nvramrc already
\ contains a devalias line with the same name, that entry is first deleted,
\ and the new entry replaces it at the same location in nvramrc.  Otherwise,
\ the new entry is placed at the beginning of nvramrc.
\
\ If there is insufficient space in nvramrc for the new devalias command,
\ a message to that effect is displayed and $nvalias aborts without
\ modifying nvramrc.
\
\ If nvramrc was successfully modified, the new "devalias" command is
\ executed immediately, creating a new memory-resident alias.
\
\ If nvramrc is currently being edited (i.e. nvedit has been executed,
\ but has not been completed with either nvstore or nvquit), $nvalias
\ aborts with an error message before taking any other action.

: $nvalias  ( name-str path-str -- )
   edit-nvramrc

   2over  delete-old-alias                     ( name-str path-str )
   2over 2over  ['] make-new-alias catch  if   ( ? )
      finish-edit drop
      deallocate-buffer
      true abort" Can't create new alias because nvramrc is full"
   then                                        ( name-str path-str )

   $devalias                                   ( )
   nvramrc-buffer finish-edit  ( adr len )  to nvramrc
   true to use-nvramrc?

   [ previous ]
   deallocate-buffer
;

\ nvalias is like $nvalias, except that the name and path arguments is taken
\ from the command line following the nvalias command, instead of from
\ the stack.

: nvalias  \ name path  ( -- )
   optional-arg$   get-field                     ( rem-str name-str )
   2swap get-field  2swap 2drop                  ( name-str path-str )
   $nvalias
;

\ If nvramrc contains a "devalias" command line with the same name
\ as the string on the stack, $nvunalias deletes that line.  Otherwise,
\ nvramrc remains unchanged.
\
\ $nvunalias aborts with an error message if nvramrc is currently being edited,
\ i.e. nvedit has been executed, but has not been completed with either
\ nvstore or nvquit.

: $nvunalias  ( name-str -- )
   edit-nvramrc   delete-old-alias

   [ also hidden ]
   nvramrc-buffer  finish-edit  to nvramrc
   [ previous ]

   deallocate-buffer
;

\ nvunalias is like $nvalias, except that the name argument is taken
\ from the command line following the nvunalias command, instead of from
\ the stack.

: nvunalias  \ name  ( -- )
   optional-arg$   get-field                     ( rem-str name-str )
   2swap 2drop  $nvunalias
;
only forth also definitions

