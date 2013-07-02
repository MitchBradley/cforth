#include "forth.h"

#ifdef FLOATING
#include "fprims.h"
#include "prims.h"	/* Needed for FPAREN_LIT */
#include <math.h>

#ifdef NeXT
#include <stdio.h>
double
strtodbl(const char *nptr, char **endptr)
{
  double fpval ;
  int len;
  if (sscanf(nptr, "%lf%n", &fpval, &len)<=0) {
    fpval = 0.0 ;
    len = 0 ;
  }
  if (endptr)
    *endptr = nptr + len ;
  return(fpval) ;
}
extern double strtodbl();
#else
#define strtodbl strtod
#endif

#define compile(token)  tokstore((token_t)token, (token_t *)V(DP)); V(DP) += sizeof(token_t)

#define FSTKLEN 20
double floatstack[FSTKLEN];
double *fsp = &floatstack[FSTKLEN];
double ftos;
double ftemp;
union fbits {
	double fb_float;
	unsigned long   fb_long[2];
} fbits;
char floatstr[50];
extern char *tocstr();
extern char *sprintf();
extern void tokstore();
extern char *altofpstr();

unsigned long *p;

void
floatop(int op)
{
    switch(op) {
	/* Floating Point additions to operation dispatch switch */

	/* Binary Floating Point Operators */
	case FPLUS:		ftos = *fsp++ + ftos;		break;
	case FMINUS:		ftos = *fsp++ - ftos;		break;
	case FTIMES:		ftos = *fsp++ * ftos;		break;
	case FDIVIDE:		ftos = *fsp++ / ftos;		break;

/* On some systems, "fmod()" may need to be replaced by "drem()" */
	case FMOD:		ftos = fmod(*fsp++, ftos);	break;

	/* Unary Floating Point Operators */
	case FNEGATE:		ftos = -ftos;			break;
	case FSIN:		ftos = sin(ftos);		break;
	case FCOS:		ftos = cos(ftos);		break;
	case FTAN:		ftos = tan(ftos);		break;
	case FLOG:		ftos = log10(ftos);		break;
	case FLN:		ftos = log(ftos);		break;
	case FATAN:		ftos = atan(ftos);		break;
	case FATAN2:		ftos = atan2(*fsp++, ftos);	break;
	case FASIN:		ftos = asin(ftos);		break;
	case FACOS:		ftos = acos(ftos);		break;
	case FCEIL:		ftos = ceil(ftos);		break;
	case FCOSH:		ftos = cosh(ftos);		break;
	case FSINH:		ftos = sinh(ftos);		break;
	case TANH:		ftos = tanh(ftos);		break;
	case FSQRT:		ftos = sqrt(ftos);		break;
	case FEXP:		ftos = exp(ftos);		break;
	case FABS:		ftos = fabs(ftos);		break;
	case FFLOOR:		ftos = floor(ftos);		break;
	case FPOW:		ftos = pow(*fsp++, ftos);	break;
#ifdef MOREFP
	case FROUND:		ftos = rint(ftos);		break;
	case FACOSH:		ftos = acosh(ftos);		break;
	case FASINH:		ftos = asinh(ftos);		break;
	case FATANH:		ftos = atanh(ftos);		break;
	case FEXPM1:		ftos = expm1(ftos);		break;
	case FLNP1:		ftos = log1p(ftos);		break;
#else
	/* These versions may not be as precise as the "MOREFP" versions */
	case FROUND:		ftos = floor(ftos+0.5);		break;
	case FACOSH:		ftos = log(ftos+sqrt(ftos*ftos-1.0)); break;
	case FASINH:		ftos = log(ftos+sqrt(ftos*ftos+1.0)); break;
	case FATANH:		ftos = log((1.0+ftos)/(1.0-ftos))/2.0; break;
	case FEXPM1:		ftos = exp(ftos)-1.0;		break;
	case FLNP1:		ftos = log(ftos+1.0);		break;
#endif

	/* Floating Point Stack Manipulation */
	case FDUP:		*--fsp = ftos;			break;
	case FDROP:		ftos = *fsp++;			break;
	case FOVER:		*--fsp = ftos; ftos = fsp[1];	break;
	case FSWAP:
		ftemp = ftos;
		ftos = *fsp;
		*fsp = ftemp;
		break;
	case FROT:
		ftemp = ftos;
		ftos = fsp[1];
		fsp[1] = fsp[0];
		fsp[0] = ftemp;
		break;
	case FMINROT:
		ftemp = ftos;
		ftos = fsp[0];
		fsp[0] = fsp[1];
		fsp[1] = ftemp;
		break;
    }
}

