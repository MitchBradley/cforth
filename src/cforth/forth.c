// C Forth
// Copyright (c) 2008 FirmWorks

// prims.h and vars.h must be included externally - see the makefile

#define DEBUGGER

#include <stdio.h>
#include <stdint.h>
#include "forth.h"
#include "string.h"

#include "compiler.h"

#define binop(operator)  (tos = *sp++ operator tos)
#define loadtos          tos = *sp++
#define unop(operator)   (tos = operator tos)
#define bincmp(operator) tos = ((*sp++ operator tos)?-1:0)
#define uncmp(operator)  tos = ((tos operator 0)?-1:0)
#define branch           ip = (token_t *)((cell)ip + *(branch_t *)ip);
#define next             continue
#define push(whatever)   *--sp = tos; tos = (cell)(whatever)
#define pop              tos; loadtos
#define comma            ncomma(tos);   loadtos

extern void floatop(int op, cell *up);
extern cell *fintop(int op, cell *sp, cell *up);
extern token_t *fparenlit(token_t *ip);

extern cell (*ccalls[])();
extern cell doccall(cell (*function_adr)(), u_char *format, cell *up);

extern cell freadline(cell f, cell *sp, cell *up);

static size_t my_strlen(const char *s);
static cell strindex(u_char *adr1, cell len1, u_char *adr2, cell len2);
static void fill_bytes(u_char *to, u_cell length, u_char with);
static cell digit(cell base, u_char c);
static void ip_canonical(char *adr, cell len, cell *up);
static cell tonumber(cell *adrp, cell len, cell *nhigh, cell *nlow, cell *up);
static void umdivmod(u_cell *dhighp, u_cell *dlowp, u_cell u);
static void umtimes(u_cell *dhighp, u_cell *dlowp, u_cell u1, u_cell u2);
static void mtimesdiv(cell *dhighp, cell *dlowp, cell n1, cell n2);
static void cmove(u_char *from, u_char *to, u_cell length);
static void cmove_up(u_char *from, u_char *to, u_cell length);
static int compare(u_char *adr1, u_cell len1, u_char *adr2, u_cell len2);
static void reveal(cell *up);
static void hide(cell *up);
static int alnumber(char *adr, cell len, cell *nhigh, cell *nlow, cell *up);
static int split_string(char c, cell *sp, void *up);

const token_t freelocbuf[] = { FREELOC, UNNEST};

#ifdef RELOCATE
u_cell nrelbytes, nurelbytes;
u_char *relmap, *urelmap;
u_char bit[8] = { 128, 64, 32, 16, 8, 4, 2, 1 };
#endif
const u_char nullrelmap[1] = { 0 };

// Move a cell to the high half of a double cell
#define TOHIGH(a) (((u_double_cell_t)(a)) << CELLBITS)
// Move the high half of a double cell to a cell
#define HIGH(a)((a) >> CELLBITS)

void udot(u_cell u, cell *up);
void udotx(u_cell u, cell *up);

