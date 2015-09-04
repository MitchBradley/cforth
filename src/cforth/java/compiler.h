extern void tokstore(int token, int adr);

#define MAXLOCALS 8
struct local_name {
    int   l_data;
    int   code;
    char  name[33];
};

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

#ifdef JAVA
#else
   extern int *word_dict;
//   extern char char_dict[];
#  define DS(ptr)    word_dict[ptr]
#  define RS(ptr)    word_dict[ptr]
#  define DATA(ptr)  word_dict[ptr]
#  define TOKEN(ptr) word_dict[ptr]
#  define CHARS(ptr) char_dict[ptr]
#  define true 1

extern char *altocstr(int adr, cell len, char *cstrbuf, int maxlen);
extern char *cstr(char *s, int adr, int up);
extern int *aln_alloc(cell nbytes);
extern void cprint(char * str, int up);
extern char* getmem(cell nbytes);
extern int execute_word(char *s, int up);
extern int init_compiler(int *origin, int here, int xlimit, int *xup);
extern void cstrerror(char *s, int up);
#define ERROR(s)   cstrerror(s, up)

#endif

#define V(index)       (DATA(up + index))
#define T(index)       V(index)

#define hash(voc) (up + DATA(voc+voc_unum) )

#define unumcomma(n)     DATA(V(DP)) = n; V(DP)++
#define nfetch(ptr) DATA(ptr)
#define nstore(ptr, value) DATA(ptr) = (value)
#define ncomma(n)	 nstore(V(DP), n); V(DP)++
#define compile(token)  tokstore(token, V(DP)); V(DP)++
#define linkcomma(token) tokstore(token, V(DP)); V(DP)++

static inline int XT_FROM_CT(int ct, int up)
{
    return ct;
}
static inline int CT_FROM_XT(int adr, int up)
{
    return adr;
}

#define LAST         (XT_FROM_CT(T(LASTP), up))
