/*
 * ROMified inflate module
 * Copyright 1994 FirmWorks, Mountain View CA USA.
 *
 * This is the inflate code from the GNU ZIP package, with
 * changes to support running the unzipper from ROM.
 * My comments are interspersed throught the file; look for "ROM".
 * One substantial change is that this version uncompresses into
 * memory, resulting in a significant simplification to the sliding
 * window management code, which is now utterly trivial.
 * Other changes:
 * * Flattened the subroutine call hierarchy somewhat so spill/fill
 *   handlers aren't necessary on SPARC machines with only 4 register
 *   windows
 * * Access global variables relative to a base variable, for position
 *   independence.
 *
 * ROM
 * The assumption is that a compressed ROM is composed of three
 * (possibly contiguous) pieces: startup code, this inflate module,
 * and a big hunk o' compressed bits.
 *
 * The startup code should locate and prepare two areas of memory:
 * an area at (caddr_t) clear to receive the uncompressed bits, and
 * an area at (struct workspace *) ws to provide scratch space for
 * the algorithm. The startup code should then call the inflate()
 * routine below with three arguments: a pointer to the compressed
 * data in the ROM, clear, and ws. After uncompressing the ROM,
 * the startup code can release ws and jump to the entry point in
 * clear.
 */

#ifdef BIG_ENDIAN
/*
 * The PowerPC version of gcc (and perhaps other versions too) generates
 * endian-dependent code in a few circumstances.  For this program, the
 * cases where this occurs are:
 * a) When initializing a local instance of "struct huft", gcc allocates
 *    the structure instance in a pair of 32-bit registers and does bit
 *    field inserts to set the fields thereof.  The code that accesses
 *    in-memory structure instances uses byte and halfword load instructions.
 *
 *    The solution to this problem is to declare the structure as an array
 *    of bytes, compute addresses therein, and cast the addresses to the
 *    appropriate pointer type.  This cause the compiler to generate
 *    endian-independent code for the structure member accesses.
 *
 * b) Operations of the form:
 *      foo = (u_short)*p;
 *    where p is a pointer to a u_long datum generates code like:
 *      lhz r0,2(p)
 *    The offset "2" is endian-dependent.
 *    A similar problem occurs with
 *      foo = (u_char)*p;
 *    where p is a pointer to a u_short datum.
 *
 *    The solution to this problem is to use the "volatile" property on the
 *    pointer, e.g.  foo = (u_short)*(volatile u_long *)p, which causes the
 *    compiler to access the datum in its "natural" size, and then demote
 *    the datum to the smaller size.
 */
#endif

/* inflate.c -- Not copyrighted 1992 by Mark Adler
   version c10p1, 10 January 1993 */

/* You can do whatever you like with this source file, though I would
   prefer that if you modify it and redistribute it that you include
   comments to that effect with your name and the date.  Thank you.
   [OK: Changes for Open Firmware by Mike Tuciarone, June 1994.]
 */

/* gzip.h -- common declarations for all gzip modules
 * Copyright (C) 1992-1993 Jean-loup Gailly.
 * This is free software; you can redistribute it and/or modify it under the
 * terms of the GNU General Public License, see the file COPYING.
 */

#define u_long  unsigned long
#define u_short unsigned short
#define u_char  unsigned char
#define NULL    (void *)0

static void init_var();
static u_long NEEDBITS();
static int huft_fixed();
static int huft_dynamic();

/* gzip flag byte */
#define ORIG_NAME    0x08 /* bit 3 set: original file name present */

/* ROM
 * Workspace definitions
 *
 * This code plays games with the interpretation of local variables and
 * function arguments in order to make the inflate code pure text (since
 * we can't very well have a data segment if we're running out of ROM).
 * It would have been possible to use traditional data and bss segments,
 * but this way the setup requirements are very simple (go find a chunk
 * of RAM anywhere), there's no linkage restriction on the inflate module,
 * and in fact if the code is compiled position-indepent it should be
 * possible to run the inflate module from any memory location.
 */

/* The extra 256 are for the CRC table */
#define	WS_NGLOBALS	32+256
struct workspace {
	u_long	globals[WS_NGLOBALS];
	u_char	*heap;
};

#define	bb		0
#define	bk		1
#define	codeptr		2
#define	border		3
#define	cplens		4
#define	cplext		5
#define	cpdist		6
#define	cpdext		7
#define huft_base	8
#define	space		31
#define	crctab		32	/* 256 longs starting here */

