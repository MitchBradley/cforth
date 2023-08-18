marker svg_plotter.f  cr lastacf .name #19 to-column .( 05-01-2023 ) \ By J.v.d.Ven
 \ To plot simple charts for a web client

needs /circular      extra.fth
needs Html	     webcontrols.fth

DECIMAL HTML DEFINITIONS

$00AF00 constant DkGreen
$000000 constant Black

begin-structure /DataParms  \ For additional information about the various fields for an SVG-plot
   field: >CfaDataLine      \ CFA of a pointer to a field in the first record in the logfile
   field: >CfaLastDataPoint \ CFA that gets the last data point in a plot.
  xfield: >FirstEntry
  xfield: >LastEntry
  xfield: >MinStat
  xfield: >MaxStat
  xfield: >AverageStat
  xfield: >Compression
   field: >Color
end-structure

: DataItem: ( <name> -- )  \ Define an inline record for additional information.
   /DataParms dup here swap allot dup value swap erase ;

\ Customizable:
900 value SvgWidth     \ Total width  including the labels
300 value SvgHeight    \ Total height including the labels

  7 value TopMargin    \ Margin at the top
 65 value BottomMargin \ For the labels at the bottom.
 50 value LeftMargin   \ For the labels at the left
 57 value RightMargin  \ For the labels at the right

\ Internal use:
f# 0e0 fvalue win.xleft
f# 0e0 fvalue win.xright
f# 0e0 fvalue win.ybot
f# 0e0 fvalue win.ytop
f# 0e0 fvalue win.xdif
f# 0e0 fvalue win.ydif

variable SXoffs
variable SXdiff
variable SYoffs
variable SYdiff

f# 0e0 fvalue MinYBot
f# 0e0 fvalue MinXBot
f# 0e0 fvalue MaxYtop
f# 0e0 fvalue MaxXtop

: Set-Gwindow  ( <xb> <yb> <xt> <yt> -- ) ( f: <xb> <yb> <xt> <yt> -- ) \ Zero is left down
    2over  SYoffs !      SXoffs !   rot  - SYdiff !    swap - SXdiff !  \ hardware coordinates!
    to win.ytop     to win.xright       to win.ybot       to win.xleft
    win.xright win.xleft F- TO win.xdif
    win.ytop  win.ybot   F- TO win.ydif ;

: Scale         ( f: <x> <y> -- )  ( -- <x> <y> )
    win.ybot  f-  win.ydif f/  SYdiff @ s>f f* f>s SYoffs @ +
    win.xleft f-  win.xdif f/  SXdiff @ s>f f* f>s sXoffs @ +  swap ;

12 value #Max_X_Lines \ Maximum vertical lines in the grid
 2 value    #X_Lines     \ # vertical lines in the grid. Must be at least 2
10 value #Max_Y_Lines \ # horizontal lines in the grid.

10 value xResolution    \ Number of plots between 2 gridlines on the x-axe
10 value xMaxResolution \ MAX Number of plots between 2 gridlines on the x-axe

: .x,y              ( x y - )      swap .Html +HTML| ,| .Html ;
: <polyline_points  ( - )          +HTML| <polyline points="| ;
: fpoly             ( f: x1 y1 - ) Scale .x,y .HtmlBl  ;

: <Poly_Line ( x1 y1 x2 y2 - )
    <polyline_points
     2swap .x,y .HtmlBl
           .x,y +HTML| " | ;

: <fpoly_line ( f: x1 y1 x2 y2 - )
    <polyline_points
    3 fpick 3 fpick fpoly Scale .x,y +HTML| " |
    fdrop fdrop ;

: poly_line>   ( stroke-width color - )
    +HTML| " fill="none" stroke="rgb(|
    dup 16 rshift .Html  +HTML| ,| dup $00FF00 and 8 rshift .Html +HTML| ,| $0000FF and .Html
    +HTML| )" stroke-width="| (h.) +html +HTML| "/> | ;


\ Statistical values
f# 0e0 fvalue MinYBotExact
f# 0e0 fvalue MaxYtopExact
f# 0e0 fvalue Average
f# 0e0 fvalue fTotal
 variable #added

DkGreen value color-y-labels-right
Black   value color-x-labels
65      value Rotation-x-labels

