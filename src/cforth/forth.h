// config.h configures C Forth 83 for the particular processor and OS
#include "config.h"

#ifndef MAKEPRIMS
#include "vars.h"
#include "prims.h"
#endif

typedef unsigned char  u_char;
typedef unsigned short u_short;

#define u_cell unsigned cell

#define INTERPRETING (cell)0
#define COMPILING (cell)1

struct voc_t {
    token_t    code_field;
    // token_t    last_word;
    token_t    voc_unum;
    token_t    voc_link;
};
#define vocabulary_t struct voc_t

struct header {
	cell magic, serial, dstart, dsize, ustart, usize, entry, res1;
};
extern struct header file_hdr;
extern const struct header builtin_hdr;

#define ERROR(s)   alerror(s, sizeof(s), up)

#ifdef BITS32
#define MAGIC 0x581120
#else
#define MAGIC 0x5820
#endif

#define ALLOCFAIL -10	/* XXX - out of the hat */
#define OPENFAIL  -11	/* XXX - out of the hat */
#define READFAIL  -12	/* XXX - out of the hat */
#define WRITEFAIL -13	/* XXX - out of the hat */
#define SEEKFAIL  -14	/* XXX - out of the hat */
#define SIZEFAIL  -15	/* XXX - out of the hat */
#define FLUSHFAIL -16	/* XXX - out of the hat */
#define DELFAIL   -17	/* XXX - out of the hat */
#define RENFAIL   -18	/* XXX - out of the hat */
#define RESIZEFAIL -19	/* XXX - out of the hat */
#define STATFAIL  -20	/* XXX - out of the hat */
#define CREATEFAIL -21	/* XXX - out of the hat */