#define	VAR(x)	(workspace->globals[x])
#define	ws	workspace
#define WORKSPACE struct workspace *ws

#define HUFT_FREE  VAR(space) = VAR(huft_base)

#define	ALLOC(v, s) {				\
			VAR(v) = VAR(space);	\
			VAR(space) += (s);	\
		    }

#define NEXTBYTE  (*(u_char *)(VAR(codeptr))++)

#define MASK_BITS(n)	((1 << (n)) - 1)

#define WSIZE 0x8000     /* window size--must be a power of two, and */
                         /*  at least 32K for zip's deflate method */

#define DUMPBITS(n) {b>>=(n);VAR(bk)-=(n);}

#ifdef BI_ENDIAN
#define E 0
#define B 1
#define N 2
#define T sizeof(char *)
struct huft {
  u_char a[__alignof__(char *) + sizeof(char *)];
};
#else
struct huft {
  u_char e;                /* number of extra bits or operation */
  u_char b;                /* number of bits in this code or subcode */
  union {
    u_short n;             /* literal, length base, or distance base */
    struct huft *t;        /* pointer to next level of table */
  } v;
};
#endif

static u_long compute_crc();

/*
 * The inflate() entry point--leave this at the head of the file,
 * so it winds up at offset 0 of this module.
 */

/*
 * Uncompress the bits in compr into clear, using scratch space at wsptr.
 * Return size of clear.
 */
int
inflate(struct workspace *wsptr, int nohdr, u_char* clear, u_char *compr) __attribute__((section ("text_inflate")));

