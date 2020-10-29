extern void tokstore(token_t token, token_t *adr);

#define MAXLOCALS 8
struct local_name {
    cell  l_data;
    token_t code;
    u_char  name[33];
};

extern token_t * name_from(u_char *);
extern void place_name(char *adr, cell len, token_t previous, cell *up);
extern cell parse_word(u_char **, cell *);
extern cell parse(u_char delim, cell *sp, cell *up);
extern void create_word(token_t cf, cell *up);
extern void makeimmed(cell *up);
extern int alfind(char *adr, cell len, xt_t *xtp, cell *up);
extern token_t * aligned(u_char *addr);
extern void align(cell *);
extern void xt_align(cell *);
extern u_char *aln_alloc(cell nbytes, cell *up);
extern int find_local(char *adr, int plen, xt_t *xtp, cell *up);
extern int search_wid(char *adr, cell len, vocabulary_t *wid, xt_t *xtp, cell *up);
extern int canon_search_wid(char *adr, cell len, vocabulary_t *wid, xt_t *xtp, cell *up);
extern void warn(char *adr, cell len, cell *up);
extern void alerror(char *str, int len, cell *up);
extern void cprint(const char *str, cell *up);
extern char* getmem(u_cell nbytes, cell *up);
extern int isinteractive(void);
extern int isstandalone(void);
extern int moreinput(cell *up);
extern void makeimmediate(cell *up);
extern void header(char *adr, cell len, cell *up);
extern void place_cf(token_t cf, cell *up);
extern void init_compiler(const u_char *origin, u_char *ramorigin, token_t topct, u_char *here, u_char *xlimit, cell *up);
extern char *altocstr(char *adr, u_cell len, char *cstrbuf, int maxlen);
extern void spush(cell n, cell *up);
extern int execute_xt(xt_t xt, cell *up);
extern int execute_word(char *s, cell *up);


#define T(index)       ((token_t)up[index])

#define hash(voc,adr,len) (token_t *)( (char *)up + (voc)->voc_unum )

#define unumcomma(n)     *(unum_t *)V(DP) = (unum_t)n; V(DP) += sizeof(unum_t)
#ifdef T16
static inline cell nfetch(cell *ptr)
{
    return (cell)(((u_cell)((uint16_t *)ptr)[1] << 16) | ((uint16_t *)ptr)[0]);
}
static inline void nstore(cell *ptr, cell value)
{
    ((uint16_t *)ptr)[0] = (uint16_t)value;
    ((uint16_t *)ptr)[1] = (uint16_t)(value >> 16);
}
#else
#define nfetch(ptr) *(ptr)
#define nstore(ptr, value) *((cell *)ptr) = (value)
#endif
#define ncomma(n)	 nstore((cell *)V(DP), (cell)n); V(DP) += sizeof(cell)
#define compile(token)  tokstore((token_t)(token), (token_t *)V(DP)); V(DP) += sizeof(token_t)
#define linkcomma(token) tokstore((token), (token_t *)V(DP)); V(DP) += sizeof(token_t)

static inline xt_t XT_FROM_CT(token_t ct, cell *up)
{
    int offset;
    if ( (offset = ct - (token_t)V(RAMCT)) >= 0)
        return (token_t *)V(RAMTOKENS) + offset;
    return (xt_t)V(TORIGIN) + ct;
}
static inline token_t CT_FROM_XT(xt_t adr, cell *up)
{
    int offset;
    offset = adr - (xt_t)V(TORIGIN);
    if (offset >= 0 && offset < V(RAMCT))
        return (token_t)offset;
    return  (token_t)(adr - (token_t *)V(RAMTOKENS)) + (token_t)V(RAMCT);
}

#define LAST         ((u_char *)XT_FROM_CT(T(LASTP), up))
