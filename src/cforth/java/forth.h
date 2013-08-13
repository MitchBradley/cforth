// config.h configures C Forth 83 for the particular processor and OS
#include "config.h"

#ifndef MAKEPRIMS
#include "vars.h"
#include "prims.h"
#endif

#ifdef INCLUDE_LOCALS
#define MAXLOCALS 8
struct local_name {
    int   l_data;
    int   code;
    char  name[33];
};
#endif

// struct voc_t
#define code_field 0
#define voc_unum 1
#define voc_link 2

#ifdef JAVA
#  define SCOPE1   private
#  define SCOPE2   private
#  define SCOPE3   private
#else
   extern int *word_dict;
#  define true 1
#  define SCOPE1   static
#  define SCOPE2
#  define SCOPE3
#endif

#define DS(ptr)    word_dict[ptr]
#define RS(ptr)    word_dict[ptr]
#define DATA(ptr)  word_dict[ptr]
#define TOKEN(ptr) word_dict[ptr]
#define CHARS(ptr) word_dict[ptr]

#define V(index)       (DATA(up + index))
#define T(index)       V(index)

#define hash(voc) (up + DATA(voc+voc_unum) )

#define unumcomma(n)     DATA(V(DP)) = n; V(DP)++
#define nfetch(ptr) DATA(ptr)
#define nstore(ptr, value) DATA(ptr) = (value)
#define ncomma(n)	 nstore(V(DP), n); V(DP)++
#define compile(token)  tokstore(token, V(DP)); V(DP)++
#define linkcomma(token) tokstore(token, V(DP)); V(DP)++

#define LAST         (T(LASTP))
#define ERROR(s)   strerror(s, up)

// Function prototypes
#ifdef JAVA
#define IntArray int[] 
#else
typedef char * String;
typedef int * IntArray;

extern void tokstore(int token, int adr);
extern int name_from(int );
extern void place_name(int adr, cell len, int previous, int up);
extern int parse_word(int, int );
extern int parse(int delim, int sp, int up);
extern void create_word(int cf, int up);
extern void makeimmed(int up);
extern int alfind(int adr, cell len, int up);
extern int find_local(int adr, int plen, int up);
extern int search_wid(int adr, cell len, int wid, int up);
extern int canon_search_wid(int adr, cell len, int wid, int up);
extern void warn(int adr, cell len, int up);
extern void alerror(int str, int len, int up);
extern int isinteractive(void);
extern int moreinput(void);
extern void makeimmediate(int up);
extern void header(int adr, cell len, int up);
extern void str_create(int adr, cell len, int cf, int up);
extern void spush(cell n, int up);
extern int execute_xt(int xt, int up);
extern void write_dictionary(int name, int len, int dictsize, int up, int usersize);
extern int caccept(int addr, int count, int up);

extern String altostr(int adr, cell len, String cstrbuf, int maxlen);
extern String cstr(String s, int adr, int up);
extern int *aln_alloc(cell nbytes);
extern void cprint(String  str, int up);
extern char* getmem(cell nbytes);
extern int execute_word(String s, int up);
extern int init_compiler(int here, int xlimit, int *xup);
extern void strerror(String s, int up);

#endif
