#include <stdio.h>
#include "forth.h"
#include "prims.h"	/* Needed for PAREN_LIT */
#include "compiler.h"

extern char *alcanonical(char *adr, cell len, char *canstr, cell *up);

// The variables that are defined in this file are use by both
// the Forth runtime (forth.c) and by the metacompiler (meta.c).
// They can't be defined in forth.c because the metacompiler
// doesn't include forth.o .

/* Most of these get initialized at run time; see init_variables() */

#if 0
#define DIGITS 24
static char numbuf[DIGITS];

char *hex(n, digits)
{
    char *p = &numbuf[digits];
    *p = '\0';
    while (--p >= numbuf) {
        *p = "0123456789abcdef"[n & 0xf];
        n >>= 4;
    }
    return numbuf;
}
#endif

void
init_compiler(const u_char *origin, u_char *ramorigin, token_t topct, u_char *here, u_char *xlimit, cell *up)
{
    V(UPZERO) = (cell)up;

    V(TORIGIN) = (cell)origin;
    V(DP) = (cell)here;

    V(RAMTOKENS) = (cell)ramorigin;
    V(RAMCT) = (cell)topct;

    xlimit -= 4 * sizeof(token_t *);      // Guard band

    V(RPZERO) = V(XRP) = (cell)xlimit;
    xlimit -= RSSIZE * sizeof(token_t *);

    xlimit -= RSSIZE * sizeof(token_t *);  // Saved copy of return stack
    V(RSSAVE) = V(RSMARK) = (cell)xlimit;  // for tracing aborts.

    xlimit -= 4 * sizeof(cell);            // Guard band
    V(SPZERO) = V(XSP) = (cell)xlimit;
    xlimit -= PSSIZE * sizeof(cell);

    xlimit -= CBUFSIZE * sizeof(token_t);
    V(COMPBUF) = (cell)xlimit;

    xlimit -= TIBSIZE * sizeof(char);
    V(TICK_SOURCE) = V(TICK_TIB)  = (cell)xlimit;

    xlimit -= MAXLOCALS * sizeof(struct local_name);
    V(LOCALS) = (cell)xlimit;

    V(LIMIT) = (cell)xlimit;
}

void xt_align(cell *up)
{
    align(up);
    tokstore(CT_FROM_XT((xt_t)V(DP), up), (token_t *)&V(LASTP));
}

void
place_name(char *adr, cell len, token_t previous, cell *up)
{
    int i;
    register u_char *rdp;

    align(up);
    rdp = (u_char *)V(DP);
    // Add null to make the string end at an alignment boundary
    i = (len + 1) & (ALIGN_BOUNDARY - 1);
    if (i) {
        while (i++ < ALIGN_BOUNDARY) {
            *rdp++ = 0;
        }
    }
    // Place the string, then the length byte
    for (i = 0; i < len; i++) {
        *rdp++ = adr[i];
    }
    *rdp++ = (u_char)len;

#ifdef RELOCATE
    set_relocation_bit((cell *)rdp);
#endif
    V(DP) = (cell)rdp;

    linkcomma(previous);
}

static void
cfwarn(char *adr, cell len, cell *up)
{
    token_t *tmpxt;

    if (V(WARNING)
    && search_wid(adr, len, (vocabulary_t *)XT_FROM_CT(T(CURRENT), up), (xt_t *)&tmpxt, up)) {
        alerror((char *)adr, (u_cell)len, up);
        FTHERROR(" isn't unique\n");
    }
}

void
header(char *adr, cell len, cell *up)
{
    char *canonstr;
    char strbuf[32];
    token_t *threadp = hash ((vocabulary_t *)XT_FROM_CT(T(CURRENT), up), adr, len);

    canonstr = alcanonical(adr, len, strbuf, up);

    cfwarn(canonstr, len, up);

    place_name(canonstr, len, *threadp, up);

 /* Link into vocabulary search list and remember lfa for hide/reveal */
//    printf("%p %x %x %x %x\n", threadp, *threadp, CT_FROM_XT((xt_t)V(DP), up), V(RAMCT), V(RAMTOKENS));

    tokstore(CT_FROM_XT((xt_t)V(DP), up), threadp);
}

void
place_cf(token_t cf, cell *up)
{
    xt_align(up);
    compile(cf);
}

void
create_word(token_t cf, cell *up)
{
    char *adr;
    cell len;

    len = parse_word((u_char **)&adr, up);
    header(adr, len, up);
    place_cf(cf,up);
}

void
tokstore(token_t token, token_t *adr)
{
#ifdef RELOCATE
    if ( (token >= MAXCF) ) {
	set_relocation_bit(adr);
    }
#endif
    *adr = token;
}

