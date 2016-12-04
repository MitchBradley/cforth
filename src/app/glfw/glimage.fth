0 value image-buf
0 value /image-buf
0 value rle-buf
0 value /rle-buf
: free-image  ( -- )
   /image-buf  if  image-buf /image-buf free-mem  0 to /image-buf  then
   /rle-buf    if  rle-buf   /rle-buf   free-mem  0 to /rle-buf    then
;
: read-image-file  ( filename$ -- )
   2dup r/o open-file  if       ( filename$ fid )
      drop ." Can't open " type cr  ( )
      abort
   else                         ( filename$ fid )
      nip nip                   ( fid )
   then                         ( fid )

   dup file-size throw drop  to /image-buf     ( )
   /image-buf alloc-mem to image-buf           ( fid )
   image-buf /image-buf 2 pick  read-file  if  ( fid len )
      free-image                               ( fid len )
      drop close-file drop                     ( )
      true abort" Can't read file"             ( )
   then                                        ( fid len )
   drop close-file drop                        ( )
;

: +ib  ( n -- adr )  image-buf +  ;
: tga-bgr>rgb  ( 'data bpp height width -- )
   rot 8 /           ( 'data height width bytes/pixel )
   >r * r@ *         ( 'data #bytes r: bytes/pixel )
   r> -rot           ( bytes/pixel 'data #bytes )
   bounds ?do        ( bytes/pixel )
      i c@  i 2+ c@  ( blue red bytes/pixel )
      i c!  i 2+ c!  ( bytes/pixel )
   dup +loop         ( bytes/pixel )
   drop
;
0 value rle-index
0 value /pixel
: rle-run  ( adr -- adr' )
   dup 1+ swap c@                              ( adr' rle-code )
   dup $7f and 1+  /pixel *                    ( adr rle-code #bytes )
   swap $80 and  if                            ( adr #bytes )
      \ RLE
      rle-buf rle-index +  over  bounds  ?do   ( adr #bytes )
         over i /pixel move                    ( adr #bytes )
      /pixel +loop                             ( adr #bytes )
      swap /pixel + swap                       ( adr' #bytes )
   else                                        ( adr #bytes )
      \ Raw
      2dup  rle-buf rle-index +  swap move     ( adr #bytes )
      tuck +  swap                             ( adr' #bytes )
   then                                        ( adr' #bytes )
   rle-index +  to rle-index                   ( adr' )
;
: rle-decode  ( 'data bpp height width -- 'data' bpp height width )
   3dup * swap 8 /           ( 'data bpp height width #pixels /pixel )
   dup to /pixel  *          ( 'data bpp height width #bytes )
   >r  3 roll  r>            ( bpp height width 'data #bytes )
   dup alloc-mem to rle-buf  ( bpp height width 'data #bytes )
   to /rle-buf               ( bpp height width 'data )
   0 to rle-index            ( bpp height width 'data )
   begin  rle-index /rle-buf <  while    ( bpp height width 'data )
      rle-run                ( bpp height width 'data' )
   repeat                    ( bpp height width 'data )
   drop                      ( bpp height width )
   >r 2>r  rle-buf  2r> r>   ( 'data' bpp height width )
;
: decode-tga-image  ( -- 'data bpp height width )   
   #18 +ib  0 +ib c@ +      ( 'data )
   #16 +ib c@               ( 'data bpp )
   #14 +ib le-w@            ( 'data bpp height )
   #12 +ib le-w@            ( 'data bpp height width )
   #02 +ib c@  $0a =  if  rle-decode  then    ( 'data bpp height width )
   2over 2over tga-bgr>rgb  ( )
;
: bpp>gl-format  ( bpp -- gl-format )  #32 =  if  GL_RGBA  else  GL_RGB  then  ;

struct
   /l field >texture
   /w field >width
   /w field >height
   /c field >bpp
end-struct /texture-info

: setup-texture  ( 'data bpp height width 'texture -- )
   >r  r@ >width w!  r@ >height w!  r@ >bpp c! ( 'data r: 'texture )
   
   r@ >texture  1  glGenTextures               ( 'data r: 'texture )
   r@ >texture l@ GL_TEXTURE_2D glBindTexture  ( 'data r: 'texture )

   1 GL_UNPACK_ALIGNMENT glPixelStorei         ( 'data r: 'texture )
   r@ >bpp c@ bpp>gl-format                    ( 'data format  r: 'texture )

   GL_UNSIGNED_BYTE  swap                      ( 'data BY format  r: 'texture )
   0  r@ >height w@  r> >width w@              ( 'data BY format 0 height width )
   3 pick  0 GL_TEXTURE_2D  glTexImage2D       ( )

   free-image                                  ( )
;
: load-tga-texture  ( filename$ 'texture -- )
   >r  read-image-file decode-tga-image  r> setup-texture
;
: 2d-pixel-view  ( -- )
   projection
   glLoadIdentity
   -1f 1f  height float 0f  width float 0f  glOrtho
   model
   glLoadIdentity
;

: enable-texture  ( -- )  GL_TEXTURE_2D glEnable  ;
: disable-texture  ( -- )  GL_TEXTURE_2D glDisable  ;

: 2d-textured-pixel-view  ( -- )
   2d-pixel-view
   enable-texture
   GL_LIGHTING glDisable
   1f 1f 1f glColor3
;

0 value imgx  0 value imgy  0 value imgw  0 value imgh
: gl-show-image-wh  ( 'texture x y w h -- )
   to imgh to imgw  to imgy  to imgx                ( 'texture )
   2d-textured-pixel-view

   dup l@ GL_TEXTURE_2D glBindTexture               ( 'texture )
   GL_NEAREST GL_TEXTURE_MIN_FILTER GL_TEXTURE_2D glTexParameteri
   GL_NEAREST GL_TEXTURE_MAG_FILTER GL_TEXTURE_2D glTexParameteri

   GL_QUADS glBegin
   1f 0f glTexCoord2f   imgy         imgx         glVertex2i
   1f 1f glTexCoord2f   imgy         imgx imgw +  glVertex2i
   0f 1f glTexCoord2f   imgy imgh +  imgx imgw +  glVertex2i
   0f 0f glTexCoord2f   imgy imgh +  imgx         glVertex2i
   glEnd

   disable-texture
;
: gl-show-image-full-size  ( 'texture x y -- )
   2 pick >width w@          ( 'texture x y w )
   3 pick >height w@         ( 'texture x y w h )
   gl-show-image-wh          ( )
;
