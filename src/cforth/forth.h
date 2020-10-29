// config.h configures C Forth 83 for the particular processor and OS
#include "config.h"

#ifndef MAKEPRIMS
#include "vars.h"
#include "prims.h"
#endif

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
    u_cell magic, serial, dstart, dsize, ustart, usize, entry, res1;
};
extern struct header file_hdr;
extern const struct header builtin_hdr;

struct stacks {
  cell sp;
  cell sp0;
  cell rp;
  cell rp0;
};
void switch_stacks(struct stacks *old, struct stacks *new, cell *up);

#define FTHERROR(s)   alerror(s, sizeof(s)-1, up)

#ifdef BITS64
#define MAGIC 0x58112000570821
#else
#ifdef BITS32
#define MAGIC 0x581120
#else
#define MAGIC 0x5820
#endif
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
#define NOFILEIO   -22	/* XXX - out of the hat */

cell pfread(cell *sp, cell len, void *fid, cell *up);
cell pfwrite(void *adr, cell len, void *fid, cell *up);
cell pfseek(void *fid, u_cell high, u_cell low, cell *up);
cell pfposition(void *fid, u_cell *high, u_cell *low, cell *up);
cell *init_forth(void);
void init_io(int argc, char **argv, cell *up);
int next_arg(cell *up);
void linemode(void);
void keymode(void);
void restoremode(void);
void title(cell *up);
int lineedit(char *addr, int count, void *up);
void emit(u_char c, cell *up);
int system();
void set_input();
void exit(int);

int caccept(char *addr, cell count, cell *up);
int key_avail();
int key();
cell dosyscall();
cell pfopen(char *name, int len, int mode, cell *up);
cell pfcreate(char *name, int len, int mode, cell *up);
cell pfclose(cell f, cell *up);
cell pfflush(cell f, cell *up);
cell pfsize(cell f, u_cell *high, u_cell *low, cell *up);
void write_dictionary(char *name, int len, char *dict, int dictsize, cell *up, int usersize);
void pfmarkinput(void *fid, cell *up);
void pfprint_input_stack();

void memfree(char *, cell *up);
char * memresize(char *, u_cell, cell *up);
void fatal(char *str, cell *up);
void name_input(char *filename, cell *up);

void clear_log(cell *up);
void start_logging(cell *up);
void stop_logging(cell *up);
cell log_extent(cell *log_base, cell *up);

#define C(cname)  (cell (*)())cname,
#define V(index)       (up[index])