int
inflate(struct workspace *wsptr, int nohdr, u_char* clear, u_char *compr)
{
	int	n;
	int	flags;
	int     done;
	int     crc, size, stored_crc, stored_size;
        register u_char *outp = clear;
	struct workspace *ws;

	/* first initialize workspace */
	ws = wsptr;
	VAR(space) = (u_long) &ws->heap;
	init_var(compr, ws);

	/*
	 * Header:
	 * Magic:       0x1f,0x8b (GZIP_MAGIC)
	 * Compression: 0x08 (DEFLATED)
	 * Flags:       0x00 if no filename, 0x08 if filename present
	 * Timestamp:   4 bytes in little endian
	 * Extra Flags: 0x00  (conveys pkzip -es, -en, or -ex information)
	 * OS Type:     0x03 for Unix, 7 for MACOS, 0 for DOS, 0x0b for WIN32
	 * Filename:    null-terminated string or nothing, depending on flags
	 */

         if (nohdr == 0) {
            /* strip off header */
            for (n = 0; n < 3; ++n)
		(void) NEXTBYTE;
            flags = NEXTBYTE;
            for (n = 0; n < 6; ++n)
		(void) NEXTBYTE;
            if (flags & ORIG_NAME)
		while (NEXTBYTE)
                    ;
         }

	/* decompress until the last block */
	do {
	    u_long t;           /* block type */
	    u_long b;                /* bit buffer */

	    /* make local bit buffer */
	    b = VAR(bb);

	    /* read in last block bit */
	    b = NEEDBITS(1, b, ws);
	    done = (int)b & 1;
	    DUMPBITS(1)

	    /* read in block type */
	    b = NEEDBITS(2, b, ws);
	    t = (u_long)b & 3;
	    DUMPBITS(2)

	    /* restore the global bit buffer */
	    VAR(bb) = b;

	    /* inflate that block type */
	    if (t == 0) {
		/* Block is stored without compression; copy it out */
                {
                  u_long n;             /* number of bytes in block */
                  u_long b;             /* bit buffer */
                
                  /* make local copies of globals */
                  b = VAR(bb);          /* initialize bit buffer */
                
                  /* go to byte boundary */
                  n = VAR(bk) & 7;
                  DUMPBITS(n);
                
                  /* get the length and its complement */
                  b = NEEDBITS(16, b, ws);
                  n = ((u_long)b & 0xffff);
                  DUMPBITS(16)
                  b = NEEDBITS(16, b, ws);
                  if (n != (u_long)((~b) & 0xffff)) {
		      /* error in compressed data */
                      done = 1;
		  } else {
                      DUMPBITS(16)
                
                      /* read and output the compressed data */
                      while (n--)
                      {
                        b = NEEDBITS(8, b, ws);
                        *outp++ = (u_char) b;
                        DUMPBITS(8)
                      }
                
                      /* restore the globals from the locals */
                      VAR(bb) = b;           /* restore global bit buffer */
	           }
                }

	    } else {
	        int i;                /* temporary variables */
		struct huft *tl;      /* literal/length code table */
		struct huft *td;      /* distance code table */
		int bl;               /* lookup bits for tl */
		int bd;               /* lookup bits for td */
		u_long ll[286+30];    /* literal/length and dist. code lens */

		if ( t == 1
		     ? huft_fixed(i, &tl, &td, &bl, &bd, ll, ws)
		     : huft_dynamic(i, &tl, &td, &bl, &bd, ll, ws) ) {
		    done = 1;
		} else {

		    /*
		     * decompress the codes in a deflated (compressed)
		     * block until an end-of-block code
		     */
                    {
                      register u_long e; /* table entry flag/# of extra bits */
                      u_long n, d;       /* length and index for copy */
                      struct huft *t;    /* pointer to table entry */
                      u_long ml, md;     /* masks for bl and bd bits */
                      u_long b;          /* bit buffer */
                    
                      /* make local copies of globals */
                      b = VAR(bb);            /* initialize bit buffer */
                    
                      /* inflate the coded data */
                      ml = MASK_BITS(bl);     /* precompute masks for speed */
                      md = MASK_BITS(bd);
                      for (;;)                /* do until end of block */
                      {
                        b = NEEDBITS(bl, b, ws);
#ifdef BI_ENDIAN
                        if ((e = (t = tl + ((u_long)b & ml))->a[E]) > 16)
#else
                        if ((e = (t = tl + ((u_long)b & ml))->e) > 16)
#endif
                          do {
                            if (e == 99)
                              goto out;
#ifdef BI_ENDIAN
                            DUMPBITS(t->a[B])
#else
                            DUMPBITS(t->b)
#endif
                            e -= 16;
                            b = NEEDBITS((int) e, b, ws);
#ifdef BI_ENDIAN
                          } while ((e = (t = 
						(*(struct huft **)(&t->a[T]))
					 	+ ((u_long)b & MASK_BITS(e))
					)->a[E]
				    ) > 16);
                        DUMPBITS(t->a[B])
#else
                          } while ((e = (t = t->v.t +
					 ((u_long)b & MASK_BITS(e)))->e) > 16);
                        DUMPBITS(t->b)
#endif
                        if (e == 16)             /* then it's a literal */
#ifdef BI_ENDIAN
                           *outp++ = (u_char)*(volatile u_short *)(&t->a[N]);
#else
                           *outp++ = (u_char) t->v.n;
#endif
                        else                     /* it's an EOB or a length */
                        {
                          /* exit if end of block */
                          if (e == 15)
                            break;
                    
                          /* get length of block to copy */
                          b = NEEDBITS((int) e, b, ws);
#ifdef BI_ENDIAN
                          n = *(u_short *)(&t->a[N]) + ((u_long)b & MASK_BITS(e));
#else
                          n = t->v.n + ((u_long)b & MASK_BITS(e));
#endif
                          DUMPBITS(e);
                    
                          /* decode distance of block to copy */
                          b = NEEDBITS(bd, b, ws);
#ifdef BI_ENDIAN
                          if ((e = (t = td + ((u_long)b & md))->a[E]) > 16)
#else
                          if ((e = (t = td + ((u_long)b & md))->e) > 16)
#endif
                            do {
                              if (e == 99)
                                goto out;
#ifdef BI_ENDIAN
                              DUMPBITS(t->a[B])
#else
                              DUMPBITS(t->b)
#endif
                              e -= 16;
                              b = NEEDBITS((int) e, b, ws);
#ifdef BI_ENDIAN
                            } while ((e = (t = *(struct huft **)(&t->a[T]) +
					 ((u_long)b & MASK_BITS(e)))->a[E]) > 16);
                          DUMPBITS(t->a[B])
#else
                            } while ((e = (t = t->v.t +  ((u_long)b & MASK_BITS(e)))->e) > 16);
                          DUMPBITS(t->b)
#endif
                          b = NEEDBITS((int) e, b, ws);
#ifdef BI_ENDIAN
                          d = *(u_short *)(&t->a[N]) + ((u_long)b & MASK_BITS(e));
#else
                          d = t->v.n + ((u_long)b & MASK_BITS(e));
#endif
                          DUMPBITS(e)

		          while (n--) {
			      *outp = outp[-d];
			      outp++;
		          }

                        }
                      }
                    
		      /* free decoding tables */
		      HUFT_FREE;

                      /* restore the globals from the locals */
                      VAR(bb) = b;            /* restore global bit buffer */
	      out:   ;
                    }
	    	}
	    }
		
	} while (!done);

	if (nohdr != 0) {
		return ((u_long)(outp - clear));
	}

        /* Check the size and CRC against the stored values*/
	{
	u_long b, n;

        b = VAR(bb);            /* initialize bit buffer */

        /* go to byte boundary */
        n = VAR(bk) & 7;
        DUMPBITS(n);

	stored_crc = NEEDBITS(32, b, ws);
	b = 0; VAR(bk) = 0;         // DUMPBITS(32) doesn't compile.
	stored_size = NEEDBITS(32, b, ws);
	b = 0; VAR(bk) = 0;         // DUMPBITS(32) doesn't compile. 
	}

	size = outp - clear;
	crc = compute_crc(clear, size, (u_long *)&VAR(crctab));

        if (size != stored_size)
	     return (-2);
	if (crc != stored_crc)
	     return (-1);

	return ((u_long)(size));
}

