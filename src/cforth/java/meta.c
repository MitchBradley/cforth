#include <stdio.h>
#include "forth.h"

extern void exit();
int strlen(const char *);

String infile;   // e.g. "interp.fth"
String outfile;  // e.g. "kernel.dic"

cell stack;	/* One-element stack, used for arguments to `constant' */

void init_dictionary(int up);
int variables[MAXVARS];

main(argc, argv)
    int argc;
    char **argv;
{
    int *origin;
    int up;

    if (argc != 3) {
        fprintf(stderr, "usage: meta input-file-name output-file-name\n");
        exit(1);
    }
    infile = argv[1];
    outfile = argv[2];

    word_dict = aln_alloc(MAXDICT);
    up = init_compiler(0, MAXDICT, variables);
    init_dictionary(up);
}


void
init_dictionary(int up)
{
    char *cstr[32];

    /* reserve space for an array of tokens to the cfa of prim headers */
    V(DP) += MAXPRIM;

#if 0
    // Make a temporary vocabulary structure so header will have
    // a place to put its various links

    tokstore(V(DP), up + CONTEXT);
    tokstore(V(DP), up + CURRENT);

    linkcomma(DOVOC);
    linkcomma(0);
    linkcomma(0);

    /* Make the initial dictionary entry */
    header("forth", sizeof("forth")-1);
#else
    place_name(V(TMPSTRBUF), strtoal("forth", V(TMPSTRBUF), up), 0, up);
#endif

    // Install the new vocabulary in the search order and the vocabulary list
    tokstore(V(DP), up + CONTEXT);
    tokstore(V(DP), up + CURRENT);
    tokstore(V(DP), up + VOC_LINK);

    compile(DOVOC);  // Code field

#ifdef RELOCATE
    set_relocation_bit(V(DP));
#endif
#if 0
    linkcomma(T(LASTP));    // last-word field
#else
    unumcomma(0);           // Forth voc threads are first thing in user area
    TOKEN(up+0) = T(LASTP);
#endif

    linkcomma(0);  // voc-link field

    init_variables(1, up);    // arg is first avail user number
    init_entries(up);
}


int xsp;

int next_prim = 1;

init_entries(int up)
{
    xsp = V(SPZERO);
    name_input(INIT_FILENAME);

    while (1) {
    	query(up);
        cinterpret(up);
    }
}

init_variables(int unum, int up)
{
    V(TO_IN) = V(BLK) = V(NUM_SOURCE) = 0;
    V(NUM_USER) = unum;
    V(NUM_OUT) = V(NUM_LINE) = 0;
    V(BASE) = 10;
    V(TICK_ACCEPT) = SYS_ACCEPT;
#ifdef XXX
    V(TICK_INTERPRET) = SYS_INTERPRET;
#endif
    V(STATE) = 0;
    V(WARNING) = 1;
    V(DPL) = -1;
    V(CAPS) = -1;
    V(THISDEF) = 0;
    V(COMPLEVEL) = 0;
}

/*
 * This simplified interpreter has no interpret state.
 * Everything that can be "interpreted" as opposed to "compiled"
 * is "magic", and is executed directly by this metacompiler.
 * It doesn't handle numbers either.
 */
interpret_word(int adr, cell len, int up)
{
    char strbuf[32];
    char *cstr = altostr(adr, len, strbuf, 32);
    int xt;
    int pct;
    int immed;
    int number;

    if (ismagic(cstr, up))
        return(1);

    if ((xt = alfind(adr, len, up)) != 0) {
        /*
         * If the word we found is a primitive, use its primitive number
         * instead of its cfa
         */
        pct = TOKEN(xt);
        compile ( pct < MAXPRIM ? pct : xt );
        return(1);
    }
    
    if (sscanf(cstr,"%d",&number) == 1) {
        if (V(STATE)) {
            compile(PAREN_LIT);
            ncomma(number);
        } else {
            stack = number;
        }
        return(1);
    }

    /* Undefined */
    alerror(adr, len, up);
    ERROR(" ?\n");
    return(0);
}

cinterpret(int up)
{
    cell len;

    while ( ((len = parse_word(up+TMP1, up)) != 0)
            && interpret_word(V(TMP1), len, up) ) {
    }
}

int
query(int up)
{
    V(NUM_SOURCE) = caccept(V(TICK_SOURCE), (cell)TIBSIZE, up);
    V(TO_IN) = 0;
}

/* Place a string in the dictionary */
void
alcomma_string(int adr, cell len, int up)
{
    int rdp = V(DP);

    CHARS(rdp++) = len;
    while ( len-- )
        CHARS(rdp++) = CHARS(adr++);
    CHARS(rdp++) = '\0';

    V(DP) = (cell)rdp;
}