#ifdef RELOCATE
set_relocation_bit(cell *adr)
{
    cell offset;

    offset = (cell)(adr - (u_char *)V(TORIGIN));
    if ((offset >= 0)  &&  (adr <= (cell *)V(DP))) {
        relmap[offset>>3] |= bit[offset&7];
        return;
    }
    offset = (cell)(adr - up);
    if ((offset >= 0)  &&  (offset < MAXUSER)) {
        urelmap[offset>>3] |= bit[offset&7];
        return;
    }
}
#endif

cell
parse(u_char delim, cell *sp, cell *up)
{
    register u_char *bufend = (u_char *)V(TICK_SOURCE) + V(NUM_SOURCE);
    register u_char *nextc  = (u_char *)V(TICK_SOURCE) + V(TO_IN);
    register u_char *wordstart = nextc;
    register int c;

    *sp = (cell)wordstart;

    do {
	if ( nextc >= bufend ) {
	    V(TO_IN) = nextc - (u_char *)V(TICK_SOURCE);
	    return((cell)(nextc - wordstart));
	}
	c = *nextc++;
    } while (  c != delim
            && (c > ' '  ||  delim != ' '  ||  isinteractive()));

    V(TO_IN) = nextc - (u_char *)V(TICK_SOURCE);
    return ((cell)(nextc - wordstart - 1));
}

/*
 * Read the next whitespace-delimited word from the input stream,
 * skipping leading delimiters.
 */

cell
parse_word(u_char **adrp, cell *up)
{
    register u_char *bufend = (u_char *)V(TICK_SOURCE) + V(NUM_SOURCE);
    register u_char *nextc  = (u_char *)V(TICK_SOURCE) + V(TO_IN);
    register u_char *wordstart = nextc;
    register int c;

    do {
        if ( nextc >= bufend ) {
            V(TO_IN) = nextc - (u_char *)V(TICK_SOURCE);
            *adrp = wordstart;
            return(0);
        }
        c = *nextc++;
    } while (c <= ' ');

    /* Now c contains a non-delimiter character. */

    wordstart = nextc-1;
    *adrp = wordstart;

    do {
        if ( nextc >= bufend ) {
            V(TO_IN) = nextc - (u_char *)V(TICK_SOURCE);
            return((cell)(nextc - wordstart));
        }
        c = *nextc++;
    } while (c > ' ');

    V(TO_IN) = nextc - (u_char *)V(TICK_SOURCE);
    return ((cell)(nextc - wordstart - 1));
}

/*
 * Look for a name within a vocabulary.
 *
 * Returns 0 if the name was not found.
 * If the name is found, stores the execution token associated with
 * that name through ctp and returns 1 if the name has the immediate
 * attribute, else -1.
 */

#define IMMEDBIT 0x80
#define to_link(xt)     (token_t *)((u_char *)xt - sizeof(token_t))
#define to_name_len(xt) ((u_char *)xt - sizeof(token_t) - 1)
#define name_len(xt)    ((*to_name_len(xt)) & 0x3f)
#define to_name_adr(xt) (to_name_len(xt) - name_len(xt))
#define isimmediate(xt) ((*to_name_len(xt)) & IMMEDBIT)

#ifndef NO_COMPLETION
xt_t next_initial_match(char *adr, cell len, xt_t dictp, cell *up)
{
    /* The first character in the string is the Forth count field. */
    u_char *str,*ptr;
    int length;

    while (dictp != (xt_t)V(TORIGIN)) {
        if ( len > name_len(dictp)) {
            goto nextword;
        }
	length = len;
        str = to_name_adr(dictp);
        ptr = (u_char *)adr;
        while ( length-- ) {
            if ( *str++ != *ptr++ ) {
                goto nextword;
            }
        }

	return dictp;

      nextword:
        dictp = XT_FROM_CT(*to_link(dictp), up);

    }
    return ((xt_t)0);	       /* Not found */
}

// adr, len - initial substring to search for
// matchnum - which matched name to return - 0 for the first, 1 for the second, ...
// namep, namelen - one of the matched names
int num_initial_matches(char *adr, cell len,
			int matchnum, char **namep, int *namelen,
			cell *up)
{
    char *canonstr;
    char strbuf[32];
    vocabulary_t *voc, *last_voc;
    int nmatches = 0;
    *namelen = 0;
    *namep = (char *)0;

    canonstr = alcanonical(adr, len, strbuf, up);

    last_voc = (vocabulary_t *)0;
    int i;
    for (i = 0; i < NVOCS; i++) {
        voc = (vocabulary_t *) XT_FROM_CT( ((token_t *)&V(CONTEXT))[i], up);
        if ( voc == (vocabulary_t *)V(TORIGIN))
            continue;
        if (voc != last_voc) {
	    xt_t dictp = XT_FROM_CT(*hash(voc, canonstr, len), up);
	    while (dictp != (xt_t)V(TORIGIN)) {
		xt_t xt = next_initial_match(canonstr, len, dictp, up);
		if (xt == (xt_t)0) {
		    break;
		}
		if (nmatches == matchnum) {
		    *namelen = name_len(xt);
		    *namep = (char *)to_name_adr(xt);
		}
		++nmatches;
		dictp = XT_FROM_CT(*to_link(xt), up);
	    }
	}
        last_voc = voc;
    }
    return nmatches;
}
#endif