: SetXResolution ( #Xpoints - ) \ To prevent square waves
    dup 1+ 2 max #Max_X_Lines min to #X_Lines
    xMaxResolution / 1 max xMaxResolution min to xResolution ;

: Hw.MinMax ( - <xb> <yb>   <xt> <yt> )
    0 LeftMargin +  SvgHeight BottomMargin -   SvgWidth RightMargin -   0 TopMargin + ;

: fpoly-points> { #end #start &dataline -- } ( interval - )
    &DataLine >CfaDataLine @ to &DataLine
    #X_Lines xResolution * 1+ 0
      do  fdup i s>f f* #start s>f f+
          fdup f>s &DataLine execute f@ fpoly
      loop  fdrop ;

: FindPeak ( cfa-offset #end #start - ) ( f: - Ypart )
    2dup <=
      if drop swap execute f@
      else  dup 3 pick execute f@ fdup    \ f: fmin fmax
               do  i over execute f@ fdup
                          frot fmax fswap
                          frot fmin fswap
               loop drop
            fdup Average  f-   Average 3 fpick f- f> \ bigger than Average ?
               if   fswap fdrop  \ keep fmax as Y part  << Opt
               else fdrop        \ keep fmin as Y part
               then
       then ;

: LastPointExact ( #end #start  &DataLine  - ) ( f: - Ypart#End )
    nip >CfaDataLine perform f@ ;

: Maximized-fpoly-points> { #end #start ptr_dataline -- } ( f: interval - )
    #end  #start - s>f
    #X_Lines xResolution * dup >r s>f f/  fswap
    r> dup 1-  to #end 0
      do  fdup i  s>f f* #start s>f f+  fdup  f>s   \ X part
          i 0=
             if    1- 0 max ptr_dataline >CfaDataLine perform f@       \ First in Y part the plot
             else  f2dup fswap f- f>s #start max  \ ok
                   #end i =                                             \ last plot
                     if    ptr_dataline dup >CfaLastDataPoint perform  \ Get last point. Y part
                     else  ptr_dataline >CfaDataLine @ -rot FindPeak   \ Peak value Y part
                     then
             then
          fpoly
      loop   fdrop fdrop ;

: CalcAverage ( - ) ( f: - Average )  fTotal #added @ s>f f/ ;

: MinMaxYf! ( f: n - )
    fdup    MinYBot fmin to MinYBot
    MaxYtop fmax to MaxYtop ;

: Round10 ( f: Up/down-val n - rounded )  fswap f# 10e0 f* f+ fround f# 10e0 f/ ;

: SetMinMaxY { #end #start ptr_data -- }
    ptr_data  dup >CfaDataLine @ to ptr_data
    f# 0e0 to fTotal  #added off
    #end  #start 1- 0 max
    #start ptr_data execute f@ fdup  to MinYBot to MaxYtop
      do  i ptr_data execute f@ fdup
          fTotal f+ to fTotal  1 #added +!  MinMaxYf!
       loop   \ Takes ALL data of the logfile in account within the plotted range
    #end #start rot
    dup dup >r >CfaLastDataPoint perform MinMaxYf! \ Including the optional LastDataPoint
    r> >compression f@ f# 1e0 fmax
    MinYBot fdup to MinYBotExact fover f/ f# -0.5e0 Round10  to MinYBot
    MaxYtop fdup to MaxYtopExact       f*  f# 0.5e0 Round10  to MaxYtop
    CalcAverage to Average ;

: y-raster ( n - )
    dup s>f 1+ 0
      do  i  s>f f# 0e0    i s>f 3 fpick <fpoly_line 1 $708090 poly_line>
      loop  fdrop ;

: x-raster ( n - )
    dup s>f 1+ 0
      do  f# 0e0 i  s>f   2 fpick i s>f  <fpoly_line 1 $708090 poly_line>
      loop fdrop ;

: SetGrid ( #x #y - )
    swap 1-
    2>r Hw.MinMax  f# 0e0   f# 0e0
    2r@ drop dup s>f s>f set-gwindow
    2r@ drop x-raster
    Hw.MinMax  f# 0e0   f# 0e0
    r@ dup  s>f s>f set-gwindow
    2r> y-raster drop ;

: <poly_line_sequence  ( #end #start &dataline -- ) ( f: interval - )
    over s>f to MinXBot  2 pick  s>f to MaxXtop <polyline_points
    >r 2dup ( fdup f>s) r@  SetMinMaxY r>
 \  <xb> <yb>  <xt> <yt>   F:<xb>   <yb>     <xt>  <yt>
    Hw.MinMax               MinXBot MinYBot   MaxXtop  MaxYtop set-gwindow  \ Zero is left down
    Maximized-fpoly-points> ;

defer r>Time  ( - Relative_offset_to_time )
defer r>Date  ( - Relative_offset_to_date )

: x-label-text ( n - )
    dup  r>Time @ 100 / 4w.intHtml .HtmlBl
    r>Date @ dup 10000 / 10000 * - 4w.intHtml ;

: x-label ( F: x y - ) ( n 'Text color Rotation - )
    scale  swap 2dup
    +HTML| <text x="| 2 - .Html
    +HTML| " y="|     3 + .Html
    rot +HTML| " transform="rotate(| .Html  +HTML| ,|  8 - .Html  +HTML| ,|  .Html  +HTML| )"| \ deg Y x
    +HTML|  font-family="Verdana" font-size="12" |
    +HTML| fill=|  "#h." +html
    +HTML|  transform="rotate(30)">|
    execute  +HTML| </text>| ;

: x-labels { #start 'text color rotation } ( f: diff - )
    #X_Lines s>f 1- f/
    #X_Lines MaxXtop  MinXBot f-  dup 1- s>f f/ 0  \ 12 0
      do   fdup   i s>f f* f# 0e0 fmax MinXBot f+ f# 0e0 MinYBot f+
           #start i s>f 3 fpick f* fround f>s + 'Text color Rotation x-label
      loop  fdrop fdrop  ;

: Anchor-Justify-right  ( - justify$ cnt) s" end" ;
: Anchor-Justify-left   ( - justify$ cnt) s" start" ;
: Anchor-Justify-center ( - justify$ cnt) s" middle" ;

: y-label ( F: x y - ) { x-cor y-cor color 'justify -- }
    fswap fover scale swap
    +HTML| <text font-family="Verdana" font-size="12" text-anchor="|
    'Justify execute +html
    +HTML| " x="|
    x-cor + .Html
    +HTML| " y="|     y-cor + .Html
    +HTML| " fill=| color "#h." +html +HTML| >|
    (f.2) +html  +HTML| </text>| ;

: y-labels { x-cor y-cor color 'justify -- }
    #Max_Y_Lines  dup MaxYtop  MinYBot f- s>f f/ 1+ 0
      do    f# 0e0 MinXBot f+   fover i s>f f* f# 0e0 fmax MinYBot f+
            x-cor y-cor color 'Justify y-label
      loop  fdrop ;

: InitSvgPlot ( - )
    +HTML| <svg id="svgelem" width="| SvgWidth (.)  +html
    +HTML| " height="|  SvgHeight  (.)  +html
    +HTML| " xmlns="http://www.w3.org/2000/svg"> | ;

FORTH DEFINITIONS

\ \s