// int printing = 0;
// Execute an array of Forth execution tokens.
int
inner_interpreter(up)
    cell *up;
{
    cell *sp;
    token_t **rp;
    cell tos;
    token_t *ip;

    rp = (token_t **)V(XRP);  ip = *rp++;  sp = (cell *)V(XSP);  tos = *sp++;
    // No need to restore the floating point stack pointer, if any,
    // because it is never manipulated outside of floatops.c

    token_t token;
    cell scr;
    u_char *ascr;
    u_char *ascr1;
    double_cell_t dscr, dscr1;
    u_double_cell_t udscr;

    while(1) {
#ifdef DEBUGGER
	if (V(LESSIP)
	    && (token_t *)V(LESSIP) <= ip
	    && (token_t *)V(IPGREATER) > ip
	    && ++(V(CNT)) == 2)
	{
	    V(CNT) = 0;
	    token = *(token_t *) &V(TICK_DEBUG);
//	    printing = 3;
	    goto doprim;
	}
#endif
        token = *ip++;

doprim:

    switch (token) {
    case 0:
        FTHERROR("Tried to execute a null token\n");
//      udotx((u_cell)ip-sizeof(*ip), up);
//      udotx((u_cell)sp, up);
//      udotx((u_cell)rp, up);
//      udotx((u_cell)*rp, up);
//      emit('\n', up);
        /*                where(); */
        /*                udot((u_cell)ip); */
        goto abort;

/*$p invert */  case INVERT:     unop (~);     next;
/*$p and */     case AND:        binop (&);    next;
/*$p or */      case OR:         binop (|);    next;
/*$p xor */     case XOR:        binop (^);    next;
/*$p + */       case PLUS:       binop (+);    next;
/*$p - */       case MINUS:      binop (-);    next;
/*$p * */       case TIMES:      binop (*);    next;

/*$p shift */   case SHIFT:
    if ( tos < 0 ) {
        if (tos <= (-CELLBITS)) {
            ++sp;
            tos = 0;
        } else {
            tos = -tos;
            tos = (u_cell) *sp++ >> (u_cell)tos;
        }
    }
    else {
        if (tos >= CELLBITS) {
            ++sp;
            tos = 0;
        } else {
            binop(<<);
        }
    }
    next;

/*$p >>a */     case SHIFTA:
        if (tos >= CELLBITS) {
            ++sp;
            tos = 0;
        } else {
            binop(>>);
        }
        next;
/*$p dup */     case DUP:     *--sp = tos;  next;
/*$p drop */    case DROP:    loadtos;  next;
/*$p swap */    case SWAP:    scr = *sp;  *sp = tos;  tos = scr;  next;
/*$p over */    case OVER:    push(sp[1]);  next;
/*$p nip */     case NIP:     ++sp;  next;
/*$p tuck */    case TUCK:    scr = sp[0];  *--sp = scr;  sp[1] = tos;  next;
/*$p rot */     case ROT:
    scr = tos;  tos = sp[1];  sp[1] = sp[0];  sp[0] = scr;
    next;
/*$p -rot */    case MINUS_ROT:
    scr = tos;  tos = sp[0];  sp[0] = sp[1];  sp[1] = scr;
    next;

/*$p pick */    case PICK:      tos = sp[tos]; next;
/*$p roll */    case ROLL:
    for (scr = sp[tos]; tos; --tos)
        sp[tos] = sp[tos-1];
    tos = scr;
    ++sp;
    next;

/*$p ?dup */    case QUES_DUP:  if (tos) { *--sp = tos; }    next;
/*$p >r */      case TO_R:      *(cell *)--rp = pop;        next;
/*$p r> */      case R_FROM:    push( *(cell *)rp++ );    next;
/*$p r@ */      case R_FETCH:   push( *(cell *)rp );        next;
/*$p 2>r */     case TWOTO_R:
    *(cell *)--rp = *sp++;
    *(cell *)--rp = pop;
    next;

/*$p 2r> */     case TWOR_FROM:
    *--sp = tos;
    tos = *(cell *)rp++;
    *--sp = *(cell *)rp++;
    next;

/*$p 2r@ */     case TWOR_FETCH:
    *--sp = tos;
    *--sp = ((cell *)rp)[1];
    tos = *(cell *)rp;
    next;

/*$p ip! */     case IP_STORE:
    *rp = (token_t *)tos;
    loadtos;
    next;

/*$p ip@ */     case IP_FETCH:   push((cell)(*rp) );    next;

    /* We don't have to account for the tos in a register, because */
    /* push has already pushed tos onto the stack before */
    /* V(SPZERO) - sp  is computed */

/*$p depth */   case DEPTH:             push((cell *)V(SPZERO) - sp) ; next;
/*$p < */       case LESS:              bincmp (<);     next;
/*$p = */       case EQUAL:             bincmp (==);    next;
/*$p > */       case GREATER:           bincmp (>);     next;
/*$p 0< */      case ZERO_LESS:         uncmp (<);      next;
/*$p 0= */      case ZERO_EQUAL:        uncmp (==);     next;
/*$p 0> */      case ZERO_GREATER:      uncmp (>);      next;
/*$p u< */      case U_LESS:
    tos = ((u_cell) * sp++ < (u_cell) tos) ? -1 : 0;
    next;

/*$p 1+ */      case ONE_PLUS:     tos++;            next;
/*$p 2+ */      case TWO_PLUS:     tos += 2;     next;
/*$p 2- */      case TWO_MINUS:    tos -= 2;     next;
/*$p um* */     case U_M_TIMES:
    udscr = (u_double_cell_t)*(u_cell *)sp;
    udscr *= (u_cell)tos;
    *sp  = (u_cell)udscr;
    tos  = (u_cell)HIGH(udscr);
    next;

/*$p m* */      case M_TIMES:
    dscr = (double_cell_t)*sp;
    dscr *= tos;
    *sp  = dscr;
    tos  = HIGH(dscr);
    next;

/*$p m%/ */     case M_TIMDIV:
    scr = *sp++;
    mtimesdiv(sp, sp+1, scr, tos);
    loadtos;
    next;

/*$p 2/ */      case TWO_DIVIDE:   tos >>= 1;  next;
/*$p max */     case PMAX:  scr = *sp++; if (tos < scr) { tos = scr; }    next;
/*$p min */     case PMIN:  scr = *sp++; if (tos > scr) { tos = scr; }    next;
/*$p abs */     case ABS:                if (tos < 0)   { tos = -tos; }   next;
/*$p negate */  case NEGATE:    unop (-);  next;
/*$p @ */       case FETCH:
    tos = nfetch((cell *)tos);
    next;
/*$p c@ */      case C_FETCH:   tos = *(u_char *)tos;   next;
/*$p w@ */      case W_FETCH:   tos = *(uint16_t *)tos; next;
/*$p l@ */      case L_FETCH:   tos = *(uint32_t *)tos; next;

/*$p /int */    case SLASH_INT:  push(sizeof(int));          next;
/*$p uint@ */   case UINT_FETCH: tos = *(unsigned int *)tos; next;
/*$p int@ */    case INT_FETCH:  tos = *(int *)tos;          next;
/*$p int! */    case INT_STORE:  *(int *)tos = *sp++;  loadtos;  next;

/*$p token@ */  case TOK_FETCH:
token_fetch:
    token = *(token_t *)tos;
    if (token < MAXPRIM) {
        token = ((token_t *)V(TORIGIN))[token];
    }
    tos = (cell)XT_FROM_CT(token, up);
    next;

/*$p ! */       case STORE:
    nstore((cell *)tos, *sp++);
    loadtos;
    next;

/*$p c! */      case C_STORE:
    *(u_char *)tos = (u_char)*sp++;
    loadtos;
    next;

/*$p w! */      case W_STORE:
    *(uint16_t *)tos = (uint16_t)*sp++;
    loadtos;
    next;

/*$p l! */      case L_STORE:
    *(uint32_t *)tos = *sp++;
    loadtos;
    next;

/*$p xt>ct */   case XT_TO_CT:
    ascr = (u_char *)tos;
    scr = ascr - (u_char *)V(TORIGIN);
    if ( (scr >= 0)  &&  (scr < V(BOUNDARY)) && (*(token_t *)ascr < MAXPRIM) ) {
	tos = (cell)*(token_t *)ascr;
    } else {
        tos = (cell)CT_FROM_XT((xt_t)ascr, up);
    }
    next;

/*$p token! */  case TOK_STORE:
    ascr = (u_char *)*sp++;
    scr = ascr - (u_char *)V(TORIGIN);
    if ( (scr >= 0)  &&  (scr < V(BOUNDARY)) && (*(token_t *)ascr < MAXPRIM) ) {
        *(token_t *)tos = *(token_t *)ascr;
    } else {
        *(token_t *)tos = CT_FROM_XT((xt_t)ascr, up);
    }
    // XXX need to set relocation bit
    loadtos;
    next;

/*$p branch! */  case BRANCH_STORE:
    *(branch_t *)tos = (branch_t)*sp++;
    loadtos;
    next;

/*$p branch@ */  case BRANCH_FETCH:
    tos = (cell)(*(branch_t *)tos);
    next;

/*$p +! */      case PLUS_STORE:
    nstore((cell *)tos, nfetch((cell *)tos) + *sp++);
    loadtos;
    next;

/*$p cmove */    case CMOVE:
    ascr  = (u_char *)(*sp++);
    ascr1 = (u_char *)(*sp++);
    cmove(ascr1, ascr, (u_cell)tos);
    loadtos;
    next;

/*$p cmove> */  case CMOVE_UP:
    ascr  = (u_char *)(*sp++);
    ascr1 = (u_char *)(*sp++);
    cmove_up(ascr1, ascr, (u_cell)tos);
    loadtos;
    next;

/*$p fill */    case FILL:
    scr  = *sp++;
    ascr = (u_char *)(*sp++);
    fill_bytes((u_char *)ascr,(u_cell)scr,(u_char)tos);
    loadtos;
    next;

/*$p compare */ case COMPARE:
    ascr  = (u_char *)(*sp++);
    scr   = *sp++;
    ascr1 = (u_char *)(*sp++);
    tos = compare(ascr1, (u_cell)scr, ascr, (u_cell)tos);
    next;

/*$p count */   case COUNT:
    *--sp = (cell)(tos + 1);
    ascr = (u_char *)tos;
    tos = (cell)(*ascr);
    next;

/*$p -trailing */ case DASH_TRAILING:
    ascr  = (u_char *) (*sp + tos);
    tos++;
    while ((--tos != 0) && (*--ascr == ' '));
    next;

/*$p cell+ */   case CELL_PLUS: tos += sizeof(cell); next;

/*$p i */       case I:
    push(((cell *)rp)[0] + ((cell *)rp)[1]);
    next;

/*$p ilimit */  case ILIMIT:
    push(((cell *)rp)[1]);
    next;

/*$p j */       case J:
    push(((cell *)rp)[3] + ((cell *)rp)[4]);
    next;

/*$p jlimit */  case JLIMIT:
    push(((cell *)rp)[4]);
    next;

/*$p branch */  case PBRANCH:
    branch;
    next;

/*$p ?branch */ case QUES_BRANCH:
    if (tos == 0) {
        branch;
    } else {
        ip = (token_t *)(((char *)ip) + sizeof(branch_t));
    }
    loadtos;
    next;

/*$p unnest */  case UNNEST:
/*$p exit */    case EXIT:    ip = *rp++;     next;
/*$p execute */ case EXECUTE:
    ascr = (u_char *)pop;
    token = CT_FROM_XT((xt_t)ascr, up);
execute:
    if ((token_t)token > MAXPRIM
        &&  (scr = (cell)*(token_t *)XT_FROM_CT(token, up)) < MAXPRIM)
        token = (token_t)scr;
    goto doprim;

/*$p behavior */case BEHAVIOR:
    ascr = (u_char *)(tos + sizeof(token_t));  // Body address
    tos = (cell) ((u_char *)up + *(unum_t *)ascr);
    goto token_fetch;

/*$p key */     case KEY:
    scr = key(up);
    if (scr == -2) {
        // Save interpreter state, return, and expect reentry
        // to inner_interpreter() upon a later callback
	scr = 2;  goto out;
    }
    push(scr);
    next;

/*$p key? */    case KEY_QUESTION:
    scr = key_avail(up);
    if (scr == -2) {
        // Save interpreter state, return, and expect reentry
        // to inner_interpreter() upon a later callback
        scr = 2;  goto out;
    }
    push(scr);
    next;

/*$p sys-emit */    case EMIT:    emit((u_char)tos, up);    loadtos;    next;
/*$p sys-cr */      case CR:      emit('\n', up);  V(NUM_OUT) = 0;  V(NUM_LINE)++;  next;

/*$p >body */    case TO_BODY:   tos += sizeof (token_t); next;
/*$p allot */    case ALLOT:
    V(DP) += tos;
    loadtos;
    if ((cell)V(DP) > V(LIMIT))
        FTHERROR( "Out of dictionary space\n");
    next;

/*$p $find */    case ALFIND:
    { xt_t *xt;
        scr = alfind((char *)*sp, tos, (xt_t *)&xt, up);
        if (scr) {
            *sp = (cell)xt;
            tos = scr;
        } else {
            push(scr);
        }
        next;
    }

/*$p search-wordlist */    case SEARCH_WORDLIST:
    scr = *sp++;
    tos = canon_search_wid((char *)(*sp), scr,
        (vocabulary_t *)tos, (xt_t *)sp, up);
    if (!tos)
        ++sp;    /* No xt if word not found */
    next;

/*$p (search-wordlist) */    case PAREN_SEARCH_WORDLIST:
    scr = *sp++;
    tos = search_wid((char *)(*sp), scr,
        (vocabulary_t *)tos, (xt_t *)sp, up);
    if (!tos)
        ++sp;    /* No xt if word not found */
    next;

/*$p $canonical */      case CANONICAL:
    ip_canonical ((char *)(*sp), tos, up);
    next;

/*$p sys-accept */ case SYS_ACCEPT:
    scr = pop;
    ascr = (u_char *)pop;
    scr = caccept((char *)ascr, scr, up);
    if (scr == -2) {
        // Save interpreter state, return, and expect reentry
        // to inner_interpreter() upon a later callback
        scr = 2;  goto out;
    }
    push(scr);
    next;

/*$p abort */   case ABORT:
    abort:
        push(-1);
        /* Fall through */

/*$p throw */   case THROW:
    if (tos == 0) {  loadtos; next;  }

    if (V(HANDLER) == 0) {
        V(STATE) = INTERPRETING;
        reveal(up);
        if (V(COMPLEVEL)) {
            V(DP) = V(SAVED_DP);
            V(LIMIT) = V(SAVED_LIMIT);
            V(COMPLEVEL) = 0;
        }
        /*
         * Restore the local copies of the virtual
         * machine registers to the external copies
         * and exit to the outer interpreter.
         */
        V(XSP) = V(SPZERO);
        V(XRP) = V(RPZERO);

        return(1);
    }

    {
        xt_t *trp = (xt_t *)V(RSSAVE);
        *trp++ = ip;
        while (rp < (xt_t *)V(HANDLER)) {
            *trp++ = *rp++;
        }
        V(RSMARK) = (cell)trp;
    }
    // rp = (token_t **)V(HANDLER);
    V(HANDLER) = (cell)*rp++;
    /* Error num remains in tos */
    sp = ((cell *)*rp++) + 1;  // Saved SP included acf location
    ip = *rp++;

    next;

/*$p finished */ case FINISHED:
    /*
     * Save the local copies of the virtual machine
     * registers to the external copies and exit to the
     * outer interpreter.
     */
    // Discard the current IP value since we do not want the ctbuf[]
    // "definition" to stay on the return stack
    ip = *rp++;
    scr = 0;     // Return value from inner_interpreter()
    goto out;

/*$p finished-pop */ case FINISHED_POP:
    /*
     * Save the local copies of the virtual machine
     * registers to the external copies and exit to the
     * outer interpreter.
     */
    // Discard the current IP value since we do not want the ctbuf[]
    // "definition" to stay on the return stack
    ip = *rp++;
    scr = pop;     // Return value from inner_interpreter()
    goto out;

/*$p rest */ case REST:
     // rest is for returning to the enclosing system, so
     // Forth execution can be resumed where it left off
     // by calling inner_interpreter() without changing
     // the stacks.  The call to inner_interpreter() can
     // be scheduled on a timer or an event 
     scr = 3;   // Return value from inner_interpreter
     goto out;

/*$p continuation */ case CONTINUATION:
    /*
     * Restore the local copies of the virtual machine
     * registers to the external copies and exit, returning
     * the top of the stack.  This is useful for returning
     * from callbacks so that a further callback can pick up
     * where we left off.
     */
    scr = pop;

    out:
    // No need to save the floating point stack pointer, if any,
    // because it is never manipulated outside of floatops.c
    *--sp = tos; V(XSP) = (cell)sp;  *--rp = ip;  V(XRP) = (cell)rp;
    return(scr);

    /*$p (pause */ case PAREN_PAUSE:
    *--sp = tos; V(XSP) = (cell)sp;
    *--rp = ip;  V(XRP) = (cell)rp;
    do {
        up = (cell*)V(LINK);
    } while(V(ASLEEP));
    sp = (cell *)V(XSP);  tos = *sp++;
    rp = (token_t **)V(XRP); ip = *rp++;
    next;

/*$p 0 */       case ZERO:      push(0);                 next;
/*$p here */    case HERE:      push(V(DP));             next;
/*$p tib */     case TIB:       push(V(TICK_TIB));       next;
/*$p /tib */    case SLASH_TIB: push(TIBSIZE);           next;
/*$p parse */   case PARSE:     tos = parse((u_char)tos, --sp, up);  next;
/*$p parse-word */ case PARSE_WORD:
    *--sp = tos;
    tos = parse_word((u_char **)--sp, up);
    next;

/*$p , */       case COMMA:     comma;  next;

/*$i ; */       case SEMICOLON:
    compile(UNNEST);
    reveal(up);
    V(STATE) = INTERPRETING;
    next;

/*$p :noname */ case COLON_NONAME:
    place_cf(DOCOLON, up);
    push(XT_FROM_CT(*(token_t *)&V(LASTP), up));
    V(STATE) = COMPILING;
    V(NUMINS) = 0;
    next;

/*$p : */       case COLON:
    create_word (DOCOLON, up);
    hide(up);
    V(STATE) = COMPILING;
    V(NUMINS) = 0;
    next;

/*$p constant */    case CONSTANT: create_word (DOCON, up);   comma;         next;
/*$p user */        case USER:     create_word (DOUSER, up);  comma;         next;
/*$p variable */    case VARIABLE: create_word (DOVAR, up);
                        ncomma(V(NUM_USER)); V(NUM_USER) += sizeof(cell);
                        next;
/*$p create */      case CREATE:   create_word (DOCREATE, up);               next;
/*$p $create */     case STR_CREATE:
    ascr = (u_char *)*sp++;
    header((char *)ascr, tos, up);
    place_cf((token_t)DOCREATE, up);
    loadtos;
    next;

/*$p $header */     case HEADER:   header((char *)*sp++, tos, up);    loadtos;   next;

/*$p acf-align     */ case ACFALIGN:     xt_align(up);  next;

/*$p colon-cf      */ case COLONCF:      place_cf(DOCOLON, up);          next;
/*$p defer-cf      */ case DEFERCF:      place_cf(DODEFER, up);          next;
/*$p user-cf       */ case USERCF:       place_cf(DOUSER, up);           next;
/*$p value-cf      */ case VALUECF:      place_cf(DOVALUE, up);          next;
/*$p constant-cf   */ case CONSTANTCF:   place_cf(DOCON, up);            next;
/*$p nnvariable    */ case NNVARIABLE:   place_cf(DOVAR, up); ncomma(0); next;
/*$p create-cf     */ case CREATECF:     place_cf(DOCREATE, up);         next;
/*$p vocabulary-cf */ case VOCABULARYCF: place_cf(DOVOC, up);            next;

/*$p user-size */   case USER_SIZE:   push(MAXUSER);     next;
/*$p immediate */   case IMMEDIATE:   makeimmediate(up);  next;

/*$p +level */      case PLUS_LEVEL:
    if (V(COMPLEVEL))
        ++V(COMPLEVEL);
    else if (V(STATE) == INTERPRETING) {
        V(COMPLEVEL) = 1;
        V(SAVED_DP) = V(DP);
        V(SAVED_LIMIT) = V(LIMIT);
        V(DP) = V(COMPBUF);
        V(LIMIT) = V(COMPBUF) + CBUFSIZE*sizeof(token_t);
        V(STATE) = COMPILING;
        /* XXX should save stack depth */
    }
    next;

/*$p -level */      case MINUS_LEVEL:
    if (V(STATE) == INTERPRETING)
        FTHERROR("Conditionals not paired\n");
    if (V(COMPLEVEL)) {
        --V(COMPLEVEL);
        if (V(COMPLEVEL) == 0) {      // Dropped back to level 0
            compile(EXIT);            // compile(EXIT);
            V(DP) = V(SAVED_DP);
            V(LIMIT) = V(SAVED_LIMIT);
            V(STATE) = INTERPRETING;
            // XXX should check stack depth
            ascr = (u_char *)V(COMPBUF);
            goto colon;       // Execute the compile buffer as a colon definition
        }
    }
    next;

/*$p (') */     case PAREN_TICK:        push( XT_FROM_CT(*ip++, up));      next;
/*$p (char) */  case PAREN_CHAR:
    scr = nfetch((cell *)ip);
    ip = (token_t *)((u_char *)ip + sizeof(cell));
    push(scr);
    next;

/*$p (lit) */   case PAREN_LIT:
    scr = nfetch((cell *)ip);
    ip = (token_t *)((u_char *)ip + sizeof(cell));
    push(scr);
    next;

/*$p (wlit) */ case PAREN_LIT16:
    push( *(branch_t *)ip );
#ifdef T16
    ip   = (token_t *)((u_char *)ip + sizeof(branch_t));
#else
    ip   = (token_t *)((u_char *)ip + sizeof(cell));
#endif
    next;

/*$p xtliteral */ case XTLITERAL:
    compile(PAREN_TICK);
    compile(CT_FROM_XT((xt_t)tos, up));
    loadtos;
    next;

/*$p compile, */case COMPILE_COMMA:
    if ( (((u_char *)tos - (u_char *)V(TORIGIN)) < V(BOUNDARY))  &&  (*(token_t *)tos < MAXPRIM) )  {
        compile(*(token_t *)tos);
    } else {
        compile (CT_FROM_XT((xt_t)tos, up));
    }
    loadtos;
    next;

/*$p dup. */    case DUPDOT:
    scr = (cell) ascr;  // Place for a debugging breakpoint
#ifdef DEBUG
    printf("%x\n", tos);
#endif
    next;
/* XXX need UNLOOP */

/*$p ?leave */  case QUES_LEAVE:
    scr = pop;
    if (!scr) { next; }
    /* else fall through */

/*$p leave */   case LEAVE:
    rp += 2;                // Discard the loop indices
    ip = *(token_t **)rp++; // Go to location after (do
    branch;                 // Get the offset there
    next;

/*$p (?do) */   case PAREN_QUESTION_DO:
    scr = *sp++;
    if ( scr == tos ) { loadtos; branch; next; }

    *--rp = ip;                  // Addr of offset to end
    ip = (token_t *)((u_char *)ip + sizeof(branch_t));
    *(cell *)--rp = scr ;        // limit value
    *(cell *)--rp = tos - scr ;  // Distance up to 0
    loadtos;
    next;

/*$p (do) */    case P_DO:
    scr = *sp++;

    *--rp = ip;                  // Addr of offset to end
    ip = (token_t *)((u_char *)ip + sizeof(branch_t));
    *(cell *)--rp = scr ;        // limit value
    *(cell *)--rp = tos - scr ;  // Distance up to 0
    loadtos;
    next;

/*$p (loop) */  case PAREN_LOOP:
    if (++(*(cell *)rp) != 0) {
        branch;
        next;
    }
    // Loop termination: clean up return stack and skip branch offset
    rp = (token_t **)  ((char *)rp + 2*sizeof(cell) + sizeof(branch_t *));
    ++ip;
    next;

/*$p (+loop) */ case PAREN_PLUS_LOOP:

    // The loop terminates when the index crosses the boundary between
    // limit-1 and limit.  We have biased the internal copy of the index
    // so that the loop terminates when the internal index crosses the
    // boundary between -1 and 0.  In the +LOOP case, we have to cope
    // with the possibility of either positive or negative increment
    // values.  The following calculation assumes 2's-complement
    // arithmetic.  It can be understood as follows:
    // tos: increment value   scr: old biased index
    // scr+tos: new biased index
    // Continue looping if the new biased index and the increment
    // value have different signs (we haven't crossed the boundary yet),
    // or if the old biased index and the increment value have the
    // same sign (we are more than half the number circle away from
    // the -1/0 boundary).
    // This scheme allows loops to work over both signed number ranges
    // and unsigned address ranges, with problems at the "rollover"
    // point where the largest signed positive integer is adjacent to
    // the smallest negative integer.
    // Typically, in assembly language Forth implementations, the
    // index is biased to terminate at that rollover point, using the
    // overflow bit to test for the boundary crossing.  The overflow
    // bit is not available from C.  A calculation very similar to the
    // following may be used to test for overflow (just interchange
    // < and >=).  However, the cell LOOP case may be implemented more
    // efficiently in C when the boundary is at 0, and we must use the
    // same boundary for LOOP and +LOOP since the same DO sets up the
    // biased index in both cases.

    scr = *(cell *)rp;
    if ((((*(cell *)rp = scr+tos)^tos) < 0)
        || ((scr^tos) >= 0)) {
        loadtos; branch; next;
    }
    // Loop termination: clean up return stack and skip branch offset
    loadtos;
    rp = (token_t **)
        ((char *)rp + 2*sizeof(cell) + sizeof(token_t *));
    ++ip;
    next;

/*$p (does) */  case P_DOES:
    tokstore(CT_FROM_XT(ip, up), (token_t *)LAST);
    ip = *rp++;
    next;

/*$p compile */ case COMPILE: compile(*ip++);    next;

/*$p bye */     case BYE:  return(-1);
/*$p lose */    case LOSE: FTHERROR("Undefined word encountered\n");  goto abort;

    // There's no need to modify sp to account for the top of stack
    // being in a register because push has already put tos on the
    // stack before the argument ( sp ) is evaluated

/*$p sp@ */     case SPFETCH:   push((cell)sp); next;
/*$p sp! */     case SPSTORE:   sp = (cell *)tos + 1;  next;

/*$p rp@ */     case RPFETCH:   push((cell)rp); next;
/*$p rp! */     case RPSTORE:   rp = (token_t **)tos;  loadtos;  next;

/*$p up@ */     case UPFETCH:   push((cell)up);        next;
/*$p up! */     case UPSTORE:   up = (cell *)tos;  loadtos;  next;

#define FLOORFIX(dividend, divisor, remainder)  \
        ((dividend < 0) ^ (divisor < 0))  &&  (remainder != 0)
/*$p / */       case DIVIDE:
    {
    register cell quot, rem;

    scr = *sp++;
    quot = scr/tos;
    rem  = scr - tos*quot;
    if (FLOORFIX(tos,scr,rem))
        tos = quot - 1;
    else
        tos = quot;
    }
    next;

/*$p mod */     case MOD:
    {
    register cell rem;

    scr = *sp++;  rem = scr%tos;
    if (FLOORFIX(tos,scr,rem))
        tos = tos + rem;
    else
        tos = rem;
    }
    next;

/*$p x%/mod */  case TIM_DIV_MOD:
    {
        register long dividend;
        register cell quot, rem;
        dividend = *sp++;
        dividend *= *sp++;
        quot = dividend/tos;
        rem  = dividend - tos*quot;
        if (FLOORFIX(dividend,tos,rem)) {
            *--sp = rem  + tos;
            tos = quot - 1;
        } else {
            *--sp = rem ;
            tos = quot;
        }
    }
    next;

/*$p /mod */    case DIVIDE_MOD:
    scr = *sp; *sp = scr%tos;
    if (((scr < 0) ^ (tos < 0))  &&  *sp != 0) {
        *sp += tos;
        tos = (scr/tos) - 1;
        next;
    }
    tos = scr/tos;
    next;

/*$p dnegate */ case DNEGATE:
    tos = ~tos + ((*sp = -*sp) == 0);  /* 2's complement */
    next;

/*$p d- */      case DMINUS:
    dscr1  = TOHIGH(tos);
    dscr1 += (u_cell)*sp++;
    dscr   = TOHIGH(*sp++);
    dscr  += (u_cell)*sp;
    dscr -= dscr1;
    *sp   = (u_cell)dscr;
    tos   = HIGH(dscr);
    next;

/*$p d+ */      case DPLUS:
    dscr   = TOHIGH(tos);
    dscr  += (u_cell)*sp++;
    dscr1  = TOHIGH(*sp++);
    dscr1 += (u_cell)*sp;
    dscr += dscr1;
    *sp   = (u_cell)dscr;
    tos   = HIGH(dscr);
    next;

/*$p um/mod */  case U_M_DIVIDE_MOD:
    udscr = TOHIGH(*sp++);
    udscr += (u_cell)*sp;
    *sp  = (u_cell)(udscr % (u_cell)tos);
    tos  = (u_cell)(udscr / (u_cell)tos);
    next;

/*$p sm/rem */  case S_M_DIVIDE_REM:
    dscr = TOHIGH(*sp++);
    dscr += (u_cell)(*sp);
    *sp  = dscr % tos;
    tos  = dscr / tos;
    next;

/*$p digit */   case DIGIT:
    if ( (scr = digit( tos, (u_char)*sp )) >= 0 ) {
        *sp = scr; tos = -1;
    } else
        tos = 0;
    next;

/*$p $number? */        case ALNUM_QUESTION:
    ascr = (u_char *)(*sp--);
    tos = alnumber( (char *)ascr, tos, sp, sp+1, up);
    if ( !tos )
        sp += 2;
    next;

/*$p >number */ case TO_NUMBER: tos = tonumber( sp, tos, sp+1, sp+2, up);  next;
/*$p hide */    case HIDE:      hide(up);    next;
/*$p reveal */  case REVEAL:    reveal(up);  next;

/*$p standalone? */     case STANDALONEQ:  push(isstandalone());   next;
/*$p interactive? */    case INTERACTIVEQ: push(isinteractive());  next;
/*$p more-input? */     case MOREINPUT:    push(moreinput(up));    next;
/*$p origin */          case ORIGIN:       push(V(TORIGIN));       next;
/*$p unused */          case UNUSED:       push(V(LIMIT)-V(DP));   next;
/*$p /token */          case SLASH_TOKEN:  push(sizeof(token_t));  next;
/*$p /branch */         case SLASH_BRANCH: push(sizeof(branch_t)); next;
/*$p maxprimitive */    case MAXPRIMITIVE: push(MAXPRIM);          next;

/*$p cells */   case CELLS:  tos *= sizeof(cell);  next;

/*$p ccall */   case CCALL:
//    scr = pop; V(XSP) = (cell)sp; V(XRP) = (cell)rp;
//    tos = doccall ((cell (*)())ccalls[scr], (u_char *)tos, up);
//    rp = (token_t **)V(XRP); sp = (cell *)V(XSP);
//    next;
    tos = (cell)ccalls[tos];
    // Fall through

/*$p acall */   case ACALL:
    scr = pop; V(XSP) = (cell)sp; V(XRP) = (cell)rp;
    tos = doccall ((cell (*)())scr, (u_char *)tos, up);
    rp = (token_t **)V(XRP); sp = (cell *)V(XSP);
    next;

#ifndef NOSYSCALL
/*$p syscall */ case SYSCALL:
    scr = pop; ascr1 = (u_char *)sp;
    tos = dosyscall(scr, tos, (cell **)&ascr1);
    sp = (cell *)ascr1;
    next;

/*$p $command */case COMMAND:
    push(alsystem((char *)*sp++, tos));
    next;

/*$p $chdir */  case CHDIR:
    push(alchdir((char *)*sp++, tos));
    V(ERRNO) = (tos < 0) ? errno : 0;
    next;

/*$p errno */   case PERRNO:    push(V(ERRNO)); next;  /* Self fetching */
/*$p why */     case WHY:       prerror("", up); next;
#endif

/*$p bl */      case BL:        push(' ');  next;
/*$p search */  case SEARCH:
    /* adr1 len1 adr2 len2 -- adr1' len1' flag */
    /* len2 in tos */
    ascr  = (u_char *)(*sp++);  // adr2 in ascr
    scr = *sp;                  // len1 in scr
    ascr1 = (u_char *)sp[1];    // adr1 in ascr1
    tos = strindex(ascr1, scr, ascr, tos);
    if (tos == -1)              // Match not found
        tos = 0;                // Return FALSE
    else {                      // tos is offset to match
        sp[1] += tos;           // advance address
        sp[0] -= tos;           // decrement count
        tos = -1;               // Return TRUE
    }
    next;

/*$p allocate */case ALLOCATE:
    tos = (cell)aln_alloc(tos, up);
    *--sp = tos;
    tos = tos ? 0 : ALLOCFAIL;      /* Error code */
    next;

/*$p free */    case MFREE:
    memfree((char *)tos, up);
    tos = 0;
    next;

/*$p resize */  case RESIZE:
    tos = (cell)memresize((char *)(*sp), tos, up);
    *sp = tos;
    tos = tos ? 0 : ALLOCFAIL;      /* Error code */
    next;

/*$p >relbit */ case TORELBIT:
#ifdef RELOCATE
    /*
     * If address is in dictionary, return address in
     * dictionary relocation map.
     */
     scr = tos;
     ascr = &relmap[scr>>3];
     if (ascr >= relmap  &&  scr < V(LIMIT)) {
         tos = (cell)ascr;
         push(bit[scr & 7]);
         next;
     }
     /*
      * If address is in user area, return address in
      * user area relocation map.
      */
     scr = (cell)((cell *)tos - up);
     ascr = &urelmap[scr>>3];
     if (ascr >= urelmap  &&  scr < MAXUSER) {
         tos = (cell)ascr;
         push(bit[scr & 7]);
         next;
     }
#endif
     /*
      * Otherwise, return a "safe" address and a 0 bitmask.
      */
     tos = (cell)nullrelmap;
     push(0);
     next;

#ifdef FLOATING
/*$p floatop */ case FLOATOP:
     floatop((int)tos, up);  loadtos;
     next;

/*$p fintop */  case FINTOP:
     sp = fintop((int)tos, sp, up);  loadtos;
     next;

/*$p (fliteral) */      case FPAREN_LIT:
     ip = fparenlit(ip);
     next;

#endif

#ifdef OPENGL
/*$p glop */ case GLOP:
     {
     extern double *fsp, ftos;
     extern void glop(int, cell **, double **, cell *);
     *--fsp = ftos;
     glop((int)tos, &sp, &fsp, up);
     ftos = *fsp++;
     loadtos;
     next;
     }
#endif

/*$i float? */  case FPRESENT:
#ifdef FLOATING
     push(-1);
#else
     push(0);
#endif
     next;

/*$p get-local */   case GETLOC:  tos = ((cell *)V(XFP))[tos];  next;
/*$p set-local */   case SETLOC:  ((cell *)V(XFP))[tos] = (cell)(*sp++);  loadtos;  next;

/*$p allocate-locals */ case ALLOCLOC:
    ascr = (u_char *)rp;    /* #locals */
    rp -= tos;              /* + *sp++ */
    *--rp = (token_t *)V(XFP);
    *--rp = (token_t *)ascr;
    V(XFP) = (cell)(rp+2);
    for (scr = 0; scr < tos; scr++)
        ((cell *)V(XFP))[scr] = *sp++;
    loadtos;
    *--rp = (xt_t)freelocbuf;  // Cast prevent "const" warning
    next;

/*$p free-locals */ case FREELOC:
    V(XFP) = (cell)(((cell *)V(XFP))[-1]);
    rp = *(token_t ***)rp;
    next;

/*$p local-name */  case LOCNAME:        /* name-str data code -- */
    {
    struct local_name *locnames = (struct local_name *)V(LOCALS);
    locnames[V(NUMINS)].code = CT_FROM_XT((xt_t)tos, up);
    locnames[V(NUMINS)].l_data = *sp++;
    locnames[V(NUMINS)].name[0] = (u_char)*sp++;
    cmove((u_char *)(*sp++),
          &locnames[V(NUMINS)].name[1],
          (u_cell)(locnames[V(NUMINS)].name[0]));
    ++V(NUMINS);
    loadtos;
    }
    next;

/*$p do-local-name */ case DOLOCNAME:
    {
    struct local_name *locnames = (struct local_name *)V(LOCALS);
    push(locnames[V(LOCNUM)].l_data);
    token = locnames[V(LOCNUM)].code;
    }
    goto execute;

// File operations

/*$p save */        case SAVE:  /* adr len -- */
    write_dictionary((char *)*sp++, tos, (char *)V(TORIGIN), V(DP)-V(TORIGIN),
                     (cell *)up, V(NUM_USER));
    loadtos;
    next;

/*$p read-line */   case READ_LINE:  /* adr len fid -- actual more? ior */
    tos = freadline(tos, sp, up);
    next;

/*$p r/o */         case R_O:  push(0);  next;
/*$p open-file */   case OPEN_FILE:  /* adr len mode -- fid ior */
    scr = pop;   // mode
    tos = pfopen((char *)*sp, tos, scr, up);
    *sp = tos;
    tos = tos ? 0 : OPENFAIL;
    next;

/*$p close-file */  case CLOSE_FILE:  /* fid -- ior */
    tos = pfclose(tos, up);     /* EOF on error */
    next;

/*$p flush-file */  case FLUSH_FILE:  /* fid -- ior */
    tos = pfflush(tos, up);     /* EOF on error */
    next;

/*$p file-size */  case FILE_SIZE:  /* fid -- ud ior */
    sp -= 2;
    tos = pfsize(tos, (u_cell *)&sp[0], (u_cell *)&sp[1], up);
    next;

/*$p to-ram */  case TO_RAM:
    V(RAMTOKENS) = pop;
    V(RAMCT) = (cell)CT_FROM_XT((xt_t)V(DP), up);
    V(DP) = V(RAMTOKENS);
    next;

/*$p read-file */  case READ_FILE:      /* adr len fid -- actual ior */
    ascr = (void *)pop;    // fid
    tos = pfread(sp, tos, ascr, up);
    next;

/*$p write-file */  case WRITE_FILE:      /* adr len fid -- ior */
    ascr = (void *)pop;    // fid
    scr = pop;             // len
    tos = pfwrite((void *)tos, scr, ascr, up);
    next;

/*$p reposition-file */  case REPOSITION_FILE:      /* ud fid -- ior */
    tos = pfseek((void *)tos, sp[0], sp[1], up);
    sp += 2;
    next;

/*$p file-position */  case FILE_POSITION:     /* fid -- ud ior */
    sp -= 2;
    tos = pfposition((void *)tos, (u_cell *)&sp[0], (u_cell *)&sp[1], up);
    next;

/*$p w/o */         case W_O:  push(1);  next;
/*$p r/w */         case R_W:  push(2);  next;
/*$p bin */         case BIN:  push(4);  next;
/*$p create-file */ case CREATE_FILE:
    scr = pop;   // mode
    tos = pfcreate((char *)*sp, tos, scr, up);
    *sp = tos;
    tos = tos ? 0 : OPENFAIL;
    next;

/*$p mark-input */ case MARK_INPUT:  // fid --
    pfmarkinput((void *)tos, up);
    loadtos;
    next;

/*$p .input-stack */ case PRINT_INPUT_STACK:  // --
    pfprint_input_stack();
    next;


/*$p split-string */ case SPLIT_STRING:  // a1 l1 char -- a1 l2 a1+l2 l1-l2
    tos = split_string(tos, --sp, up);
    next;

// Logging captures everything that goes out via emit.  Usage:
//   log{ <logged> }log  <not_logged>  log{ <logged> }log
//   log$ type
//   clear-log
// Subsequent uses of log{ append to the log until clear-log

/*$p clear-log */ case CLEAR_LOG: // --
    clear_log(up);
    next;

/*$p log{ */ case START_LOGGING: // --
    start_logging(up);
    next;

/*$p }log */ case STOP_LOGGING: // --
    stop_logging(up);
    next;

/*$p log$ */ case LOG_EXTENT: // -- adr len
    push(log_extent(--sp, up));
    next;

default:   // Non-primitives - colon defs, constants, etc.
    ascr = (u_char *)XT_FROM_CT(token, up);  // Code field address
    scr  = (cell)*(token_t *)ascr;       // Code field value
    ascr += sizeof(token_t);             // Body address
    switch (scr) {

/*$c (:) */         case DOCOLON:
    colon:
    *--rp = ip;  ip = (token_t *)ascr;  next;
/*$c (constant) */  case DOCON:
    push(nfetch((cell *)ascr));
    next;

/*$c (variable) */  case DOVAR:   /* push(ascr); */
                           push( *(unum_t *)ascr + (cell)up );
                            next;
/*$c (create) */    case DOCREATE: push(ascr); next;
/*$c (user) */      case DOUSER:  push( *(unum_t *)ascr + (cell)up );  next;
/*$c (defer) */     case DODEFER:
    token = *(token_t *) ((u_char *)up + *(unum_t *)ascr);
    goto execute;

/*$c (vocabulary) */case DOVOC:   tokstore(token, (xt_t)&V(CONTEXT));  next;
/*$c (code) */      case DOCODE:  (*(void (*) ())ascr)();  next;
/*$c (value) */     case DOVALUE:  push( *(cell *)(*(unum_t *)ascr + (cell)up) );  next;

default:    /* DOES> word */
    /* Push parameter field address */
    push(ascr);

    /* Use the code field as the address of a colon definition */
    /* Maybe we should pick it up as a token? Then */
    /* we could do ;code stuff by adding its code to the switch */
    *--rp = ip;
    ip = (token_t *)XT_FROM_CT((token_t)scr, up);
    next;
    }

    } /* End of top level switch */
  } /* End of while (1) */
}

