#ifndef JAVA
#include <stdio.h>

#ifdef FLOATING
extern void floatop(int op);
extern cell *fintop(int op, cell *sp);
extern token_t *fparenlit(token_t *ip);
#endif


#if later
extern cell (*ccalls[])();
extern cell doccall(cell (*function_adr)(), int format, cell *up);
#endif

extern cell freadline(cell f, int sp, int up);

static int strindex(int adr1, int len1, int adr2, int len2);
static void fill_bytes(int to, int length, int with);
static int digit(int base, int c);
static void ip_canonical(int adr, int len, int up);
static int tonumber(int adrp, int len, int nhigh, int nlow, int up);
static void type(int  adr, int len, int up);
#ifndef JAVA
#define u_cell unsigned int
static void umdivmod(u_cell *dhighp, u_cell *dlowp, u_cell u);
static void umtimes(u_cell *dhighp, u_cell *dlowp, u_cell u1, u_cell u2);
static void mtimesdiv(cell *dhighp, cell *dlowp, cell n1, cell n2);
#endif
static void cmove(int from, int to, int length);
static void cmove_up(int from, int to, int length);
static int compare(int adr1, int len1, int adr2, int len2);
static void reveal(int up);
static void hide(int up);
static int alnumber(int adr, int len, int nhigh, int nlow, int up);

#ifndef NOSYSCALL
/* System call error reporting */
extern int errno;

extern int system();
#endif

extern set_input();
extern void exit();

extern emit(char c, int up);
extern int key_avail();
extern int key();
extern int dosyscall();
extern cell pfopen(int name, int len, int mode, int up);
extern cell pfclose(cell f, int up);
#endif
