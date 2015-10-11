\ GL test
decimal

: gcall:  ( n "name" -- )  create ,  does> @ glop   ;

fl gcalls.fth

$0 constant GL_NONE
$0400 constant GL_FRONT_LEFT
$0401 constant GL_FRONT_RIGHT
$0402 constant GL_BACK_LEFT
$0403 constant GL_BACK_RIGHT
$0404 constant GL_FRONT
$0405 constant GL_BACK
$0406 constant GL_LEFT
$0407 constant GL_RIGHT
$0408 constant GL_FRONT_AND_BACK
$0409 constant GL_AUX0
$040A constant GL_AUX1
$040B constant GL_AUX2
$040C constant GL_AUX3

\ ShadingModel
$1D00 constant GL_FLAT
$1D01 constant GL_SMOOTH

\ FrontFaceDirection
$0900 constant GL_CW
$0901 constant GL_CCW

$0B71 constant GL_DEPTH_TEST

$00000001 constant GL_CURRENT_BIT                    
$00000002 constant GL_POINT_BIT                      
$00000004 constant GL_LINE_BIT                       
$00000008 constant GL_POLYGON_BIT                    
$00000010 constant GL_POLYGON_STIPPLE_BIT            
$00000020 constant GL_PIXEL_MODE_BIT                 
$00000040 constant GL_LIGHTING_BIT                   
$00000080 constant GL_FOG_BIT                        
$00000100 constant GL_DEPTH_BUFFER_BIT               
$00000200 constant GL_ACCUM_BUFFER_BIT               
$00000400 constant GL_STENCIL_BUFFER_BIT             
$00000800 constant GL_VIEWPORT_BIT                   
$00001000 constant GL_TRANSFORM_BIT                  
$00002000 constant GL_ENABLE_BIT                     
$00004000 constant GL_COLOR_BUFFER_BIT               
$00008000 constant GL_HINT_BIT                       
$00010000 constant GL_EVAL_BIT                       
$00020000 constant GL_LIST_BIT                       
$00040000 constant GL_TEXTURE_BIT                    
$00080000 constant GL_SCISSOR_BIT                    
$000fffff constant GL_ALL_ATTRIB_BITS                

$1700 constant GL_MODELVIEW                      
$1701 constant GL_PROJECTION                     
$1702 constant GL_TEXTURE                        

$0000 constant GL_POINTS                         
$0001 constant GL_LINES                          
$0002 constant GL_LINE_LOOP                      
$0003 constant GL_LINE_STRIP                     
$0004 constant GL_TRIANGLES                      
$0005 constant GL_TRIANGLE_STRIP                 
$0006 constant GL_TRIANGLE_FAN                   
$0007 constant GL_QUADS                          
$0008 constant GL_QUAD_STRIP                     
$0009 constant GL_POLYGON                        

$88E4 constant GL_STATIC_DRAW
$8892 constant GL_ARRAY_BUFFER
$8893 constant GL_ELEMENT_ARRAY_BUFFER

$0B50 constant GL_LIGHTING
$0B51 constant GL_LIGHT_MODEL_LOCAL_VIEWER
$0B52 constant GL_LIGHT_MODEL_TWO_SIDE
$0B53 constant GL_LIGHT_MODEL_AMBIENT

$1200 constant GL_AMBIENT
$1201 constant GL_DIFFUSE
$1202 constant GL_SPECULAR
$1203 constant GL_POSITION
$1204 constant GL_SPOT_DIRECTION
$1205 constant GL_SPOT_EXPONENT
$1206 constant GL_SPOT_CUTOFF
$1207 constant GL_CONSTANT_ATTENUATION
$1208 constant GL_LINEAR_ATTENUATION
$1209 constant GL_QUADRATIC_ATTENUATION

$1400 constant GL_BYTE
$1401 constant GL_UNSIGNED_BYTE
$1402 constant GL_SHORT
$1403 constant GL_UNSIGNED_SHORT
$1404 constant GL_INT
$1405 constant GL_UNSIGNED_INT
$1406 constant GL_FLOAT
$1407 constant GL_2_BYTES
$1408 constant GL_3_BYTES
$1409 constant GL_4_BYTES
$140A constant GL_DOUBLE

$1600 constant GL_EMISSION
$1601 constant GL_SHININESS
$1602 constant GL_AMBIENT_AND_DIFFUSE
$1603 constant GL_COLOR_INDEXES

$4000 constant GL_LIGHT0
$4001 constant GL_LIGHT1
$4002 constant GL_LIGHT2
$4003 constant GL_LIGHT3
$4004 constant GL_LIGHT4
$4005 constant GL_LIGHT5
$4006 constant GL_LIGHT6
$4007 constant GL_LIGHT7