static void
init_var(compr, ws)
u_char *compr;
WORKSPACE;
{
	u_long *ulp;
	u_short *usp, us;
	int i;

	/* initialize variables */
	VAR(bb) = 0;
	VAR(bk) = 0;
	VAR(codeptr) = (u_long) compr;

	/* Tables for deflate from PKZIP's appnote.txt. */
	/* Order of the bit length code lengths */
	ALLOC(border, 19 * sizeof(u_long));
	ulp = (u_long *) VAR(border);
	*ulp++ = 16; *ulp++ = 17; *ulp++ = 18; *ulp++ = 0;
	*ulp++ =  8; *ulp++ =  7; *ulp++ =  9; *ulp++ = 6;
	*ulp++ = 10; *ulp++ =  5; *ulp++ = 11; *ulp++ = 4;
	*ulp++ = 12; *ulp++ =  3; *ulp++ = 13; *ulp++ = 2;
	*ulp++ = 14; *ulp++ =  1; *ulp++ = 15;

	/* Copy lengths for literal codes 257..285 */
	ALLOC(cplens, 16 * sizeof(u_long));
	usp = (u_short *) VAR(cplens);
        *usp++ =   3; *usp++ =   4; *usp++ =   5; *usp++ =   6; *usp++ =   7;
	*usp++ =   8; *usp++ =   9; *usp++ =  10; *usp++ =  11; *usp++ =  13;
	*usp++ =  15; *usp++ =  17; *usp++ =  19; *usp++ =  23; *usp++ =  27;
	*usp++ =  31; *usp++ =  35; *usp++ =  43; *usp++ =  51; *usp++ =  59;
	*usp++ =  67; *usp++ =  83; *usp++ =  99; *usp++ = 115; *usp++ = 131;
	*usp++ = 163; *usp++ = 195; *usp++ = 227; *usp++ = 258; *usp++ =   0;
	*usp++ =   0;
        /* note: see note #13 above about the 258 in this list. */

	/* Extra bits for literal codes 257..285 */
	ALLOC(cplext, 16 * sizeof(u_long));
	usp = (u_short *) VAR(cplext);
	for (i = 0; i < 4; ++i)
		*usp++ = 0;
	for ( ; i < 28; i += 4) {
		us = (i - 1) / 4;
		*usp++ = us; *usp++ = us; *usp++ = us; *usp++ = us;
	}
	*usp++ = 0; *usp++ = 99; *usp++ = 99; /* 99==invalid */

	/* Copy offsets for distance codes 0..29 */
	ALLOC(cpdist, 16 * sizeof(u_long));
	usp = (u_short *) VAR(cpdist);
        *usp++ =     1; *usp++ =     2; *usp++ =     3; *usp++ =     4;
	*usp++ =     5; *usp++ =     7; *usp++ =     9; *usp++ =    13;
	*usp++ =    17; *usp++ =    25; *usp++ =    33; *usp++ =    49;
	*usp++ =    65; *usp++ =    97; *usp++ =   129; *usp++ =   193;
	*usp++ =   257; *usp++ =   385; *usp++ =   513; *usp++ =   769;
	*usp++ =  1025; *usp++ =  1537; *usp++ =  2049; *usp++ =  3073;
	*usp++ =  4097; *usp++ =  6145; *usp++ =  8193; *usp++ = 12289;
	*usp++ = 16385; *usp++ = 24577;

	/* Extra bits for distance codes */
	ALLOC(cpdext, 16 * sizeof(u_long));
	usp = (u_short *) VAR(cpdext);
	*usp++ = 0; *usp++ = 0;
	for (i = 2; i < 30; i += 2) {
		us = (i - 1) / 2;
		*usp++ = us; *usp++ = us;
	}
	VAR(huft_base) = VAR(space);
}

