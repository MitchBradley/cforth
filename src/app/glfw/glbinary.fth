\ OpenGL test for drawing an object from binary files
\ Each binary file contains an array of floats representing
\ some aspect of the object - triangle face vertices,
\ normals, etc.

\needs glfw-setup fl gltools.fth

: open-file-to-memory  ( name$ -- adr len )
   r/o open-file  abort" Can't open file"  >r   (         r: fid )
   r@ file-size throw drop                      ( len     r: fid )
   dup alloc-mem swap                           ( adr len r: fid)
   2dup r@ read-file  if                        ( adr len r: fid)
      free-mem                                  (         r: fid)
      r> close-file drop                        ( )
      true abort" Can't read file"
   then                                         ( adr len actual  r: fid)
   over <>  if                                  ( adr len         r: fid)
      free-mem                                  (         r: fid)
      r> close-file drop                        ( )
      true abort" Short read"
   then                                         ( adr len  r: fid)
   r> close-file drop
;

3 /n* constant /array

/array buffer: 'face-array
/array buffer: 'face-normal-array

: 'buf>adr  ( 'array-id -- adr len )  1 na+ @  ;
: 'buf>len  ( 'array-id -- adr len )  2 na+ @  ;

0 value #faces

: load-buffer-from-file  ( name$ type 'array-id -- len )
   2>r  open-file-to-memory       ( adr len  r: type 'array-id )
   2dup 2r> dup >r  setup-buffer  ( adr len  r: 'array-id )
\  r> drop  tuck free-mem                 ( len )
   swap r@ 1 na+ !  dup r> 2 na+ !
;

: get-full-arrays
   " faces.bin"          GL_ARRAY_BUFFER     'face-array         load-buffer-from-file  3 / /sf / to #faces
   " face_normals.bin"   GL_ARRAY_BUFFER     'face-normal-array  load-buffer-from-file  drop
\   " vertex_normals.bin"   GL_ARRAY_BUFFER     'face-normal-array  load-buffer-from-file  drop
;

0 [if]
0 value #vertices

/array buffer: 'vertex-array
/array buffer: 'normal-array
/array buffer: 'vertex-index-array
/array buffer: 'normal-index-array

: get-indexed-arrays  ( -- )
   " vertices.bin"       GL_ARRAY_BUFFER     'vertex-array       load-buffer-from-file  3 / /sf / to #vertices
   " normals.bin"        GL_ARRAY_BUFFER     'normal-array       load-buffer-from-file  drop

   " vertex_indices.bin" GL_ELEMENT_ARRAY_BUFFER 'vertex-index-array load-buffer-from-file  3 / /l /  to #faces
   " normal_indices.bin" GL_ELEMENT_ARRAY_BUFFER 'normal-index-array load-buffer-from-file  drop
;

: drawit1
   vertex{

   'vertex-array l@ GL_ARRAY_BUFFER glBindBuffer
   0 0  GL_FLOAT 3  glVertexPointer

   'vertex-index-array l@ GL_ARRAY_BUFFER glBindBuffer
   0 GL_UNSIGNED_INT  #faces 3 *  GL_TRIANGLES glDrawElements

   }vertex
;

: dump-obj  ( -- )
   6 places
   #vertices 0  ?do
      ." vn " 'normal-array 'buf>adr  i 3 sfloats * + .3floats  cr
      ." v "  'vertex-array 'buf>adr  i 3 sfloats * + .3floats  ." 0.752941 0.752941 0.752941" cr
   loop
   #faces 0  ?do
      ." f " 'vertex-index-array 'buf>adr  i 3 * la+
      dup l@ 1+ .// space
      dup la1+ l@ 1+ .// space
      2 la+ l@ 1+ .//  cr
   loop
;

: drawit2
   vertex{

   GL_NORMAL_ARRAY glEnableClientState

   'normal-array l@ GL_ARRAY_BUFFER glBindBuffer
   0 0  GL_FLOAT  glNormalPointer

   'vertex-array l@ GL_ARRAY_BUFFER glBindBuffer
   0 0  GL_FLOAT 3  glVertexPointer

   'vertex-index-array l@ GL_ARRAY_BUFFER glBindBuffer
   0 GL_UNSIGNED_INT  #faces 3 *  GL_TRIANGLES glDrawElements

   GL_NORMAL_ARRAY glDisableClientState

   }vertex
;

[then]

: getit   get-full-arrays    ;

: drawit0
   vertex{

   'face-array l@ GL_ARRAY_BUFFER glBindBuffer
   0  0  GL_FLOAT 3  glVertexPointer

   #faces 3 *  0  GL_TRIANGLES glDrawArrays
   }vertex
;

: alen  300f ;
: -alen  alen fnegate ;

: draw-coordinate-axes  ( -- )
  GL_LIGHTING glDisable

  5.5f  glLineWidth

  GL_LINES glBegin
   yellow

   0f  alen 0f  glVertex3d
   0f -alen 0f  glVertex3d

   red

    alen 0f 0f  glVertex3d
   -alen 0f 0f  glVertex3d

   green

   0f 0f  alen  glVertex3d
   0f 0f -alen  glVertex3d

   glEnd

   GL_LIGHTING glEnable
;

: drawit4
   vertex{

   glPushMatrix

   0f  0f 1f 90f glRotate

   rotation

   GL_NORMAL_ARRAY glEnableClientState

   'face-normal-array l@ GL_ARRAY_BUFFER glBindBuffer
   0 0  GL_FLOAT  glNormalPointer

   'face-array l@ GL_ARRAY_BUFFER glBindBuffer
   0 0  GL_FLOAT 3  glVertexPointer

   #faces 3 *  0  GL_TRIANGLES glDrawArrays

   GL_NORMAL_ARRAY glDisableClientState

   glPopMatrix

   }vertex

   draw-coordinate-axes

   swap-buffers
;

: spinit  ( -- )
   #360  0  do  i 0 0 rpy  drawit4  #20 ms loop
   #360  0  do  0 i 0 rpy  drawit4  #20 ms loop
   #360  0  do  0 0 i rpy  drawit4  #20 ms loop
;

: go
   glfw-setup
   getit
   setup-view
   lighting
   spinit
;