void switch_stacks(struct stacks *old, struct stacks *new, cell *up)
{
  if (old) {
    old->sp = V(XSP);
    old->sp0 = V(SPZERO);
    old->rp = V(XRP);
    old->rp0 = V(RPZERO);
  }
  V(XSP) = new->sp;
  V(SPZERO) = new->sp0;
  V(XRP) = new->rp;
  V(RPZERO) = new->rp0;
}

void spush(cell n, cell *up)
{
    V(XSP) -= sizeof(cell);
    *(cell *)V(XSP) = n;
}

token_t ctbuf[2];
int execute_xt(xt_t xt, cell *up)
{
    ctbuf[0] = CT_FROM_XT(xt, up);
    ctbuf[1] = FINISHED;

    V(XRP) -= sizeof(token_t *);
    *(xt_t *)V(XRP) = ctbuf;

    return inner_interpreter(up);
}

int execute_xt_pop(xt_t xt, cell *up)
{
    ctbuf[0] = CT_FROM_XT(xt, up);
    ctbuf[1] = FINISHED_POP;

    V(XRP) -= sizeof(token_t *);
    *(xt_t *)V(XRP) = ctbuf;

    return inner_interpreter(up);
}

int
execute_word(char *s, cell *up)
{
    xt_t xt;

    if (alfind(s, my_strlen(s), (xt_t *)&xt, up) == 0) {
        FTHERROR("Can't find '");
        alerror(s, my_strlen(s), up);
        FTHERROR("'\n");
        return(-2);
    }

    return execute_xt(xt, up);
}