static u_long
NEEDBITS(n, b, ws)
int n;
u_long b;
WORKSPACE;
{
	while (VAR(bk) < (n)) {
		b |= ((u_long)NEXTBYTE) << VAR(bk);
		VAR(bk) += 8;
	}
	return (b);
}

/* If BMAX needs to be larger than 16, then h and x[] should be u_long. */
#define BMAX 16         /* maximum bit length of any code (16 for explode) */
#define N_MAX 288       /* maximum number of codes in any set */

#define lbits  9;          /* bits in base literal/length lookup table */
#define dbits  6;          /* bits in base distance lookup table */

#ifdef BI_ENDIAN
static
memcpy(dst,src,len)
char *dst, *src;
int len;
{
	while (len--)
		*dst++ = *src++;
}
#endif

/*
 * Given a list of code lengths and a maximum table size, make a set of
 * tables to decode that set of codes.  Return zero on success, one if
 * the given code set is incomplete (the tables are still built in this
 * case), two if the input is invalid (all zero length codes or an
 * oversubscribed set of lengths), and three if not enough memory.
 */
static int
huft_build(b, n, s, d, e, t, m, ws)
u_long *b;            /* code lengths in bits (all assumed <= BMAX) */
u_long n;             /* number of codes (assumed <= N_MAX) */
u_long s;             /* number of simple-valued codes (0..s-1) */
u_short *d;                 /* list of base values for non-simple codes */
u_short *e;                 /* list of extra bits for non-simple codes */
struct huft **t;        /* result: starting table */
int *m;                 /* maximum lookup bits, returns actual */
WORKSPACE;
{
  u_long a;                   /* counter for codes of length k */
  u_long c[BMAX+1];           /* bit length count table */
  u_long f;                   /* i repeats in table every f entries */
  int g;                   /* maximum code length */
  int h;                   /* table level */
  u_long i;                   /* counter, current code */
  u_long j;                   /* counter */
  int k;                   /* number of bits in current code */
  int l;                   /* bits per table (returned in m) */
  register u_long *p;         /* pointer into c[], b[], or v[] */
  register struct huft *q; /* points to current table */
  struct huft r;           /* table entry for structure assignment */
  struct huft *u[BMAX];    /* table stack */
  u_long v[N_MAX];            /* values in order of bit length */
  register int w;          /* bits before this table == (l * h) */
  u_long x[BMAX+1];           /* bit offsets, then code stack */
  u_long *xp;                 /* pointer into x */
  int y;                   /* number of dummy codes added */
  u_long z;                   /* number of entries in current table */


  /* Generate counts for each bit length */
  for (i = 0; i < BMAX+1; ++i)
  	c[i] = 0;
  p = b;  i = n;
  do {
    c[*p]++;                    /* assume all entries <= BMAX */
    p++;                      /* Can't combine with above line (Solaris bug) */
  } while (--i);
  if (c[0] == n)                /* null input--all zero length codes */
  {
    *t = (struct huft *)NULL;
    *m = 0;
    return 0;
  }


  /* Find minimum and maximum length, bound *m by those */
  l = *m;
  for (j = 1; j <= BMAX; j++)
    if (c[j])
      break;
  k = j;                        /* minimum code length */
  if ((u_long)l < j)
    l = j;
  for (i = BMAX; i; i--)
    if (c[i])
      break;
  g = i;                        /* maximum code length */
  if ((u_long)l > i)
    l = i;
  *m = l;


  /* Adjust last length count to fill out codes, if needed */
  for (y = 1 << j; j < i; j++, y <<= 1)
    if ((y -= c[j]) < 0)
      return 2;                 /* bad input: more codes than bits */
  if ((y -= c[i]) < 0)
    return 2;
  c[i] += y;


  /* Generate starting offsets into the value table for each length */
  x[1] = j = 0;
  p = c + 1;  xp = x + 2;
  while (--i) {                 /* note that i == g from above */
    *xp++ = (j += *p++);
  }


  /* Make a table of values in order of bit lengths */
  p = b;  i = 0;
  do {
    if ((j = *p++) != 0)
      v[x[j]++] = i;
  } while (++i < n);


  /* Generate the Huffman codes and for each, make the table entries */
  x[0] = i = 0;                 /* first Huffman code is zero */
  p = v;                        /* grab values in bit order */
  h = -1;                       /* no tables yet--level -1 */
  w = -l;                       /* bits decoded == (l * h) */
  u[0] = (struct huft *)NULL;   /* just to keep compilers happy */
  q = (struct huft *)NULL;      /* ditto */
  z = 0;                        /* ditto */

  /* go through the bit lengths (k already is bits in shortest code) */
  for (; k <= g; k++)
  {
    a = c[k];
    while (a--)
    {
      /* here i is the Huffman code of length k bits for value *p */
      /* make tables up to required level */
      while (k > w + l)
      {
        h++;
        w += l;                 /* previous table always l bits */

        /* compute minimum size table less than or equal to l bits */
	z = g - w;
        z = z > (u_long)l ? l : z;  /* upper limit on table size */
        if ((f = 1 << (j = k - w)) > a + 1)     /* try a k-w bit table */
        {                       /* too few codes for k-w bit table */
          f -= a + 1;           /* deduct codes from patterns left */
          xp = c + k;
          while (++j < z)       /* try smaller tables up to z bits */
          {
            if ((f <<= 1) <= *++xp)
              break;            /* enough codes to use up j bits */
            f -= *xp;           /* else deduct codes from patterns */
          }
        }
        z = 1 << j;             /* table entries for j-bit table */

        /* allocate and link in new table */
	q = (struct huft *)VAR(space);
	VAR(space) += (z + 1)*sizeof(struct huft);

        *t = q + 1;             /* link to list for huft_free() ?? needed ?? */
#ifdef BI_ENDIAN
        *(t = (struct huft **)&(q->a[T])) = (struct huft *)NULL;
#else
        *(t = &(q->v.t)) = (struct huft *)NULL;
#endif
        u[h] = ++q;             /* table starts after link */

        /* connect to last table, if there is one */
        if (h)
        {
          x[h] = i;             /* save pattern for backing up */
#ifdef BI_ENDIAN
          r.a[B] = (u_char)l;         /* bits to dump before this table */
          r.a[E] = (u_char)(16 + j);  /* bits in this table */
          *(struct huft **)(&r.a[T]) = q;       /* pointer to this table */
          j = i >> (w - l);     /* (get around Turbo C bug) */
          memcpy((char *)&(u[h-1][j]), (char *)&r, sizeof(struct huft));
#else
          r.b = (u_char)l;         /* bits to dump before this table */
          r.e = (u_char)(16 + j);  /* bits in this table */
          r.v.t = q;            /* pointer to this table */
          j = i >> (w - l);     /* (get around Turbo C bug) */
          u[h-1][j] = r;        /* connect to last table */
#endif
        }
      }

      /* set up table entry in r */
#ifdef BI_ENDIAN
      r.a[B] = (u_char)(k - w);
#else
      r.b = (u_char)(k - w);
#endif
      if (p >= v + n)
#ifdef BI_ENDIAN
        r.a[E] = 99;               /* out of values--invalid code */
#else
        r.e = 99;               /* out of values--invalid code */
#endif
      else if (*p < s)
      {
#ifdef BI_ENDIAN
        r.a[E] = (u_char)(*p < 256 ? 16 : 15);  /* 256 is end-of-block code */
        *(u_short *)(&r.a[N]) = (u_short)(*(volatile u_long *)p);
				       /* simple code is just the value */
#else
        r.e = (u_char)(*p < 256 ? 16 : 15);    /* 256 is end-of-block code */
        r.v.n = (u_short)(*p);             /* simple code is just the value */
#endif
	p++;                           /* one compiler does not like *p++ */
      }
      else
      {
#ifdef BI_ENDIAN
        r.a[E] = (u_char)(*(volatile u_short *)(&e[*p - s]));
                                             /* non-simple--look up in lists */
        *(u_short *)(&r.a[N]) = d[*p++ - s];
#else
        r.e = (u_char)e[*p - s];   /* non-simple--look up in lists */
        r.v.n = d[*p++ - s];
#endif
      }

      /* fill code-like entries with r */
      f = 1 << (k - w);
      for (j = i >> w; j < z; j += f)
#ifdef BI_ENDIAN
         memcpy((char *)&(q[j]), (char *)&r, sizeof(struct huft));
#else
        q[j] = r;
#endif

      /* backwards increment the k-bit code i */
      for (j = 1 << (k - 1); i & j; j >>= 1)
        i ^= j;
      i ^= j;

      /* backup over finished tables */
      while ((i & ((1 << w) - 1)) != x[h])
      {
        h--;                    /* don't need to update q */
        w -= l;
      }
    }
  }

  /* Return true (1) if we were given an incomplete table */
  return y != 0 && g != 1;
}


