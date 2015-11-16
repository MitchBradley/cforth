\needs read-image-file fl glimage.fth

0 value font-width
0 value font-height
0 value font-bpp
0 value font-data
#21 value char-width
#32 value char-height
#32 constant first-glyph
: /font-data  ( -- n )  font-width font-height * font-bpp 8 / *  ;

0 [if]  \ Unused
: decode-tga-font  ( -- )
   decode-tga-image  ( bpp height width 'data )
   to font-width  to font-height  to font-bpp  to font-data
   #21 to char-width
   #32 to char-height
   #32 to first-glyph
;
[then]

: decode-bff2-font  ( -- )
   #02 +ib le-l@ to font-width
   #06 +ib le-l@ to font-height
   #10 +ib le-l@ to char-width
   #14 +ib le-l@ to char-height
   #18 +ib c@   to font-bpp
   #19 +ib c@   to first-glyph
   \ Actual (variable-width) char widths start at 20
   #276 +ib     to font-data
;

\ Not yet supporting GL_LUMINANCE
: font-format  ( -- n )  font-bpp bpp>gl-format  ;

variable 'font-texture
: $gl-load-font  ( filename$ -- )
   read-image-file
   decode-bff2-font

   'font-texture 1 glGenTextures
   'font-texture l@ GL_TEXTURE_2D glBindTexture

   1 GL_UNPACK_ALIGNMENT glPixelStorei

   GL_NEAREST GL_TEXTURE_MIN_FILTER GL_TEXTURE_2D glTexParameteri
   GL_NEAREST GL_TEXTURE_MAG_FILTER GL_TEXTURE_2D glTexParameteri

   GL_CLAMP_TO_EDGE GL_TEXTURE_WRAP_S GL_TEXTURE_2D glTexParameteri
   GL_CLAMP_TO_EDGE GL_TEXTURE_WRAP_T GL_TEXTURE_2D glTexParameteri

   font-data  GL_UNSIGNED_BYTE  font-format  0  font-height font-width
   font-format  0 GL_TEXTURE_2D glTexImage2D

   free-image
;

: load-our-font  ( -- )  " ../glfw/SimHei.bff" $gl-load-font  ;

: glyphs/row  ( -- n )  font-width char-width /  ;
: col-factor  ( -- f )  char-width float  font-width float  f/  ;
: row-factor  ( -- f )  char-height float  font-height float  f/  ;

\ u and v are x and y fractional offsets within the texture, from 0f to 1f
0f fvalue u0  0f fvalue u1  0f fvalue v0  0f fvalue v1

: >glyph  ( char -- )
   first-glyph -                ( char# )
   glyphs/row /mod              ( col row )
   float row-factor f* fdup to v0  row-factor f+ to v1  ( col )
   float col-factor f* fdup to u0  col-factor f+ to u1  ( )
;
0 value txtx  0 value txty
: gl-char  ( char -- )
   'font-texture l@ GL_TEXTURE_2D glBindTexture
   GL_QUADS glBegin
   >glyph
   v1 u0 glTexCoord2f   txty                txtx               glVertex2i
   v1 u1 glTexCoord2f   txty                txtx char-width +  glVertex2i
   v0 u1 glTexCoord2f   txty char-height +  txtx char-width +  glVertex2i
   v0 u0 glTexCoord2f   txty char-height +  txtx               glVertex2i
   txtx char-width + to txtx
   glEnd
;
: set-text-xy  ( x y -- )  to txty  to txtx  ;

: text{  ( -- )  2d-textured-pixel-view  1f 1f 1f glColor3  ;
: }text  ( -- )  disable-texture  ;

: t  ( -- )  \ For testing
   glfw-setup load-our-font
   full-viewport gl-clear
;

: gl-type  ( adr len -- )  bounds  ?do  i c@ gl-char  loop  ;

: text-at  ( adr len x y -- )  text{ set-text-xy gl-type  }text  ;
