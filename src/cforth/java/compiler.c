#include "forth.h"

#ifndef JAVA
#include <stdio.h>
int *word_dict;

int alcanonical(int adr, int len, int up);
#endif

// The variables that are defined in this file are use by both
// the Forth runtime (forth.c) and by the metacompiler (meta.c).
// They can't be defined in forth.c because the metacompiler
// doesn't include forth.o .

// Most of these get initialized at run time; see init_variables()

#define DICT_ALLOC(var, n)  xlimit -= n;  V(var) = xlimit
#define DICT_BELOW(var, n)  V(var) = xlimit; xlimit -= (n)

SCOPE2 int
init_compiler(int here, int xlimit, IntArray stored_up)
{
    int up;
    int i;

    xlimit -= MAXVARS;
    up = xlimit;
    for (i = 0; i < MAXVARS; i++) {
        V(i) = stored_up[i];
    }

    V(DP) = here;

    DICT_ALLOC(UPZERO, 0);                 // User area variables

    DICT_ALLOC(RPZERO, 4);                 // top address; 4 is guard band
    DICT_BELOW(XRP, RSSIZE);               // top address

    DICT_ALLOC(RSSAVE, RSSIZE);            // Saved copy of return stack
    DICT_ALLOC(RSMARK, 0);

    DICT_ALLOC(SPZERO, 4);                 // top address; 4 is guard band
    DICT_BELOW(XSP, PSSIZE);               // top address

    DICT_ALLOC(COMPBUF, CBUFSIZE);         // Compile buffer

#ifdef INCLUDE_LOCALS
    DICT_ALLOC(LOCALS, MAXLOCALS * sizeof(struct local_name));
#endif

    DICT_ALLOC(CTBUF, 2);                   // Used by execute_word

// XXX this will change if we have a separate character array
    DICT_ALLOC(TICK_SOURCE, TIBSIZE);       // Text input buffer
    DICT_ALLOC(TICK_TIB, 0);

    DICT_ALLOC(TMPSTRBUF, 32);
    DICT_ALLOC(CANONSTR, 32);

    DICT_ALLOC(LIMIT, 0);

    return up;
}

SCOPE2 void
place_name(int adr, int len, int previous, int up)
{
    int i;
    int rdp;

    rdp = V(DP);
    // Place the string, then the length byte
    for (i = 0; i < len; i++) {
        TOKEN(rdp++) = CHARS(adr++);
    }
    TOKEN(rdp++) = len;

    V(DP) = rdp;

    linkcomma(previous);

    tokstore(V(DP), up + LASTP);
}

SCOPE2 void
cfwarn(int adr, int len, int up)
{
    if (V(WARNING) != 0
    && 0 != search_wid(adr, len, T(CURRENT), up)) {
        alerror(adr, len, up);
        ERROR(" isn't unique\n");
    }
}

SCOPE2 void
header(int adr, int len, int up)
{
    int canstr;
    int threadp = up + DATA(voc_unum + T(CURRENT));

    canstr = alcanonical(adr, len, up);

    cfwarn(canstr, len, up);

    place_name(canstr, len, TOKEN(threadp), up);

    // Link into vocabulary search list and remember lfa for hide/reveal
    tokstore(V(DP), threadp);
}

SCOPE2 void
str_create(int adr, int len, int cf, int up)
{
    header(adr, len, up);
    compile(cf);
}

SCOPE2 void
create_word(int cf, int up)
{
    int len = parse_word(up+TMP1, up);
    str_create(V(TMP1), len, cf, up);
}

SCOPE2 void
tokstore(int token, int adr)
{
    TOKEN(adr) = token;
}
        
SCOPE2 int
parse(int delim, int sp, int up)
{
    int bufend = V(TICK_SOURCE) + V(NUM_SOURCE);
    int nextc  = V(TICK_SOURCE) + V(TO_IN);
    int wordstart = nextc;
    int c;

    DS(sp) = wordstart;

    do {
        if (nextc >= bufend) {
            V(TO_IN) = nextc - V(TICK_SOURCE);
            return(nextc - wordstart);
        }
        c = CHARS(nextc++);
    } while (  c != delim
            && (c > ' '  ||  delim != ' '  ||  isinteractive() != 0 )
        );

    V(TO_IN) = nextc - V(TICK_SOURCE);
    return (nextc - wordstart - 1);
}

// Read the next whitespace-delimited word from the input stream,
// skipping leading delimiters.