/* Create Huffman tables for an inflated type 1 (fixed Huffman codes) block. */
static int
huft_fixed(i, tl, td, bl, bd, ll, ws)
  int i;                /* temporary variables */
  struct huft **tl;     /* literal/length code table */
  struct huft **td;     /* distance code table */
  int *bl;              /* lookup bits for tl */
  int *bd;              /* lookup bits for td */
  u_long ll[286+30];    /* literal/length and distance code lengths */
WORKSPACE;
{
  /* set up literal table */
  for (i = 0; i < 144; i++)
    ll[i] = 8;
  for (; i < 256; i++)
    ll[i] = 9;
  for (; i < 280; i++)
    ll[i] = 7;
  for (; i < 288; i++)          /* make a complete, but wrong code set */
    ll[i] = 8;
  *bl = 7;
  if ((i = huft_build(ll, 288L, 257L, (u_short *) VAR(cplens), (u_short *) VAR(cplext), tl, bl, ws)) != 0)
    return i;

  /* set up distance table */
  for (i = 0; i < 30; i++)      /* make an incomplete code set */
    ll[i] = 5;
  *bd = 5;
  if ((i = huft_build(ll, 30L, 0L, (u_short *) VAR(cpdist), (u_short *) VAR(cpdext), td, bd, ws)) > 1)
  {
    return i;
  }
  return 0;
}