/* Forth variables */
/* Forth name   C #define       */
/*$u link       e LINK:         */
/*$u asleep     e ASLEEP:       */
/*$u #user      e NUM_USER:     */
/*$u >in        e TO_IN:        */
/*$u base       e BASE:         */
/*$u blk        e BLK:          */
/*$u #tib       e NUM_TIB:      */
/*$u 'tib       e TICK_TIB:     */
/*$u #source    e NUM_SOURCE:   */
/*$u 'source    e TICK_SOURCE:  */
/*$u state      e STATE:        */
/*$u delimiter  e DELIMITER:    */
/*$u 'sp        e XSP:          */
/*$u 'rp        e XRP:          */
/*$u 'fp        e XFP:          */  /* locals frame pointer, not floating stack pointer */
/*$u 'origin    e TORIGIN:      */
/*$u dp         e DP:           */
/*$u 'limit     e LIMIT:        */
/*$u 'ramct     e RAMCT:        */
/*$u 'ramtokens e RAMTOKENS:    */
/*$u 'compbuf   e COMPBUF:      */
/*$u 'locals    e LOCALS:       */
/*$u saved-dp   e SAVED_DP:     */
/*$u saved-limit e SAVED_LIMIT:  */
/*$u sp0        e SPZERO:       */
/*$u rp0        e RPZERO:       */
/*$u up0        e UPZERO:       */
/*$u 'rssave    e RSSAVE:       */
/*$u 'rsmark    e RSMARK:       */
/*$u #out       e NUM_OUT:      */
/*$u #line      e NUM_LINE:     */
/*$u dpl        e DPL:          */
/*$u warning    e WARNING:      */
/*$u caps       e CAPS:         */
/*$u v_errno    e ERRNO:        */
/*$u #places    e FNUMPLACES:   */
/*$u handler    e HANDLER:      */
/*$t voc-link   e VOC_LINK:     */
/*$t last       e LASTP:        */
/*$d accept     e ACCEPT:       */
/*$u thisdef    e THISDEF:      */
/*$u complevel  e COMPLEVEL:    */
/*$u #ins       e NUMINS:       */
/*$u locnum     e LOCNUM:       */
/*$u 'sysptr    e SYSPTR:       */
/*$u boundary   e BOUNDARY:     */
/*$u <ip        e LESSIP:       */
/*$u ip>        e IPGREATER:    */
/*$u cnt        e CNT:          */
/*$u 'debug     e TICK_DEBUG:   */
/*$t current    e CURRENT:      */
/*$t context    e CONTEXT:      *$UUUUUUUUUUUUUUU */ /* 15 extra voc slots */

