\ Tools to perform some common OpenGL operations

\needs GL_NONE fl glconstants.fth

#640 value width
#640 value height

$00033002 constant GLFW_STICKY_KEYS
$00020005 constant GLFW_DECORATED

0 value win
: glfw-setup  ( -- )
   set-error-callback
   glfwInit 0= abort" glfwInit failed"
   \ 0 GLFW_DECORATED glfwWindowHint
   0 0 " Nod Backspin Test" height width glfwCreateWindow to win
   win glfwMakeContextCurrent   
   1 glfwSwapInterval
   glewInit
   1 GLFW_STICKY_KEYS win glfwSetInputMode
;

0 value GLFW_RELEASE
1 value GLFW_PRESS
2 value GLFW_REPEAT
#32 constant GLFW_KEY_SPACE
#48 constant GLFW_KEY_0
#65 constant GLFW_KEY_A
#256 constant GLFW_KEY_ESC
#257 constant GLFW_KEY_ENTER
: >glfw-key  ( char -- n )
   dup bl =  if  drop GLFW_KEY_SPACE exit  then

   upc dup 'A' 'Z' between  if   ( char )
      'A' - GLFW_KEY_A + exit    ( -- n )
   then                          ( char )
   dup '0' '9' between  if       ( char )
      '0' - GLFW_KEY_0 + exit    ( -- n )
   then                          ( char )
   drop true abort" Unsupported GLFW key"
   \ Not yet supporting ',-./;=[\]`
   \ Not yet supporting Esc Enter Tab Backspace Insert Delete Left Right Up Down
   \ and others
;
: glfw-key?  ( keycode -- flag )
   dup  win glfwGetKey  if      ( keycode )
      begin                     ( keycode )
         glfwPollEvents         ( keycode )
         dup win glfwGetKey     ( keycode pressed? )
      0= until                  ( keycode )
      drop true                 ( true )
   else                         ( keycode )
      drop false                ( false )
   then                         ( flag )
;

0 value eroll
0 value pitch
0 value yaw

: rpy  to yaw  to pitch  to eroll  ;

defer rotation
: rpy-rotation  ( -- )
  0f 1f 0f  eroll float          glRotate
  0f 0f 1f  pitch float fnegate  glRotate
  1f 0f 0f  yaw   float fnegate  glRotate
;
' rpy-rotation to rotation

: projection  ( -- )  GL_PROJECTION glMatrixMode  glLoadIdentity  ;
: model  ( -- )  GL_MODELVIEW  glMatrixMode  glLoadIdentity  ;

: pixel-coordinates  ( -- )
   projection
   1f -1f  height float  0  width float  0  glOrtho
;

: gl-clear  ( -- )
   GL_DEPTH_BUFFER_BIT GL_COLOR_BUFFER_BIT or glClear
;

: full-viewport  ( -- )  height width 0 0 glViewport  ;
: 3d-view  ( -- )
   projection
   glLoadIdentity
   -70f 70f   -70f 70f   70f -70f  glOrtho  
   model
   glLoadIdentity
   0f 1f 0f  0f 0f 0f  1f 1f 0.3f  gluLookAt
;
: setup-view
   full-viewport
   gl-clear
   3d-view
;

: vertex{  ( -- )
   gl-clear
   GL_VERTEX_ARRAY glEnableClientState
;
: }vertex  ( -- )
   GL_VERTEX_ARRAY glDisableClientState
;

: swap-buffers  ( -- )  win glfwSwapBuffers  ;
 
: setup-buffer  ( adr len type 'id -- )
   dup 1 glGenBuffers                      ( adr len type 'id )
   l@ over glBindBuffer                    ( adr len type )
   >r GL_STATIC_DRAW -rot r> glBufferData  ( )
;

: .3floats  ( adr -- )
   >r r@ sf@ f.  r@ 1 sfloats + sf@ f.  r> 2 sfloats + sf@ f.
;
: .//  ( n -- )  dup (.) type  ." //" (.) type  ;


\ These can be used only when lighting/shading is off
: white   ( -- )   1.0f  1.0f  1.0f glColor3  ;
: red     ( -- )   0.0f  0.0f  1.0f glColor3  ;
: green   ( -- )   0.0f  1.0f  0.0f glColor3  ;
: blue    ( -- )   1.0f  0.0f  0.0f glColor3  ;
: cyan    ( -- )   1.0f  1.0f  0.5f glColor3  ;
: magenta ( -- )   1.0f  0.5f  1.0f glColor3  ;
: yellow  ( -- )   0.5f  1.0f  1.0f glColor3  ;
: pink    ( -- )   0.5f  0.5f  1.0f glColor3  ;
: light-green   ( -- )   0.5f  1.0f  0.5f glColor3  ;
: half  0.5f 0.5f 0.5f glScale  ;
: double  2f 2f 2f glScale  ;

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
   0f 0f 0f  0f glClearColor   \ Black background
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