$8074 constant GL_VERTEX_ARRAY
$8075 constant GL_NORMAL_ARRAY
$8076 constant GL_COLOR_ARRAY
$8077 constant GL_INDEX_ARRAY
$8078 constant GL_TEXTURE_COORD_ARRAY
$8079 constant GL_EDGE_FLAG_ARRAY
$807A constant GL_VERTEX_ARRAY_SIZE
$807B constant GL_VERTEX_ARRAY_TYPE
$807C constant GL_VERTEX_ARRAY_STRIDE
$807E constant GL_NORMAL_ARRAY_TYPE
$807F constant GL_NORMAL_ARRAY_STRIDE
$8081 constant GL_COLOR_ARRAY_SIZE
$8082 constant GL_COLOR_ARRAY_TYPE
$8083 constant GL_COLOR_ARRAY_STRIDE
$8085 constant GL_INDEX_ARRAY_TYPE
$8086 constant GL_INDEX_ARRAY_STRIDE
$8088 constant GL_TEXTURE_COORD_ARRAY_SIZE
$8089 constant GL_TEXTURE_COORD_ARRAY_TYPE
$808A constant GL_TEXTURE_COORD_ARRAY_STRIDE
$808C constant GL_EDGE_FLAG_ARRAY_STRIDE
$808E constant GL_VERTEX_ARRAY_POINTER
$808F constant GL_NORMAL_ARRAY_POINTER
$8090 constant GL_COLOR_ARRAY_POINTER
$8091 constant GL_INDEX_ARRAY_POINTER
$8092 constant GL_TEXTURE_COORD_ARRAY_POINTER
$8093 constant GL_EDGE_FLAG_ARRAY_POINTER
$2A20 constant GL_V2F
$2A21 constant GL_V3F
$2A22 constant GL_C4UB_V2F
$2A23 constant GL_C4UB_V3F
$2A24 constant GL_C3F_V3F
$2A25 constant GL_N3F_V3F
$2A26 constant GL_C4F_N3F_V3F
$2A27 constant GL_T2F_V3F
$2A28 constant GL_T4F_V4F
$2A29 constant GL_T2F_C4UB_V3F
$2A2A constant GL_T2F_C3F_V3F
$2A2B constant GL_T2F_N3F_V3F
$2A2C constant GL_T2F_C4F_N3F_V3F
$2A2D constant GL_T4F_C4F_N3F_V4F

$0200 constant GL_NEVER
$0201 constant GL_LESS
$0202 constant GL_EQUAL
$0203 constant GL_LEQUAL
$0204 constant GL_GREATER
$0205 constant GL_NOTEQUAL
$0206 constant GL_GEQUAL
$0207 constant GL_ALWAYS

#640 value width
#480 value height

0 value win
: glfw-setup  ( -- )
   set-error-callback
   glfw-init
   0 0 " Test Window" height width glfw-create-window to win
   win glfw-make-context-current   
   1 glfw-swap-interval
   glew-init
;

0 value eroll
0 value pitch
0 value yaw

: rpy  to yaw  to pitch  to eroll  ;

3.1415926535f fconstant fpi
: >radians  ( i.degrees -- f.radians )  float 180.f f/ fpi f*  ;

: rotation  ( -- )
\   1f 0f 0f  .050f get-msecs float f*  glRotate
  0f 1f 0f  eroll float          glRotate
  0f 0f 1f  pitch float fnegate  glRotate
  1f 0f 0f  yaw   float fnegate  glRotate
;

\ : ratio  ( -- d )  height float width float f/  ;
: ratio 1f ;

: pv    GL_PROJECTION glMatrixMode  glLoadIdentity  ;
: mv    GL_MODELVIEW  glMatrixMode  glLoadIdentity  ;

: pixel-coordinates  ( -- )
   pv  1f -1f  height float  0  width float  0  glOrtho
;

: setup-view
   height width 0 0 glViewport
   GL_COLOR_BUFFER_BIT glClear
   pv   

\   ratio fnegate  ratio  -1f 1f 1f -1f  glOrtho
\   ratio fnegate  ratio  -10f 10f 0f 0f  glOrtho
\    1f 0f   0f height float   width float  0f  glOrtho  
\    ratio fnegate  ratio  -10f 10f 0f 0f  glOrtho

   -70f 70f   -70f 70f   70f -70f  glOrtho  

\   ratio  ratio fnegate  -10f 10f 10f -10f  glFrustum
   mv
   0f 1f 0f  0f 0f 0f  1f 1f 0.3f  gluLookAt