int
find_local(char *adr, int plen, xt_t *xtp, cell *up)
{
    register int slen;
    struct local_name *locnames = (struct local_name *)V(LOCALS);

    /* The first character in the string is the Forth count field. */
    register u_char *s,*p;

    for ( V(LOCNUM) = 0; V(LOCNUM) < V(NUMINS); ) {
        s = locnames[V(LOCNUM)].name;
        p = (u_char *)adr;
        slen = *s++;
        if ( slen != plen)
            goto nextword;

        while (slen--)
            if ( *s++ != *p++ )
                goto nextword;

        *xtp = XT_FROM_CT( ((token_t *)V(TORIGIN))[DOLOCNAME], up);
        return (1);                     /* Immediate */
    nextword:
        V(LOCNUM)++;
    }
    return (0);
}

/*
 * It is tempting to try and eliminate this "hidden" variable by
 * checking to see if *threadp==threadp.  However, that doesn't
 * always work.  The first headerless definition after switching
 * to a different "current" vocabulary will break it; thus we need
 * the "hidden" variable to assert that there really is a hidden header.
 */

static void
hide(cell *up)
{
    // adr,len is not actually used, because of the definition of hash
    token_t *threadp = hash((vocabulary_t *)XT_FROM_CT(T(CURRENT), up), adr, len);

    tokstore(*(token_t *)(LAST-sizeof(token_t)), threadp);
    V(THISDEF) = (cell)threadp;
}