/*Create Huffman tables for an inflated type 2 (dynamic Huffman codes) block.*/
static int
huft_dynamic(i, tl, td, bl, bd, ll, ws)
  int i;                /* temporary variables */
  struct huft **tl;     /* literal/length code table */
  struct huft **td;     /* distance code table */
  int *bl;              /* lookup bits for tl */
  int *bd;              /* lookup bits for td */
  u_long ll[286+30];    /* literal/length and distance code lengths */
WORKSPACE;
{
  u_long j;
  u_long l;           /* last length */
  u_long m;           /* mask for bit lengths table */
  u_long n;           /* number of lengths to get */
  u_long nb;          /* number of bit length codes */
  u_long nl;          /* number of literal/length codes */
  u_long nd;          /* number of distance codes */
  u_long b;       /* bit buffer */

  /* make local bit buffer */
  b = VAR(bb);


  /* read in table lengths */
  b = NEEDBITS(5, b, ws);
  nl = 257 + ((u_long)b & 0x1f);      /* number of literal/length codes */
  DUMPBITS(5)
  b = NEEDBITS(5, b, ws);
  nd = 1 + ((u_long)b & 0x1f);        /* number of distance codes */
  DUMPBITS(5)
  b = NEEDBITS(4, b, ws);
  nb = 4 + ((u_long)b & 0xf);         /* number of bit length codes */
  DUMPBITS(4)
  if (nl > 286 || nd > 30)
    return 1;                   /* bad lengths */


  /* read in bit-length-code lengths */
  for (j = 0; j < nb; j++)
  {
    b = NEEDBITS(3, b, ws);
    ll[((u_long *)VAR(border))[j]] = (u_long)b & 7;
    DUMPBITS(3)
  }
  for (; j < 19; j++)
    ll[((u_long *)VAR(border))[j]] = 0;


  /* build decoding table for trees--single level, 7 bit lookup */
  *bl = 7;
  if ((i = huft_build(ll, 19L, 19L, (u_short *) NULL, (u_short *) NULL, tl, bl, ws)) != 0)
  {
    if (i == 1)
    return i;                   /* incomplete code set */
  }


  /* read in literal and distance code lengths */
  n = nl + nd;
  m = MASK_BITS(*bl);
  i = l = 0;
  while ((u_long)i < n)
  {
    b = NEEDBITS(*bl, b, ws);
#ifdef BI_ENDIAN
    j = (*td = *tl + ((u_long)b & m))->a[B];
    DUMPBITS(j)
    j = *(u_short *)(&(*td)->a[N]);
#else
    j = (*td = *tl + ((u_long)b & m))->b;
    DUMPBITS(j)
    j = (*td)->v.n;
#endif
    if (j < 16)                 /* length of code in bits (0..15) */
      ll[i++] = l = j;          /* save last length in l */
    else if (j == 16)           /* repeat last length 3 to 6 times */
    {
      b = NEEDBITS(2, b, ws);
      j = 3 + ((u_long)b & 3);
      DUMPBITS(2)
      if ((u_long)i + j > n)
        return 1;
      while (j--)
        ll[i++] = l;
    }
    else if (j == 17)           /* 3 to 10 zero length codes */
    {
      b = NEEDBITS(3, b, ws);
      j = 3 + ((u_long)b & 7);
      DUMPBITS(3)
      if ((u_long)i + j > n)
        return 1;
      while (j--)
        ll[i++] = 0;
      l = 0;
    }
    else                        /* j == 18: 11 to 138 zero length codes */
    {
      b = NEEDBITS(7, b, ws);
      j = 11 + ((u_long)b & 0x7f);
      DUMPBITS(7)
      if ((u_long)i + j > n)
        return 1;
      while (j--)
        ll[i++] = 0;
      l = 0;
    }
  }


  /* free decoding table for trees */
  HUFT_FREE;


  /* restore the global bit buffer */
  VAR(bb) = b;


  /* build the decoding tables for literal/length and distance codes */
  *bl = lbits;
  if ((i = huft_build(ll, nl, 257L, (u_short *) VAR(cplens), (u_short *) VAR(cplext), tl, bl, ws)) != 0)
  {
    return i;                   /* incomplete code set */
  }
  *bd = dbits;
  if ((i = huft_build(ll + nl, nd, 0L, (u_short *) VAR(cpdist), (u_short *) VAR(cpdext), td, bd, ws)) != 0)
  {
    return i;                   /* incomplete code set */
  }
  return 0;
}