;

: axis  ( -- )
;
: vertex{
   GL_DEPTH_BUFFER_BIT GL_COLOR_BUFFER_BIT or glClear
   GL_VERTEX_ARRAY glEnableClientState
;
: }vertex
   GL_VERTEX_ARRAY glDisableClientState
;
: swap-buffers  win glfw-swap-buffers  ;
 
: setup-buffer  ( adr len type 'id -- )
   dup 1 glGenBuffers                      ( adr len type 'id )
   l@ over glBindBuffer                    ( adr len type )
   >r GL_STATIC_DRAW -rot r> glBufferData  ( )
;

: open-file-to-memory  ( name$ -- adr len )
   r/o open-file  abort" Can't open file"  >r   (         r: fid )
   r@ file-size                                 ( len     r: fid )
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

: .3floats  ( adr -- )
   >r r@ sf@ f.  r@ 1 sfloats + sf@ f.  r> 2 sfloats + sf@ f.
;
: .//  ( n -- )  dup (.) type  ." //" (.) type  ;


: drawit0
   vertex{

   'face-array l@ GL_ARRAY_BUFFER glBindBuffer
   0  0  GL_FLOAT 3  glVertexPointer

   #faces 3 *  0  GL_TRIANGLES glDrawArrays
   }vertex
;

: yellow  ( -- )   0.5f  1.0f  1.0f glColor3  ;
: red     ( -- )   0.5f  0.5f  1.0f glColor3  ;
: cyan    ( -- )   1.0f  1.0f  0.5f glColor3  ;
: green   ( -- )   0.5f  1.0f  0.5f glColor3  ;
: half  0.5f 0.5f 0.5f glScale  ;
: double  2f 2f 2f glScale  ;

: alen  300f ;
: -alen  alen fnegate ;
: gravity  ( -- )
\  glPushMatrix
\  mv
\  0f 0f 1f  30f glRotate

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

\   glPopMatrix
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

   gravity

   swap-buffers
;

$7fffffff constant maxl

create ambient0    0.3f sf,  0.3f sf,  0.3f sf,  1f sf,
\ create ambient0    0.2f sf,  0.2f sf,  0.2f sf,  1f sf,
create diffuse0    0.3f sf,  0.3f sf,  0.3f sf,  1f sf,
create specular0   0.1f sf,  0.1f sf,  0.1f sf,  1f sf,
\ create specular0   0.2f sf,  0.2f sf,  0.2f sf,  1f sf,
create position0   -30f sf, -30.f sf, -10.f sf,  1f sf,

create ambient1    .05f sf,  .05f sf,  .05f sf,  1f sf,
create diffuse1    0.1f sf,  0.1f sf,  0.1f sf,  1f sf,
create specular1   0.1f sf,  0.1f sf,  0.1f sf,  1f sf,
create position1   -10f sf,  5.0f sf, -30.f sf,  1f sf,

create ambient2    .05f sf,  .05f sf,  .05f sf,  1f sf,
create diffuse2    0.1f sf,  0.1f sf,  0.1f sf,  1f sf,
create specular2   0.1f sf,  0.1f sf,  0.1f sf,  1f sf,
create position2    10f sf,  5.0f sf, -30.f sf,  1f sf,

create ambient3    .05f sf,  .05f sf,  .05f sf,  1f sf,
create diffuse3    0.1f sf,  0.1f sf,  0.1f sf,  1f sf,
create specular3   0.1f sf,  0.1f sf,  0.1f sf,  1f sf,
create position3   0.0f sf, 20.0f sf,  0.0f sf,  1f sf,

create reflect    0.8f sf, 0.8f sf,  0.8f sf,  1f sf,

create mcolor     0.75f sf, 0.75f sf,  0.75f sf,  1f sf,

: lighting
   0f 0f 0f 0f glClearColor
\   1f 1f 1f 1f glClearColor
   1f glClearDepth

   GL_DEPTH_TEST glEnable
   GL_LEQUAL glDepthFunc

   GL_SMOOTH glShadeModel
\  GL_FLAT glShadeModel

   GL_LIGHTING glEnable
   GL_LIGHT0 glEnable
   GL_LIGHT1 glEnable
   GL_LIGHT2 glEnable
   GL_LIGHT3 glEnable

   ambient0  GL_AMBIENT  GL_LIGHT0 glLightfv
   diffuse0  GL_DIFFUSE  GL_LIGHT0 glLightfv
   specular0 GL_SPECULAR GL_LIGHT0 glLightfv
   position0 GL_POSITION GL_LIGHT0 glLightfv
   
   ambient1  GL_AMBIENT  GL_LIGHT1 glLightfv
   diffuse1  GL_DIFFUSE  GL_LIGHT1 glLightfv
   specular1 GL_SPECULAR GL_LIGHT1 glLightfv   
   position1 GL_POSITION GL_LIGHT1 glLightfv

   ambient2  GL_AMBIENT  GL_LIGHT2 glLightfv
   diffuse2  GL_DIFFUSE  GL_LIGHT2 glLightfv
   specular2 GL_SPECULAR GL_LIGHT2 glLightfv
   position2 GL_POSITION GL_LIGHT2 glLightfv
   
   ambient3  GL_AMBIENT  GL_LIGHT3 glLightfv
   diffuse3  GL_DIFFUSE  GL_LIGHT3 glLightfv
   specular3 GL_SPECULAR GL_LIGHT3 glLightfv
   position3 GL_POSITION GL_LIGHT3 glLightfv
   
   GL_CW glFrontFace
   mcolor GL_AMBIENT_AND_DIFFUSE GL_FRONT glMaterialfv
   reflect GL_SPECULAR GL_FRONT glMaterialfv

   #50 GL_SHININESS GL_FRONT glMateriali
;


: spinit  ( -- )
\   #360  1 0  do  drawit4  1f 1f 1f  1f  glRotate  #40 ms loop
   #360  0  do  i 0 0 rpy  drawit4  #20 ms loop
   #360  0  do  0 i 0 rpy  drawit4  #20 ms loop
   #360  0  do  0 0 i rpy  drawit4  #20 ms loop
;
: go
   glfw-setup
   getit
   setup-view
   lighting
   \   0f  0f 1f 120f glRotate
\      0f  0f 1f 90f glRotate
   spinit
;


\ create TRIANGLE_TEST
[ifdef] TRIANGLE_TEST
\needs 'vertex-array  /array buffer: 'vertex-array
\needs 'vertex-index-array /array buffer: 'vertex-index-array

: object
   GL_TRIANGLES glBegin
   0.f  0.0f  1.0f glColor3
   0.f -0.4f -0.6f glVertex3d
   0.f  1.0f  0.0f glColor3
   0.f -0.4f  0.6f glVertex3d
   1.f  0.0f  0.0f glColor3
   0.f  0.6f  0.0f glVertex3d
   glEnd
;

: triangle  ( -- )
   setup-view
   rotation
   object
   win glfw-swap-buffers
;

create tribuf
  -1.0f f,  -1.0f f,  -0.5f f,
   1.0f f,  -1.0f f,  -0.5f f,
   0.0f f,   0.75f f,  0.5f f,
here tribuf - constant /tribuf

\ In this version the data stays in host memory and is processed
\ one vector at a time during redraw
: tri-draw-array
   vertex{

   yellow

   tribuf 0 GL_DOUBLE 3 glVertexPointer
   /tribuf 3 / /f /   0  GL_TRIANGLES glDrawArrays

   }vertex
;

\ In this version the data is copied into GPU memory once
\ and is accessed from there on every redraw.
: tri-setup-buffer
   tribuf /tribuf GL_ARRAY_BUFFER 'vertex-array setup-buffer
;

: tri-draw-buffer
   vertex{

   'vertex-array l@ GL_ARRAY_BUFFER glBindBuffer
   0 0 GL_DOUBLE 3 glVertexPointer
   
   3 0  GL_TRIANGLES glDrawArrays

   }vertex
;

\ In this version we use indices to refer to the vertices, which would
\ be useful in a large collection of triangles so vertices need not
\ be stored multiple times.

create tri-indices  0 l, 1 l, 2 l,  here tri-indices - constant /tri-indices
: tri-setup-indices
   tribuf      /tribuf      GL_ARRAY_BUFFER         'vertex-array       setup-buffer
   tri-indices /tri-indices GL_ELEMENT_ARRAY_BUFFER 'vertex-index-array setup-buffer
;

: tri-draw-indices
   vertex{

   'vertex-array l@ GL_ARRAY_BUFFER glBindBuffer
   0 0 GL_DOUBLE 3 glVertexPointer
   
   'vertex-index-array l@ GL_ARRAY_BUFFER glBindBuffer
   0 GL_UNSIGNED_INT  3 GL_TRIANGLES glDrawElements

   }vertex
;

: tri-go  ( -- )
   glfw-setup
   tri-setup-buffer
   red  tri-draw-buffer
   swap-buffers
   glfw-poll-events
;
[then]
