DOC= \
	readme

FTHSRC= \
	atxy.fth	block.fth	blockio.fth	brackif.fth	\
	buffer.fth	callfind.fth	case.fth	ccalls.fth	\
	cmdcom.fth	comment.fth	compat.fth	compiler.fth	\
	config.fth	control.fth	decomp.fth	decompm.fth	\
	dot.fth		double.fth	dump.fth	environ.fth	\
	floatops.fth	format.fth	id.fth		interp.fth	\
	load.fth	loadblk.fth	locals.fth	marker.fth	\
	misc.fth	needs.fth	page.fth	patch.fth	\
	postpone.fth	sift.fth	stringar.fth	struct.fth	\
	th.fth		util.fth	words.fth

CSRC= \
	compiler.c	compiler.h	config.h	extend.c	\
	floatops.c	forth.c		forth.h		fprims.h	\
	io.c		makename.c	malloca.c	mallocl.c	\
	meta.c

ALL = ${DOC} ${FTHSRC} ${CSRC}

zip:
	@zip cforth93.zip ${ALL}