#define forw_mark    DS(--xsp) = V(DP); V(DP)++
#define back_mark    DS(--xsp) = V(DP)
#define forw_resolve {	cell start = DS(xsp++); \
			TOKEN(start) = V(DP)-start; }
#define back_resolve {	cell start = DS(xsp++); \
			TOKEN(V(DP)) = start-V(DP); \
			V(DP)++; }
#define but	 { cell temp = DS(xsp); DS(xsp) = DS(xsp+1); DS(xsp+1) = temp; }

/* We let the interpreter take care of the next word for ['] and [compile] */
/* This wouldn't work in a "real" Forth interpreter because */
/* the next word could be immediate, but this simplified */
/* metacompiler is only intended to compile very limited code */

void doprim(int up)
{
	create_word(next_prim, up);
    tokstore(T(LASTP), next_prim);
//  tokstore(T(LASTP), next_prim*sizeof(token_t));  // For &data[] version
//  tokstore(T(LASTP), next_prim);  // For &tokens[] version

//	tokstore(V(DP) - sizeof(token_t), &tokens[next_prim]);
	next_prim++;
}

void doiprim(int up)	   { doprim(up); makeimmediate(up); }

void doimmed(int up)	   { makeimmediate(up); }
void donuser(int up)
{
	create_word(DOUSER, up);
	unumcomma(V(NUM_USER));
	V(NUM_USER)++;
}

void dotuser(int up)
{
	create_word(DOUSER, up);
	unumcomma(V(NUM_USER));
	V(NUM_USER)++;
}

void dodefer(int up)
{
	create_word(DODEFER, up);
	unumcomma(V(NUM_USER));
	V(NUM_USER)++;
}

void doconstant(int up)
{
	create_word(DOCON, up);
	ncomma(stack);
}

void docftok(int up)
{
	create_word(DOCON, up);
    ncomma(next_prim);  // Don't do ++ here because ncomma has side effects
    ++next_prim;  // 
}

void doload(int up)
{
	V(BOUNDARY) = V(DP);
	V(NUM_USER) = NEXT_VAR;
	name_input(infile);
}

void dostore(int up)	   {
    int xt;
    cell adr;
    cell len;
    cell astr;
    
    len = strtoal(outfile, V(TMPSTRBUF), up);
    write_dictionary(V(TMPSTRBUF), len, V(DP), up, V(NUM_USER));
    exit(0);
}
void dodotquote(int up)  {
    compile(P_DOT_QUOTE);
    alcomma_string(V(TMP1), parse('"', up+TMP1, up), up);
}

void doparen(int up)     { (void) parse(')', up+TMP1, up);  }
void dobackslash(int up) { (void) parse('\n', up+TMP1, up); }
void dobractick(int up)  { compile(PAREN_TICK); }
void dobraccomp(int up)  { }
void docolon(int up)     { create_word(DOCOLON, up); V(STATE) = 1;}
void dosemicol(int up)   { compile(UNNEST); V(STATE) = 0;}
void doif(int up)        { compile(QUES_BRANCH); forw_mark; }
void doelse(int up)      { compile(PBRANCH); forw_mark;  but;  forw_resolve; }
void dothen(int up)      { forw_resolve; }
void dobegin(int up)     { back_mark; }
void dowhile(int up)     { compile(QUES_BRANCH); forw_mark; but; }
void dorepeat(int up)    { compile(PBRANCH); back_resolve; forw_resolve; }
void doagain(int up)     { compile(PBRANCH); back_resolve; }
void dountil(int up)     { compile(QUES_BRANCH); back_resolve; }

struct metatab {  char *name; void (*func)(); } metawords[] = {
	"(",		doparen,
	"\\",		dobackslash,
	"[']",		dobractick,
	"[compile]",	dobraccomp,
	":",		docolon,
	";",		dosemicol,
	"immediate",	doimmed,
	"nuser",	donuser,
	"defer",	dodefer,
	"constant",	doconstant,
	"if",		doif,
	"else",		doelse,
	"then",		dothen,
	"begin",	dobegin,
	"while",	dowhile,
	"repeat",	dorepeat,
	"again",	doagain,
	"until",	dountil,
	".\"",		dodotquote,
	"p",		doprim,
	"u",		donuser,
	"t",		dotuser,
	"i",		doiprim,
	"c",		docftok,
	"w",		dostore,
	"e",		doload,
	"",		0,
};

int
ismagic(char *str, int up)		/* Returns true if string was handled "magically" */
{
    struct metatab *p;

    for (p = metawords; p->name[0] != '\0'; p++) {
	if (strcmp(str, p->name) == 0) {
	    (p->func)(up);
	    return(1);
	}
    }
    return(0);
}

/* The metacompiler doesn't need interactive mode so we stub these out */
keymode() {}
linemode() {}

#if 0
/* ARGSUSED */
int find_local(int adr, int plen, int xtp, int up) { return 0; }
#endif