SCOPE2 int
parse_word(int adrp, int up)
{
    int bufend = V(TICK_SOURCE) + V(NUM_SOURCE);
    int nextc  = V(TICK_SOURCE) + V(TO_IN);
    int wordstart = nextc;
    int c;

    do {
        if (nextc >= bufend) {
            V(TO_IN) = nextc - V(TICK_SOURCE);
            DATA(adrp) = wordstart;
            return(0);
        }
        c = CHARS(nextc++);
    } while (c <= ' ');

    // Now c contains a non-delimiter character.

    wordstart = nextc-1;
    DATA(adrp) = wordstart;

    do {
        if (nextc >= bufend) {
            V(TO_IN) = nextc - V(TICK_SOURCE);
            return(nextc - wordstart);
        }
        c = CHARS(nextc++);
    } while (c > ' ');

    V(TO_IN) = nextc - V(TICK_SOURCE);
    return (nextc - wordstart - 1);
}

// Look for a name within a vocabulary.
//
// Returns 0 if the name was not found.
// If the name is found, stores the execution token associated with
// that name through ctp and returns 1 if the name has the immediate
// attribute, else -1.

#define IMMEDBIT 0x80
#define to_link(xt)     (xt - 1)
#define to_name_len(xt) (xt - 1 - 1)
#define name_len(xt)    (CHARS(to_name_len(xt)) & 0x3f)
#define to_name_adr(xt) (to_name_len(xt) - name_len(xt))

SCOPE2 int
isimmediate(int xt)
{
    return (CHARS(to_name_len(xt)) & IMMEDBIT) != 0 ? 1 : -1;
}

SCOPE2 int
search_wid(int adr, int len, int wid, int up)
{
    // The first character in the string is the Forth count field.
    int str, ptr;
    int length;
    int dictp;
 
    for ( dictp = TOKEN(up + DATA(voc_unum + wid));
          dictp != 0;
          dictp = TOKEN(to_link(dictp))
        ) {
 
        length = name_len(dictp);

        if (len != length) {
            continue;
        }
        str = to_name_adr(dictp);
        ptr = adr;
        for ( ; length != 0; --length ) {
            if ( CHARS(str++) != CHARS(ptr++) )
                break;
        }
        if (length == 0)
            return dictp;
    }
    return (0);	       // Not found
}

SCOPE2 int
canon_search_wid(int adr, int len, int wid, int up)
{
    return search_wid(alcanonical(adr, len, up), len, wid, up);
}

SCOPE2 int
alfind(int adr, int len, int up)
{
    int canstr;
    int i, found;
    int voc, last_voc;

    canstr = alcanonical(adr, len, up);

#ifdef INCLUDE_LOCALS
    if ((found = find_local(canstr, len, up)) != 0) {
        return found;
    }
#endif
    last_voc = 0;
    for (i = 0; i < NVOCS; i++) {
//        voc = V(CONTEXT) + i;
        voc = V(CONTEXT + i);
        if (voc == 0)
            continue;
        if ( (voc != last_voc) && ((found = search_wid(canstr, len, voc, up)) != 0) )
            return found;
        last_voc = voc;
    }
    return 0;
}

SCOPE2 void
makeimmediate(int up)
{
    // The flag bit is in the length byte, which precedes the xt address
    // and the link field
    CHARS(to_name_len(LAST)) |= IMMEDBIT;
}

SCOPE2 int
name_from(int nfa)
{
    return ( nfa + CHARS(nfa) + 1 );
}

SCOPE2 int
alcanonical(int adr, int len, int up)
{
    int p, q;
    int c;

    if (V(CAPS) == 0)
        return adr;

    q = V(CANONSTR);

    if (len > 32)
        len = 32;

    for (p = adr; (len--) != 0; p++) {
        c = CHARS(p);
        CHARS(q++) = (c >= 'A' && c <= 'Z') ? (c - 'A' + 'a') : c;
    }
    return V(CANONSTR);
}

#ifdef JAVA
SCOPE2 String
altostr(int adr, int len)
{
    byte[] strbuf = new byte[len+1];
    int to;

    for (to=0; to<len; to++)
        strbuf[to] = (byte)CHARS(adr++);

    strbuf[to] = '\0';
    return new String(strbuf);
}

SCOPE2 int
strtoal(String s, int adr, int up)
{
    int len = s.length();

    if (len > 32)
        len = 32;

    for (int i=0; i < len; i++)
//        CHARS(adr++) = s.codePointAt(i);  // CIDP omits this method
        CHARS(adr++) = (int)s.charAt(i);

    return len;
}
#else
int *
aln_alloc(int nbytes)
{
    return( (int *)getmem(nbytes * sizeof(int)) );
}

char *
altostr(int adr, int len, char *cstrbuf, int maxlen)
{
    char *to;

    to = cstrbuf;

    if (len > (unsigned)maxlen-1)
        len = maxlen-1;

    while ((len--) != 0)
        *to++ = CHARS(adr++);

    *to++ = '\0';
    return (cstrbuf);
}

int
strtoal(String s, int adr, int up)
{
    int i;

    for (i=0; (i < 32) && (*s != '\0'); i++)
        CHARS(adr++) = *s++;

    return i;
}
#endif
