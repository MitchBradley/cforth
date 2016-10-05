\ Stub versions of OFW frame buffer support

\needs column#  0 value column#
\needs line#    0 value line#
\needs #columns 0 value #columns
\needs #lines   0 value #lines
\needs #scroll-lines  1 value #scroll-lines

0 value inverse?
0 value inverse-screen?
\needs draw-character defer draw-character
defer reset-screen
defer toggle-cursor
defer erase-screen
defer blink-screen          ( -- )
defer invert-screen         ( -- )
defer insert-characters     ( n -- )
\needs delete-characters defer delete-characters     ( n -- )
defer insert-lines          ( n -- )
\needs delete-lines defer delete-lines          ( n -- )
defer draw-logo             ( line# laddr lwidth lheight -- )
\needs frame-buffer-adr 0 value frame-buffer-adr
\needs screen-height 0 value screen-height
\needs screen-width 0 value screen-width
0 value window-top
0 value window-left
0 value foreground-color
0 value background-color

: default-font ;
: set-font ;
0 value char-height
\needs char-width 0 value char-width
: >font ;
0 value fontbytes

: fb8-draw-character    ( char -- )  ;
: fb8-reset-screen      ( -- )  ;
: fb8-toggle-cursor     ( -- )  ;
: fb8-erase-screen      ( -- )  ;
: fb8-blink-screen      ( -- )  ;
: fb8-invert-screen     ( -- )  ;
: fb8-insert-characters ( #chars -- )  ;
: fb8-delete-characters ( #chars -- )  ;
: fb8-insert-lines      ( #lines -- )  ;
: fb8-delete-lines      ( #lines -- )  ;
: fb8-draw-logo         ( line# ladr lwidth lheight -- )  ;
: fb8-install           ( width height #cols #lines -- )  ;

alias is-install drop
alias is-remove drop
alias is-selftest drop
