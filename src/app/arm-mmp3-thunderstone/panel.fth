d# 1024 to hdisp  \ Display width
d# 1344 to htotal \ Display + FP + Sync + BP

d#  768 to vdisp  \ Display width
d#  806 to vtotal \ Display + FP + Sync + BP

: bright!  ( level -- )  drop  ;
: backlight-on  ( -- )  ;
: backlight-off  ( -- )  ;

: lcd-power-on  ( -- )
;

: init-panel  ( -- )
   lcd-power-on
;
