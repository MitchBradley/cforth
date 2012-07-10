false value fb-shown?
h# 8009.1100 constant fb-on-value
: show-fb  ( -- )  fb-on-value h# 190 lcd!  ;
: ?visible  ( -- )
   \ Stop polling after the check button is seen for the first time,
   \ thus avoiding conflicts with OFW's use of the check button
   fb-shown?  if  exit  then
   show-fb?  if  show-fb  true to fb-shown?  then
;

fl ../arm-xo-1.75/fbnums.fth
: blank-display-lowres  ( -- )
   \ Setup the panel path with the normal resolution
   init-lcd

[ifdef] notdef-lowres4x3
   \ This trick uses the hardware scaler so we can display a blank
   \ white screen very quickly, without spending a lot of time
   \ filling the frame buffer with a constant value.

   \ Set the source resolution to 4x3
    4 3 wljoin h# 104 lcd!

   \ Set the pitch to 0 so we only have to fill one line
   0 h# fc lcd!

   \ Fill one line of the screen
   \ Since hdisp-lowres is 4, one line is a single longword!
   display-pa  4  h# ffffffff lfill

   \ Set the depth to 8 bpp
   h# 800a1100 h# 190 lcd!
[else]
   \ Start with all display data sources off
   0 h# 190 lcd!

   \ Set the source resolution to 12x9
   h# 9000c h# 104 lcd!

   \ Set the pitch to 6 (12 pixels * 4 bits/pixel / 8 bits/byte )
   6 h# fc lcd!

   \ Set the no-display-source background color to white
   h# ffffffff h# 124 lcd!

   \ Fill the rudimentary frame buffer with white
   diagfb-pa 6 9 *  h# ff fill

   \ Turn on the display if the user presses the check key
   ?visible
[then]

   \ Enable the display
   init-panel
;
