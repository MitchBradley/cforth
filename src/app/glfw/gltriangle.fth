\ Simple OpenGL test for drawing a triangle with different buffering methods

\needs glfw-setup fl gltools.fth

\ Old-school method where you call a function for each vertex
: triangle  ( -- )
   setup-view
   rotation

   GL_TRIANGLES glBegin
   0.f  0.0f  1.0f glColor3
   0.f -0.4f -0.6f glVertex3d
   0.f  1.0f  0.0f glColor3
   0.f -0.4f  0.6f glVertex3d
   1.f  0.0f  0.0f glColor3
   0.f  0.6f  0.0f glVertex3d
   glEnd

   swap-buffers
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

variable 'face-array

\ In this version the data is copied into GPU memory once
\ and is accessed from there on every redraw.
: tri-setup-buffer
   tribuf /tribuf GL_ARRAY_BUFFER 'face-array setup-buffer
;

: tri-draw-buffer
   vertex{

   'face-array l@ GL_ARRAY_BUFFER glBindBuffer
   0 0 GL_DOUBLE 3 glVertexPointer
   
   3 0  GL_TRIANGLES glDrawArrays

   }vertex
;

\ In this version we use indices to refer to the vertices, which would
\ be useful in a large collection of triangles so vertices need not
\ be stored multiple times.

variable 'vertex-array
variable 'vertex-index-array

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
   glfwPollEvents
;