xt_t next_match(char *adr, cell len, xt_t dictp, cell *up)
{
    /* The first character in the string is the Forth count field. */
    u_char *str,*ptr;
    int length;

    while (dictp != (xt_t)V(TORIGIN)) {

        length = name_len(dictp);

        if ( len != length ) {
            goto nextword;
        }
        str = to_name_adr(dictp);
        ptr = (u_char *)adr;
        while ( length-- ) {
            if ( *str++ != *ptr++ ) {
                goto nextword;
            }
        }

	return dictp;

      nextword:
        dictp = XT_FROM_CT(*to_link(dictp), up);

    }
    return ((xt_t)0);	       /* Not found */
}

int
search_wid(char *adr, cell len, vocabulary_t *wid, xt_t *xtp, cell *up)
{
    *xtp = next_match(adr, len, XT_FROM_CT(*hash(wid, adr, len), up), up);
    if (*xtp == (xt_t)0) {
	return 0;
    }
    return isimmediate(*xtp) ? 1 : -1;
}

int
canon_search_wid(char *adr, cell len, vocabulary_t *wid, xt_t *xtp, cell *up)
{
    char *canonstr;
    char strbuf[32];

    canonstr = alcanonical(adr, len, strbuf, up);
    return search_wid(canonstr, len, wid, xtp, up);
}

int
alfind(char *adr, cell len, xt_t *xtp, cell *up)
{
    int i, found = 0;
    vocabulary_t *voc, *last_voc;
    char *canonstr;
    char strbuf[32];

    canonstr = alcanonical(adr, len, strbuf, up);

    if ((found = find_local(canonstr, len, xtp, up)) != 0) {
        return (found);
    }
    last_voc = (vocabulary_t *)0;
    for (i = 0; i < NVOCS; i++) {
        voc = (vocabulary_t *) XT_FROM_CT( ((token_t *)&V(CONTEXT))[i], up);
        if ( voc == (vocabulary_t *)V(TORIGIN))
            continue;
        if ( (voc != last_voc) && ((found = search_wid(canonstr, len, voc, xtp, up)) != 0) )
            break;
        last_voc = voc;
    }
    return (found);
}

void
makeimmediate(cell *up)
{
    // The flag bit is in the length byte, which precedes the xt address
    // and the link field
    *to_name_len(LAST) |= IMMEDBIT;
}

token_t *
aligned(u_char *addr)
{
    /* This calculation assumes twos-complement representation */
    return( (token_t *)
      ( ((cell)addr + ALIGN_BOUNDARY - 1) & (-((cell)ALIGN_BOUNDARY)) )
    );
}

void
align(cell *up)
{
    int length = (cell)aligned((u_char *)V(DP) ) - V(DP);
    u_char *rdp = (u_char *)V(DP);
    while ( length-- )
        *rdp++ = '\0';
    /* Pointer alignment */
    V(DP) = (cell)rdp;
}

/* This should be called skip-string */
token_t *
name_from(u_char * nfa)
{
    return ( aligned( &nfa[(*nfa)+1] ) );
}

char *
alcanonical(char *adr, cell len, char *canonstr, cell *up)
{
    register char *p, *q;
    register char c;

    if ( !V(CAPS) )
        return(adr);

    q = canonstr;

    if (len > 32)
        len = 32;

    for (p = adr; len--; p++) {
        c = *p;
        *q++ = (c >= 'A' && c <= 'Z') ? (c - 'A' + 'a') : c;
    }
    return canonstr;
}

char *
altocstr(char *adr, u_cell len, char *cstrbuf, int maxlen)
{
    register char *to;

    if (adr[len] == '\0')
        return adr;

    to = cstrbuf;

    if (len > (unsigned)maxlen-1)
        len = maxlen-1;

    while ((len--) != 0)
        *to++ = *adr++;

    *to++ = '\0';
    return (cstrbuf);
}

u_char *
aln_alloc(cell nbytes, cell *up)
{
    return((u_char *)aligned((u_char *)getmem(nbytes+ALIGN_BOUNDARY, up)));
}
