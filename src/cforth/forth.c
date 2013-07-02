// C Forth
// Copyright (c) 2008 FirmWorks

// prims.h and vars.h must be included externally - see the makefile

#include <stdio.h>
#include "forth.h"

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

extern void floatop(int op);
extern cell *fintop(int op, cell *sp);
extern token_t *fparenlit(token_t *ip);

extern cell (*ccalls[])();
extern cell doccall(cell (*function_adr)(), u_char *format, cell *up);

extern cell freadline(cell f, cell *sp, cell *up);

static cell strindex(u_char *adr1, cell len1, u_char *adr2, cell len2);
static void fill_bytes(u_char *to, u_cell length, u_char with);
static cell digit(cell base, u_char c);
static void ip_canonical(char *adr, cell len, cell *up);
static cell tonumber(cell *adrp, cell len, cell *nhigh, cell *nlow, cell *up);
static void type(u_char * adr, cell len, cell *up);
static void umdivmod(u_cell *dhighp, u_cell *dlowp, u_cell u);
static void umtimes(u_cell *dhighp, u_cell *dlowp, u_cell u1, u_cell u2);
static void mtimesdiv(cell *dhighp, cell *dlowp, cell n1, cell n2);
static void cmove(u_char *from, u_char *to, u_cell length);
static void cmove_up(u_char *from, u_char *to, u_cell length);
static int compare(u_char *adr1, u_cell len1, u_char *adr2, u_cell len2);
static void reveal(cell *up);
static void hide(cell *up);
static int alnumber(char *adr, cell len, cell *nhigh, cell *nlow, cell *up);

int strlen(const char *);

const token_t freelocbuf[] = { FREELOC, UNNEST};

#ifdef RELOCATE
u_cell nrelbytes, nurelbytes;
u_char *relmap, *urelmap;
u_char bit[8] = { 128, 64, 32, 16, 8, 4, 2, 1 };
#endif
const u_char nullrelmap[1] = { 0 };

#ifndef BITS32
#define LOW(a) ((a) & 0xffff)
#define HIGH(a)((a) >> 16)
#endif

/* System call error reporting */
extern int errno;

extern int system();
extern set_input();
extern void exit(int);

extern int caccept(char *addr, cell count, cell *up);
extern emit(char c, cell *up);
extern int key_avail();
extern int key();
extern cell dosyscall();
extern cell pfopen(char *name, int len, char *mode, cell *up);
extern cell pfclose(cell f, cell *up);
extern void write_dictionary(char *name, int len, char *dict, int dictsize, cell *up, int usersize);

extern void memfree(char *, cell *up);
extern char * memresize(char *, u_cell, cell *up);

