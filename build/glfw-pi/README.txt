Notes about CForth OpenGL with Raspberry Pi

Raspbian Wheezy does not have glfw3; you need at least Raspbian Jessie.

Raspberry Pi has OpenGL ES 2.0, which does not support the old-style
fixed pipeline for lighting.  You have to use the modern GLSL shader
language stuff.  Currently there is no Forth example code for how
to do that.

Triangle demos and color rendering work.