#define push(x)	*--sp = (cell)(x)
#define pop	*sp++

cell *
fintop(int op, cell *sp)
{
    /* Floating Point operations involving the Forth data stack */

    switch(op) {
	case FPZERO:		/* Top of Floating Point Stack */
		push( (u_char *)&floatstack[FSTKLEN] );
		break;
	case FDEPTH:
		push( &floatstack[FSTKLEN] - fsp );
		break;
	case FPSTORE:		/* Set Floating Point Stack Pointer */
		fsp = (double *)pop;
		break;

	/* Floating Point Memory Access */
	case FSTORE:
		p = (unsigned long *)pop;
		fbits.fb_float = ftos;
		ftos = *fsp++;
		*p++ = fbits.fb_long[0];
		*p++ = fbits.fb_long[1];
		break;
	case FFETCH:
		p = (unsigned long *)pop;
		*--fsp = ftos;
		fbits.fb_long[0] = *p++;
		fbits.fb_long[1] = *p++;
		ftos = fbits.fb_float;
		break;

	/* Move numbers between Floating Point and Integer Stacks */
	case FINT:	/* Float to Integer */
		push( ftos );
		ftos = *fsp++;
		break;
	case FFLOAT:	/* Integer to Float */
		*--fsp = ftos;
		ftos = (double)pop;
		break;
	case FPOP:	/* Move unconverted bits from FP stack to Int stack */
		p = (unsigned long *)sp;
		p -= 2;
		sp = (cell *)p;
		fbits.fb_float = ftos;
		p[1] = fbits.fb_long[1];
		p[0] = fbits.fb_long[0];
		ftos = *fsp++;
		break;
	case FPUSH:	/* Move unconverted bits from Int stack to FP stack */
		p = (unsigned long *)sp;
		*--fsp = ftos;
		fbits.fb_long[1] = p[1];
		fbits.fb_long[0] = p[0];
		sp = (cell *)(p+2);
		ftos = fbits.fb_float;
		break;

	/* Floating Point Input and Output */
	/* Implement F. as FSTRING TYPE , E. as ESTRING TYPE */
	case FSTRING:
		(void) sprintf(floatstr, "%.*f", (int)V(FNUMPLACES), ftos); 
		push( (u_char *)floatstr );
		push( strlen(floatstr) );
		ftos = *fsp++;
		break;
	case ESTRING:
		(void) sprintf(floatstr, "%.*e", (int)V(FNUMPLACES), ftos);
		push( (u_char *)floatstr );
		push( strlen(floatstr) );
		ftos = *fsp++;
		break;

	/* Comparisons */
#define flag(boolean)	((boolean) ? -1 : 0)
#define fbincmp(operator) \
	push ( flag(*fsp++ operator ftos) ); ftos = *fsp++;
#define funcmp(operator) \
	push ( flag(ftos operator 0.0) ); ftos = *fsp++;

	case FEQ:		fbincmp(==);			break;
	case FNEQ:		fbincmp(!=);			break;
	case FLT:		fbincmp(<);			break;
	case FGT:		fbincmp(>);			break;
	case FLEQ:		fbincmp(<=);			break;
	case FGEQ:		fbincmp(>=);			break;

	case FZEQ:		funcmp(==);			break;
	case FZNEQ:		funcmp(!=);			break;
	case FZLT:		funcmp(<);			break;
	case FZGT:		funcmp(>);			break;
	case FZLEQ:		funcmp(<=);			break;
	case FZGEQ:		funcmp(>=);			break;


	case FPICK:
		*--fsp = ftos;
		ftos = fsp[pop];
		break;
	case FNUMQUES:		/* True if string is a valid floating number */
		op = *sp++;
		*sp = (cell)isfloatnum((u_cell)*sp, (u_cell)op);
		break;
	case FNUMBER:		/* Convert string to floating point number */
		*--fsp = ftos;
		/*
		 * XXX This isn't exactly right - it doesn't allow
		 * the omission of the { D | d | E | e } in the exponent.
		 */
		op = *sp++;
		ftos = strtodbl((altofpstr((u_cell)*sp, (u_cell)op)), sp);
		*sp = *(char *)(*sp);	/* Get terminating character */
		break;

	case FSCALE:		/* Scale by exponent manipulation */
		ftos = ldexp(ftos, pop);
		break;

	case REPRESENT:		/* Convert fp number to digit string */
		{
		    int len = *sp++;
		    char *adr = (char *)(*sp++);
		    char *radr;
		    int decpt, sign;
		    extern char *ecvt();

		    radr = ecvt(ftos, len, &decpt, &sign);
		    ftos = *fsp++;

		    *--sp = decpt;
		    *--sp = sign ? -1 : 0;
		    *--sp = isdigit(*radr) ? -1 : 0;

		    /* Copy C string out into Forth buffer*/
		    while (len--) {
			/* If C string ends prematurely, pad with blanks */
			if (*radr == '\0') {
			    do {
				*adr++ = ' ';
			    } while (len--);
			    break;
			}
		        *adr++ = *radr++;
		    }
		}
		break;
	case FPROXIMATE:	/* ( -- flag )  ( F: r1 r2 r3 -- ) */
	    {
		double r1, r2;
		int result;

		r2 = *fsp++;
		r1 = *fsp++;
		
		if (ftos > 0.0)			/* Threshold match */
			result = abs(r1-r2) < ftos;
		else if (ftos == 0.0)		/* Exact match */
			result = r1 == r2;
		else				/* Relative match */
			result = abs(r1 - r2) < (-ftos * (abs(r1) + abs(r2)));

		ftos = *fsp++;
		*--sp = result ? -1 : 0;
	    }
	    break;

	/* Single-precision Floating Point Memory Access */
	case SFSTORE:
		p = (unsigned long *)pop;
		*(float *)p = (float)ftos;
		ftos = *fsp++;
		break;
	case SFFETCH:
		p = (unsigned long *)pop;
		*--fsp = ftos;
		ftos = (double)*(float *)p;
		break;
    }
    return(sp);
}

