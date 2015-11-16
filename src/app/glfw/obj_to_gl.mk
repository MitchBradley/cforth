# This makefile fragment creates various .bin files from test.obj
# test.obj is a Wavefront file listing vertices and faces
# The .bin files faces.bin, face_normals.bin, vertices.bin, normals.bin,
# normal_indices.bin, vertex_normals.bin, and vertex_indices.bin are
# arrays suitable for direct use by OpenGL
# glbinary.fth contains test code that can read and render them.

THISDIR := $(dir $(lastword $(MAKEFILE_LIST)))

faces.bin: obj_to_gl

# test.obj is a Wavefront .obj file to render
# We preprocess it into a set of binary files for fast loading
faces.bin: test.obj
	./obj_to_gl <$<

obj_to_gl: $(THISDIR)/obj_to_gl.c
	cc -o $@ $<