static void
reveal(cell *up)
{
    if (V(THISDEF)) {
        tokstore(T(LASTP), (token_t *)V(THISDEF));
        V(THISDEF) = 0;
    }
}

static void
cmove(u_char *from, u_char *to, u_cell length)
{
    while ((length--) != 0)
        *to++ = *from++;
}

static void
cmove_up(u_char *from, u_char *to, u_cell length)
{
    from += length;
    to += length;

    while ((length--) != 0)
        *--to = *--from;
}

static void
fill_bytes(u_char *to, u_cell length, u_char with)
{
    while ((length--) != 0)
        *to++ = with;
}

static int
compare(u_char *adr1, u_cell len1, u_char *adr2, u_cell len2)
{
    while (len1 && len2) {
        if (*adr1 != *adr2)
            return((*adr1 < *adr2) ? -1 : 1);
        adr1++; adr2++; len1--; len2--;
    }
    if (len1 == len2)
        return(0);
    return((len1 < len2) ? -1 : 1);
}

// If string 1 is a proper substring of string2, return the offset from
// the start of string2 where string1 begins.  If string1 is not a
// substring of string2, return -1.
static cell
strindex(u_char *adr1, cell len1, u_char *adr2, cell len2)
{
    register int n;
    register u_char *p, *q;
    register int i;

    for (n = 0; len1 >= len2; adr1++, len1--, n++) {
        p = adr2;
        q = adr1;
        i = len2;
        while(i-- > 0)
            if (*p++ != *q++)
                goto tryagain;
        // Found match
        return(n);
tryagain: ;
    }
    return(-1);
}