token_t *
fparenlit(token_t *ip)
{
	p = (unsigned long *)ip;
	fbits.fb_long[0] = *p++;
	fbits.fb_long[1] = *p++;
	*--fsp = ftos;
	ftos = fbits.fb_float;
	return ((token_t *)p);
}

isfloatnum(adr, len)
	register u_char *adr;
	register u_cell len;
{
	int efound = 0;
	register char *str = (char *)adr;

	/*
	 * Don't recognize floating point numbers unless base is decimal.
	 * This prevents the ambiguity with "e" for exponent or "e" for
	 * a hex digit.
	 */
	if (V(BASE) != 10)
		return(0);

	for ( ; len; len--) {
		switch (*str++) {
		case '0':  case '1':  case '2':  case '3':  case '4':
		case '5':  case '6':  case '7':  case '8':  case '9':
		case '+':  case '-':  case '.':
			break;
		/* case 'e': */	/* ANS Forth allows only uppercase "E" */
		case 'E':
			efound = 1;
			break;
	default:
			return(0);
		}
	}
	return(efound);
}

/*
 * Preprocess a Forth string to allow the form where the exponent
 * has a sign but no "e", e.g.  123.4+5
 */
char *
altofpstr(adr,len)
    register u_char *adr;
    register u_cell len;
{
    static char cstrbuf[40];

    register char *to   = cstrbuf;
    register char *from = (char *)adr;
    register char c, lastc;
    register int nonwhiteseen = 0;

    lastc = '\0';
    while ((len--) != 0) {
	c = *from++;

	/* Insert an "e" before the exponent if it is missing */
        if ((c == '+'  ||  c == '-')
	&& nonwhiteseen
	&& (lastc != 'D' && lastc != 'E' && lastc != 'd' && lastc != 'e') )
	    *to++ = 'e';

	if (isspace(c))
	    if (nonwhiteseen)	/* Skip trailing blanks */
		break;
	else 
	    nonwhiteseen = 1;

	if ((to - cstrbuf) >= 39)	/* Reject too-long strings */
		return("X");

	*to++ = c;

	lastc = c;
    }

    *to++ = '\0';
    return (cstrbuf);
}

#endif