// Execute an array of Forth execution tokens.
inner_interpreter(up)
    cell *up;
{
    cell *sp = (cell *)V(XSP);
    token_t **rp = (token_t **)V(XRP);
    cell tos = *sp++;
    token_t *ip = *rp++;

    token_t token;
    cell scr;
    u_char *ascr;
    u_char *ascr1;
#ifndef BITS32
    long lscr, lscr1;
#endif

    while(1) {
        token = *ip++;

doprim:

    switch (token) {
    case 0:
        ERROR("Tried to execute a null token\n");
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
        tos = -tos;
        tos = (unsigned cell) *sp++ >> (unsigned cell)tos;
    }
    else
        binop(<<);
    next;

/*$p >>a */     case SHIFTA:  binop(>>);  next;
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
    *--rp = (token_t *)tos;
    loadtos;
    next;

/*$p ip@ */     case IP_FETCH:  push((cell)(*rp++) );    next;

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

#ifdef BITS32
    --sp;
    umtimes((u_cell *)sp, (u_cell *)sp+1,
            (u_cell)*(sp+1), (u_cell)tos);
    loadtos;
#else
    lscr = ((unsigned long)(*(u_cell *)sp));
    lscr = (unsigned long)lscr * (u_cell)tos;
    *sp  = (u_cell)LOW(lscr);
    tos  = (u_cell)HIGH(lscr);
#endif
    next;

/*$p m* */      case M_TIMES:

#ifdef BITS32
    scr = 1;        /* Sign */
    if (*sp < 0) {
        *sp = -*sp;
        scr = -1;
    }
    if (tos < 0) {
        tos = -tos;
        scr = -scr;
    }
    --sp;
    umtimes((u_cell *)sp, (u_cell *)sp+1,
            (u_cell)*(sp+1), (u_cell)tos);
    loadtos;
    if (scr < 0)      /* 2's complement dnegate */
        tos = ~tos + ((*sp = -*sp) == 0);
#else
    lscr = ((long)((int)*sp));
    lscr = (long)lscr * tos;
    *sp  = (cell)LOW(lscr);
    tos  = (cell)HIGH(lscr);
#endif
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
/*$p c@ */      case C_FETCH:   tos = *(u_char *)tos;    next;
/*$p w@ */      case W_FETCH:   tos = *(unsigned short *)tos; next;
/*$p l@ */      case L_FETCH:   tos = *(unsigned long *)tos; next;

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
    *(u_short *)tos = (u_short)*sp++;
    loadtos;
    next;

/*$p l! */      case L_STORE:
    *(unsigned long *)tos = *sp++;
    loadtos;
    next;

/*$p token! */  case TOK_STORE:
    ascr = (u_char *)*sp++;
    if ( ((ascr - (u_char *)V(TORIGIN)) < V(BOUNDARY)) && (*(token_t *)ascr < MAXPRIM) ) {
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

/*$p j */       case J:
    push(((cell *)rp)[3] + ((cell *)rp)[4]);
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

/*$p key */     case KEY:        push(key()); next;
/*$p key? */    case KEY_QUESTION:    push(key_avail()); next;
/*$p emit */    case EMIT:    emit ((u_char)tos, up);    loadtos;    next;
/*$p cr */      case CR:    emit ('\n', up);    next;

/*$p type */    case TYPE: 
    type( (u_char *)(*sp++), tos, up);
    loadtos;
    next;

/*$p >body */    case TO_BODY:   tos += sizeof (token_t); next;
/*$p allot */    case ALLOT:
    V(DP) += tos;
    loadtos;
    if ((cell)V(DP) > V(LIMIT))
        ERROR( "Out of dictionary space\n");
    next;

/*$p vfind */    case VFIND:
    scr = *(u_char *)(*sp);
    tos = canon_search_wid(((char *)(*sp))+1, scr,
                           (vocabulary_t *)tos, (xt_t *)sp, up);
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

/*$p $canonical */      case CANONICAL: 
    ip_canonical ((char *)(*sp), tos, up);
    next;

/*$p sys-accept */ case SYS_ACCEPT:
    *--rp = ip;          // Save all the interpreter state in the user area
    V(XSP) = (cell)(sp+1);     /* Account for *sp++ below */
    V(XRP) = (cell)rp;
    // Since the state is in the user area, caccept doesn't have to
    // return cleanly; it can suspend the task and register a callback
    // that will re-execute inner_interpreter.
    tos = caccept ((char *)(*sp++), tos, up);
    if (tos == -1)
        return 2;
    // Restore the interpreter state
    sp = (cell *)V(XSP);
    rp = (token_t **)V(XRP);
    ip = *rp++;
    next;

/*$p accept */      case ACCEPT:    token = T(TICK_ACCEPT);    goto execute;
/*$p interpret */   case INTERPRET: token = T(TICK_INTERPRET); goto execute;

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
     * Restore the local copies of the virtual machine
     * registers to the external copies and exit to the
     * outer interpreter.
     */
     *--sp = tos;    V(XSP) = (cell)sp;    V(XRP) = (cell)rp;
     return(0);

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
    align(up);
    push(V(DP));
    compile(DOCOLON);
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

/*$p $header */     case HEADER:   header((char *)*sp++, tos, up);    loadtos;   next;

/*$p colon-cf    */ case COLONCF:    align(up); compile(DOCOLON);          next;
/*$p constant-cf */ case CONSTANTCF: align(up); compile(DOCON);            next;
/*$p nnvariable  */ case NNVARIABLE: align(up); compile(DOVAR); ncomma(0); next;
/*$p create-cf   */ case CREATECF:   align(up); compile(DOCREATE);         next;

/*$p $create */     case STR_CREATE:
    ascr = (u_char *)*sp++;
    str_create ((char *)ascr, tos, (token_t)DOCREATE, up);
    loadtos;
    next;

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
        ERROR("Conditionals not paired\n");
    if (V(COMPLEVEL)) {
        --V(COMPLEVEL);
        if (V(COMPLEVEL) == 0) {      // Dropped back to level 0
            compile(FINISHED);        // compile(EXIT);
            V(DP) = V(SAVED_DP);
            V(LIMIT) = V(SAVED_LIMIT);
            V(STATE) = INTERPRETING;
            // XXX should check stack depth
            *--rp = (xt_t)V(COMPBUF);       // Arrange to execute the compile buffer
            *--sp = tos;   V(XSP) = (cell)sp;    V(XRP) = (cell)rp;
            (void)inner_interpreter(up);
            rp = (token_t **)V(XRP);  sp = (cell *)V(XSP);  loadtos;
        }
    }
    next;

/*$p (') */     case PAREN_TICK:        push( XT_FROM_CT(*ip++, up));      next;
/*$p (char) */  case PAREN_CHAR:
    scr = nfetch((cell *)ip);
    ip   = (token_t *)((u_char *)ip + 2*sizeof(u_short));
    push(scr);
    next;

/*$p (lit) */   case PAREN_LIT:
    scr = nfetch((cell *)ip);
    ip   = (token_t *)((u_char *)ip + 2*sizeof(u_short));
    push(scr);
    next;

#ifdef T16
/*$p (lit16) */ case PAREN_LIT16:
    push( *(branch_t *)ip );
    ip   = (token_t *)((u_char *)ip + sizeof(branch_t));
    next;
#endif

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

/*$p (.") */    case P_DOT_QUOTE:
    ascr = (u_char *)ip;
    type( ascr+1, (cell)*ascr, up);
    ip = aligned( ascr + *ascr + 2);
    next;

/*$p compile */ case COMPILE: compile(*ip++);    next;

/*$p bye */     case BYE:  return(-1);
/*$p lose */    case LOSE: ERROR("Undefined word encountered\n");  goto abort;

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
#ifdef BITS32
    tos = ~tos + ((*sp = -*sp) == 0);  /* 2's complement */
#else
    lscr = ((long)((int)tos)) << 16;
    lscr = -((unsigned long)lscr + (unsigned int)(*sp));
    *sp  = (u_cell)LOW(lscr);
    tos  = (u_cell)HIGH(lscr);
#endif
    next;

/*$p d- */      case DMINUS:

#ifdef BITS32
/* Borrow calculation assumes 2's complement arithmetic */
#define BORROW(a,b)  ((u_cell)a < (u_cell)b)

#define al scr
#define bl tos
    { cell ah, bh;
        bh  = tos;      bl  = *sp++;
        ah  = *sp++;    al  = *sp;
        *sp = al - bl;  tos = ah - bh - BORROW(al, bl);
    }
#undef al
#undef bl
#undef BORROW

#else
    lscr1 = ((long)((int)tos)) << 16;
    lscr1 = (unsigned long)lscr + (unsigned int)(*sp++);
    lscr  = ((long)((int)*sp++)) << 16;
    lscr  = (unsigned long)lscr1 + (unsigned int)(*sp);
    lscr -= lscr1;
    *sp   = (u_cell)LOW(lscr);
    tos   = (u_cell)HIGH(lscr);
#endif
    next;

/*$p d+ */      case DPLUS:
#ifdef BITS32

/* Carry calculation assumes 2's complement arithmetic. */
#define CARRY(res,b)  ((u_cell)res < (u_cell)b)

#define al scr
#define bl tos
    { cell ah, bh;
        bh  = tos;      bl  = *sp++;
        ah  = *sp++;    al  = *sp;
        *sp = al += bl;  tos = ah + bh + CARRY(al, bl);
    }
#undef al
#undef bl
#undef CARRY

#else
    lscr  = ((long)((int)tos)) << 16;
    lscr  = (unsigned long)lscr + (unsigned int)(*sp++);
    lscr1 = ((long)((int)*sp++)) << 16;
    lscr1 = (unsigned long)lscr1 + (unsigned int)(*sp);
    lscr += lscr1;
    *sp   = (u_cell)LOW(lscr);
    tos   = (u_cell)HIGH(lscr);
#endif
    next;

/*$p um/mod */  case U_M_DIVIDE_MOD:
#ifdef BITS32
    (void)umdivmod((u_cell *)sp, (u_cell *)sp+1, (u_cell)tos);
    loadtos;
#else
    lscr = ((long)((int)*sp++)) << 16;
    lscr = (unsigned long)lscr + (unsigned int)(*sp);
    *sp  = (cell)((unsigned long)lscr % (u_cell)tos);
    tos  =   (cell)((unsigned long)lscr / (u_cell)tos);
#endif
    next;

/*$p sm/rem */  case S_M_DIVIDE_REM:
#ifdef BITS32
    scr = 0;        /* Sign */

    if (*sp < 0) {  /* dividend */
        *sp = ~*sp + ((sp[1] = -sp[1]) == 0);
        scr = 1;        /* dividend is negative */
    }                               
    if (tos < 0) {
        tos = -tos;
        scr += 2;       /* divisor is negative */
    }
                        
    (void)umdivmod((u_cell *)sp, (u_cell *)sp+1, (u_cell)tos);
    loadtos;

    /* Fix up signs of results */
    switch (scr) {
    case 0:  break;       /* +dividend, +divisor */
    case 1:  *sp = -*sp;  /* -dividend, +divisor : Negate remainder, fall */
    case 2:  tos = -tos;  /* +dividend, -divisor : Negate quotient */
        break;
    case 3:  *sp = -*sp;  /* -dividend, -divisor : Negate remainder*/
        break;
    }
#else
    lscr = ((long)((int)*sp++)) << 16;
    lscr = (long)lscr + (unsigned int)(*sp);
    *sp  = (cell)((long)lscr % tos);
    tos  = (cell)((long)lscr / tos);
#endif
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

/*$p interactive? */    case INTERACTIVEQ: push(isinteractive());  next;
/*$p more-input? */     case MOREINPUT:    push(moreinput());      next;
/*$p origin */          case ORIGIN:       push(V(TORIGIN));        next;
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
/*$p why */     case WHY:       perror(""); next;
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
     floatop((int)tos);  tos = pop;
     next;

/*$p fintop */  case FINTOP:
     sp = fintop((int)tos, sp);  tos = pop;
     next;

/*$p (fliteral) */      case FPAREN_LIT:
     ip = fparenlit(ip);
     next;

#endif
/*$i float? */  case FPRESENT:
#ifdef FLOATING
     push(-1);
#else
     push(0);
#endif
     next;

/*$p get-local */   case GETLOC:  tos = ((cell *)V(XFP))[tos];  next;
/*$p set-local */   case SETLOC:  ((cell *)V(XFP))[tos] = (cell)(*sp++);  tos = pop;  next;

/*$p allocate-locals */ case ALLOCLOC:
    ascr = (u_char *)rp;    /* #locals */
    rp -= tos;              /* + *sp++ */
    *--rp = (token_t *)V(XFP);
    *--rp = (token_t *)ascr;
    V(XFP) = (cell)(rp+2);
    for (scr = 0; scr < tos; scr++)
        ((cell *)V(XFP))[scr] = *sp++;
    tos = pop;
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
          (unsigned cell)(locnames[V(NUMINS)].name[0]));
    ++V(NUMINS);
    tos = pop;
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

/*$p save */        case SAVE:
    write_dictionary((char *)*sp++, tos, (char *)V(TORIGIN), V(DP)-V(TORIGIN),
                     (cell *)up, V(NUM_USER));
    loadtos;
    next;

/*$p read-line */   case READ_LINE:  /* adr len fid -- actual more? ior */
    tos = freadline(tos, sp, up);
    next;

/*$p r/o */         case R_O:  push((cell)READ_MODE);  next;
/*$p open-file */   case OPEN_FILE:
    ascr1 = (u_char *)tos;   // mode in ascr1
    loadtos;
    tos = pfopen((char *)*sp, tos, (char *)ascr1, up);
    *sp = tos;
    tos = tos ? 0 : OPENFAIL;
    next;

/*$p close-file */  case CLOSE_FILE:
    tos = pfclose(tos, up);     /* EOF on error */
    next;

/*$p to-ram */  case TO_RAM:
    V(RAMTOKENS) = pop;
    V(RAMCT) = (cell)CT_FROM_XT((xt_t)V(DP), up);
    V(DP) = V(RAMTOKENS);
    next;

default:   // Non-primitives - colon defs, constants, etc.
    ascr = (u_char *)XT_FROM_CT(token, up);  // Code field address
    scr  = (cell)*(token_t *)ascr;       // Code field value
    ascr += sizeof(token_t);             // Body address
    switch (scr) {

/*$c (:) */         case DOCOLON:  *--rp = ip;  ip = (token_t *)ascr;  next;
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

void spush(cell n, cell *up)
{
    V(XSP) -= sizeof(cell);
    *(cell *)V(XSP) = n;
}

int execute_xt(xt_t xt, cell *up)
{
    token_t ctbuf[2];

    ctbuf[0] = CT_FROM_XT(xt, up);
    ctbuf[1] = FINISHED;

    V(XRP) -= sizeof(token_t *);
    *(xt_t *)V(XRP) = ctbuf;

    return inner_interpreter(up);
}

int
execute_word(char *s, cell *up)
{
    xt_t xt;

    if (alfind(s, strlen(s), (xt_t *)&xt, up) == 0) {
        ERROR("Can't find '");
        alerror(s, strlen(s), up);
        ERROR("'\n");
        return(-2);
    }

    execute_xt(xt, up);
}

/* Forth variables */
/* Forth name   C #define       */
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
/*$u 'fp        e XFP:          */
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
/*$t 'interpret e TICK_INTERPRET: */
/*$t 'quit      e TICK_QUIT:    */
/*$t 'accept    e TICK_ACCEPT:  */
/*$u thisdef    e THISDEF:      */
/*$u complevel  e COMPLEVEL:    */
/*$u #ins       e NUMINS:       */
/*$u locnum     e LOCNUM:       */
/*$u 'sysptr    e SYSPTR:       */
/*$u boundary   e BOUNDARY:     */
/*$t current    e CURRENT:      */
/*$t context    e CONTEXT:      *$UUUUUUUUUUUUUUU */ /* 15 extra voc slots */

static void
type(u_char *adr, cell len, cell *up)
{
    while (len--)
        emit(*adr++, up);
}

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

int
strlen(const char *s)
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
    char cstr[128];

/* The following cases are ordered by expected frequency of occurrence */
#define CONVERT(var) \
    switch(*format++) {\
        case 'i': var = *sp++; break;\
        case '-': goto doccall;\
        case '$': ret = *sp++; var = (cell) altocstr((char *)(*sp++), ret, cstr, 128); break;\
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
              ret = (cell)strlen((char *)ret); break;
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
    cell accum = 0;

    V(DPL) = -100;
    if( *adr == '-' ) {
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
    if (V(DPL) < 0)
        V(DPL) = -1;
    *nlow  = isminus ? -accum : accum;
    *nhigh = isminus ? -1 : 0;
    return( len ? 0 : -1 );
}

/* Carry calculation assumes 2's complement arithmetic. */
#define CARRY(res,b)  ((u_cell)res < (u_cell)b)

void
dplus(dhighp, dlowp, shigh, slow)
    register cell *dhighp, *dlowp, shigh, slow;
{
    register cell lowres;

    lowres   = *dlowp + slow;
    *dhighp += shigh + CARRY(lowres, slow);
    *dlowp   = lowres;
}

/* Borrow calculation assumes 2's complement arithmetic */
#define BORROW(a,b)  ((u_cell)a < (u_cell)b)

void
dminus(cell *dhighp, cell *dlowp, cell shigh, cell slow)
{
    register cell lowres;

    lowres   = *dlowp - slow;
    *dhighp  = *dhighp - shigh - BORROW(*dlowp, slow);
    *dlowp   = lowres;
}

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
#ifdef BITS32
    register u_cell ah, al, bh, bl, tmp;

    ah = u1>>16;  al = u1 & 0xffff;
    bh = u2>>16;  bl = u2 & 0xffff;

    *dhighp = ah*bh;  *dlowp = al*bl;
    
    tmp = ah*bl;
    dplus((cell *)dhighp, (cell *)dlowp, (cell)(tmp>>16), (cell)(tmp<<16));

    tmp = al*bh;
    dplus((cell *)dhighp, (cell *)dlowp, (cell)(tmp>>16), (cell)(tmp<<16));
#else
    register unsigned long ulscr;

    ulscr = ((unsigned long)u1);
    ulscr = ulscr * u2;
    *dlowp   = (u_cell)LOW(ulscr);
    *dhighp  = (u_cell)HIGH(ulscr);
#endif
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
    register u_cell ulow, uhigh;
    register u_cell guess;
    u_cell errhigh, errlow;
    u_cell thigh, tlow;

    /* XXX the speed of this should be compared to a bit-banging divide loop */

    errhigh = *dhighp; errlow = *dlowp;

    if (errhigh >= u) {                 /* Overflow */
        if (u == 0)
            errhigh = 1 / u;            /* Force a divide by 0 trap */
        *dhighp = 0xffffffff;
        *dlowp  = 0;
        return;
    }

    uhigh = u >> 16; ulow = u & 0xffff;
    
    if (uhigh == 0) {
        guess = ((errhigh << 16) + (errlow >> 16)) / ulow;
        *dhighp = guess << 16;
        umtimes(&thigh, &tlow, u, guess<<16);
        dminus((cell *)&errhigh, (cell *)&errlow, (cell)thigh, (cell)tlow);
        guess = errlow / ulow;
        *dhighp += guess;
        *dlowp = (errlow - (ulow * guess));
        return;
    }

    guess = *dhighp / uhigh;
    if (guess == 0x10000)       /* This can happen! */
        guess = guess-1;
    umtimes(&thigh, &tlow, u, guess<<16);
    dminus((cell *)&errhigh, (cell *)&errlow, (cell)thigh, (cell)tlow);
    while (((cell)errhigh) < 0) {
        --guess;
        dplus((cell *)&errhigh, (cell *)&errlow, (cell)uhigh, (cell)(ulow << 16));
    }
    /* dhighp, dlowp are dead now */
    *dhighp = guess << 16;              /* High word of quotient */

    guess = ((errhigh << 16) + (errlow >> 16)) / uhigh;
    if (guess == 0x10000)       /* This can happen! */
        guess = guess-1;
    umtimes(&thigh, &tlow, u, guess);
    dminus((cell *)&errhigh, (cell *)&errlow, (cell)thigh, (cell)tlow);
    while (((cell)errhigh) < 0) {
        --guess;
/* XXX Should this be mplus ? */
/*      dplus((cell *)&errhigh, (cell *)&errlow, (cell)0, (cell)u); */
        mplus((cell *)&errhigh, (cell *)&errlow, (cell)u);

    }
    *dhighp += guess;
    *dlowp = errlow;
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
    register char *p;
    register char c;

    if ( !V(CAPS) )
        return;

    for (p = adr; len--; p++) {
        c = *p;
        *p++ = (c >= 'A' && c <= 'Z') ? (c - 'A' + 'a') : c;
    }
}