static size_t
my_strlen(const char *s)
{
    const char *p = s;
    while (*p) { p++; }
    return p-s;
}

/* Interface to user-supplied C subroutines */
cell
doccall(cell (*function_adr)(), u_char *format, cell *up)
{
    register cell *sp = (cell *)V(XSP);
    cell arg0, arg1, arg2, arg3, arg4,  arg5,
           arg6, arg7, arg8, arg9, arg10, arg11;
    cell ret;
    char cstr[4][128];
    int strn = 0;

/* The following cases are ordered by expected frequency of occurrence */
#define CONVERT(var) \
    switch(*format++) {\
        case 'i': var = *sp++; break;\
        case '-': goto doccall;\
        case '$': ret = *sp++; var = (cell) altocstr((char *)(*sp++), ret, cstr[strn++], 128); break;\
        case 'a': var = (cell) (*sp++); break;\
        case 'l': var = *sp++; break;\
    }

    CONVERT(arg0);
    CONVERT(arg1);
    CONVERT(arg2);
    CONVERT(arg3);
    CONVERT(arg4);
    CONVERT(arg5);
    CONVERT(arg6);
    CONVERT(arg7);
    CONVERT(arg8);
    CONVERT(arg9);
    CONVERT(arg10);
    CONVERT(arg11);
#undef CONVERT
doccall:
    V(XSP) = (cell)sp;
    /* function_adr is the address of a C subroutine */
    ret = function_adr(
        arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11);

    sp = (cell *)V(XSP);
    switch(*format) {
    case '\0': ret = *sp++; break;
    case 's': *--sp = ret;
              ret = (cell)my_strlen((char *)ret); break;
    case 'h':
      {
        int iret = ret;
        ret = (cell)iret;
        break;
      }
    case 'a': break;
        /* Default: ret is correct already */
    }
    V(XSP) = (cell)sp;
    return(ret);
}