#define ulg u_long
#define uch u_char
static void
makecrc(u_long *crc_32_tab)
{
  /* Not copyrighted 1990 Mark Adler      */

  unsigned long c;      /* crc shift register */
  unsigned long e;      /* polynomial exclusive-or pattern */
  int i;                /* counter for all possible eight bit values */
  int k;                /* byte being shifted into crc apparatus */

  /* wmb: Static data table converted to use run-time initialization */
  /* terms of polynomial defining this crc (except x^32): */
  int p[14];
  p[0] = 0;
  p[1] = 1;
  p[2] = 2;
  p[3] = 4;
  p[4] = 5;
  p[5] = 7;
  p[6] = 8;
  p[7] = 10;
  p[8] = 11;
  p[9] = 12;
  p[10] = 16;
  p[11] = 22;
  p[12] = 23;
  p[13] = 26;

  /* Make exclusive-or pattern from polynomial */
  e = 0;
  for (i = 0; i < sizeof(p)/sizeof(int); i++)
    e |= 1L << (31 - p[i]);

  crc_32_tab[0] = 0;

  for (i = 1; i < 256; i++)
    {
      c = 0;
      for (k = i | 256; k != 1; k >>= 1)
	{
	  c = c & 1 ? (c >> 1) ^ e : c >> 1;
	  if (k & 1)
	    c ^= e;
	}
      crc_32_tab[i] = c;
    }
}

/* ===========================================================================
 * Compute the CRC of an array of bytes.
 * Derived from updcrc() by Mark Adler.
 */
static ulg compute_crc(s, n, crc_32_tab)
    uch *s;                 /* pointer to bytes to pump through */
    unsigned n;             /* number of bytes in s[] */
    u_long *crc_32_tab;
{
    register ulg c;         /* temporary variable */

    makecrc(crc_32_tab);
    c = 0xffffffffL;
    if (n) do {
        c = crc_32_tab[((int)c ^ (*s++)) & 0xff] ^ (c >> 8);
    } while (--n);

    return c ^ 0xffffffffL;       /* (instead of ~c for 64-bit machines) */
}

#if 0
/* Test scaffolding */
char wsx[0x20000];
char inbuf[0x40000];
char outbuf[0x200000];

#include <stdio.h>

main()
{
  int r;
  read(0,inbuf,0x40000);
  r = inflate(inbuf, outbuf, (struct workspace *)wsx);
  fprintf(stderr,"%d\n", r);
}
#endif
