# Builds a MacOS host Forth application with OpenGL under GLFW

TOPDIR=../..

CONFIG += -DBITS64
CONFIG += -DFLOATING -DMOREFP
CONFIG += -DOPENGL

LIBS += -lglfw3  -framework Cocoa  -framework OpenGL  -framework IOKit  -framework CoreVideo

MYOBJS += glops.o

forth.o: glops.h

makegcalls: makegcalls.c
	cc -o $@ $<

obj_to_gl: $(TOPDIR)/src/app/glfw/obj_to_gl.c
	cc -o $@ $<

glfaces.bin: obj_to_gl


# test.obj is a Wavefront .obj file to render
# We preprocess it into a set of binary files for fast loading
glfaces.bin: ~/Downloads/test.obj
	./obj_to_gl <$<

glops.h: makegcalls

glops.h: $(TOPDIR)/src/cforth/glops.c
	./makegcalls <$<

include $(TOPDIR)/src/app/glfw/targets.mk