/*
 * scanf doesn't work because it would accept numbers which don't take up
 * the whole word, as in 123xyz
 */
int
alnumber(char *adr, cell len, cell *nhigh, cell *nlow, cell *up)
{
/* XXX handle double numbers */
    int base = V(BASE);
    u_char c;
    int d;
    int isminus = 0;

    // accum is twice the cell width
    double_cell_t accum = 0;

    V(DPL) = -100;
    if ( len >= 3 && adr[0] == '\'' && adr[len-1] == '\'') {
	adr++; len -= 2;
	for ( ; len > 0; len-- ) {
	    accum = (accum << 8) | *adr++;
	}
    } else {
	if( len ) {
	    switch (*adr)
	    {
	    case '%': base = 2; len--; adr++; break;
	    case '#': base = 10; len--; adr++; break;
	    case '$': base = 16; len--; adr++; break;
	    }
	}
	if( len && *adr == '-' ) {
	    isminus = 1;
	    len--;
	    ++adr;
	}
	for( ; len > 0; len-- ) {
	    c = *adr++;
	    if( c == '.' )
		V(DPL) = 0;
	    else {
		if( -1 == (d = digit( (cell)base, c )) )
		    break;
		++V(DPL);
		accum = accum * base + d;
	    }
	}
    }
    if (V(DPL) < 0)
        V(DPL) = -1;
    if (isminus)
	accum = -accum;
    *nlow  = accum & (u_cell)-1LL;
    *nhigh = HIGH(accum) & (u_cell)-1LL;
    return( len ? 0 : -1 );
}

void udot(u_cell u, cell *up) {
    if (u>10)
        udot(u/10, up);
    emit('0'+u%10, up);
}

void udotx(u_cell u, cell *up) {
    int i;
    for (i=(sizeof(u)*8)-4; i>=0; i -= 4) {
	emit("0123456789abcdef"[(u>>i)&0xf], up);
    }
    emit(' ', up);
}

/* Carry calculation assumes 2's complement arithmetic. */
#define CARRY(res,b)  ((u_cell)res < (u_cell)b)

void
mplus(cell *dhighp, cell *dlowp, cell n)
{
    register cell lowres;

    lowres   = *dlowp + n;
    *dhighp += CARRY(lowres, n);
    *dlowp   = lowres;
}

void
umtimes(u_cell *dhighp, u_cell *dlowp, u_cell u1, u_cell u2)
{
    u_double_cell_t udscr;

    udscr = u1;
    udscr *= u2;
    *dlowp   = udscr;
    *dhighp  = HIGH(udscr);
}

void
mtimes(cell *dhighp, cell *dlowp, cell n1, cell n2)
{
    register int negative;

    negative = (n1 ^ n2) < 0;
    if (n1 < 0)
        n1 = -n1;
    if (n2 < 0)
        n2 = -n2;

    umtimes((u_cell *)dhighp, (u_cell *)dlowp, (u_cell)n1, (u_cell)n2);
    if (negative)
        *dhighp = ~*dhighp + ((*dlowp = -*dlowp) == 0); /* 2's complement */
}

void
dutimes(u_cell *dhighp, u_cell *dlowp, u_cell u)
{
    register u_cell dhigh = *dhighp, dlow = *dlowp;

    umtimes(dhighp, dlowp, dlow, u);
    *dhighp += u*dhigh;
}

// quotient in dhighp, remainder in dlowp
static void
umdivmod(u_cell *dhighp, u_cell *dlowp, u_cell u)
{
    u_double_cell_t numerator;
    numerator = TOHIGH(*dhighp) | *dlowp;
    *dhighp = (u_cell)(numerator / u);
    *dlowp = (u_cell)(numerator % u);
}

static void
mtimesdiv(cell *dhighp, cell *dlowp, cell n1, cell n2)
{
    int sign;
    u_cell thigh, tmid, tlow, temp;

    sign = *dhighp ^ n1;        /* Determine the sign of the final result */

    if ( n1 < 0 )               /* Make n1 positive */
        n1 = -n1;

    if (*dhighp < 0)            /* Make d positive */
        *dhighp = ~*dhighp + ((*dlowp = -*dlowp) == 0);         /* dnegate */

    umtimes(&tmid, &tlow, *dlowp, n1);  /* now we have tlow and partial tmid */
    umtimes(&thigh, &temp, *dhighp, n1);
    mplus((cell *)&thigh, (cell *)&tmid, temp);

    /* Now we have the absolute value of the triple intermediate result */

    *dhighp = thigh;
    *dlowp  = tmid;
    umdivmod((u_cell *)dhighp, (u_cell *)dlowp, n2);/* quot in dhighp, rem in dlowp */
    temp = tlow;
    umdivmod((u_cell *)dlowp, &temp, n2);

    /* Now we have the absolute value of the double final result */

    if (sign < 0)               /* Correct the sign of the result */
        *dhighp = ~*dhighp + ((*dlowp = -*dlowp) == 0);
}

static cell
tonumber(cell *adrp, cell len, cell *nhigh, cell *nlow, cell *up)
{
    int base = V(BASE);
    u_char c;
    register char *adr = (char *)(*adrp);
    int d;

    for( ; len > 0; adr++, len-- ) {
        c = *adr;
        if( -1 == (d = digit( (cell)base, c )) )
            break;
        dutimes((u_cell *)nhigh, (u_cell *)nlow, (u_cell)base);
        mplus(nhigh, nlow, d);
    }

    *adrp = (cell)adr;

    return(len);
}

// Converts the character c into a digit in base 'base'.
// Returns the digit or -1 if not a valid digit.
// Accepts either lower or upper case letters for bases larger than ten.
static cell
digit(cell base, u_char c)
{
    register int ival = c;

    if ('0' <= c && c <= '9')
        ival = c - '0';
    else if ('a' <= c && c <= 'z')
        ival = 10 + c - 'a';
    else if ('A' <= c && c <= 'Z')
        ival = 10 + c - 'A';
    else
        ival = -1;
    return (ival < base ? ival : -1);
}

static void
ip_canonical(char *adr, cell len, cell *up)   // Canonicalize string "in place"
{
    char *p;
    char c;

    if ( !V(CAPS) )
        return;

    for (p = adr; len--; p++) {
        c = *p;
	if (c >= 'A' && c <= 'Z') {
		*p = c - 'A' + 'a';
	}
    }
}

static int
split_string(char c, cell *sp, void *up)
{
    char *adr = (char *)sp[2];
    int len = sp[1];
    int i;
    for (i=0; i<len; i++)
	if (adr[i] == c)
	    break;
    sp[1] = i;
    sp[0] = (cell)&adr[i];
    return len-i;
}
