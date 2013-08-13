// C Forth 93
// Copyright (c) 1992 by Bradley Forthware

// prims.h and vars.h must be included externally - see the makefile

#include "forth.h"

#define DOEXECUTE break

#ifdef JAVA

#  define NEXT      continue walk
#  define DOTHROW   break dispatch

#else

#  define NEXT      goto walk
#  define DOTHROW   goto throw

#endif


#define LOADTOS          tos = DS(sp++)
#define PUSH(whatever)   DS(--sp) = tos; tos = (int)(whatever)
#define POP              tos; LOADTOS
#define DOCOMMA          ncomma(tos);   LOADTOS

#include "prototypes.h"

#ifdef INCLUDE_LOCALS
const token_t freelocbuf[] = { FREELOC, UNNEST};
#endif

// Execute an array of Forth execution tokens.
SCOPE1 int inner_interpreter(int up)
{
    int sp = V(XSP);
    int rp = V(XRP);
    int tos = DS(sp++);
    int ip = RS(rp++);

    int token;
    int scr;
    int ascr;
    int ascr1;

  walk: while(true) {

   token = TOKEN(ip++);

  dispatch: while(true) {
    switch (token) {
    case 0:
        ERROR("Tried to execute a null token\n");
        /*                where(); */
        /*                udot((cell)ip); */
        // Fall through

/*$p abort */   case ABORT:   PUSH(-1); DOTHROW;

/*$p throw */   case THROW:
                 if (tos == 0) {  LOADTOS; NEXT;  }
                 DOTHROW;

/*$p invert */  case INVERT:     tos = ~tos;     NEXT;
/*$p and */     case AND:        tos = DS(sp++) & tos;    NEXT;
/*$p or */      case OR:         tos = DS(sp++) | tos;    NEXT;
/*$p xor */     case XOR:        tos = DS(sp++) ^ tos;    NEXT;
/*$p + */       case PLUS:       tos = DS(sp++) + tos;    NEXT;
/*$p - */       case MINUS:      tos = DS(sp++) - tos;    NEXT;
/*$p * */       case TIMES:      tos = DS(sp++) * tos;    NEXT;

/*$p shift */   case SHIFT:
    if ( tos < 0 ) {
        tos = -tos;
#ifdef JAVA
        tos = DS(sp++) >>> tos;
#else
        tos = DS(sp++) >> tos;
#endif
    }
    else
        tos = DS(sp++) << tos;
    NEXT;

/*$p >>a */     case SHIFTA:  tos = DS(sp++) >> tos;  NEXT;
/*$p dup */     case DUP:     DS(--sp) = tos;  NEXT;
/*$p drop */    case DROP:    LOADTOS;  NEXT;
/*$p swap */    case SWAP:    scr = DS(sp);  DS(sp) = tos;  tos = scr;  NEXT;
/*$p over */    case OVER:    PUSH(DS(sp+1));  NEXT;
/*$p nip */     case NIP:     ++sp;  NEXT;
/*$p tuck */    case TUCK:    scr = DS(sp+0);  DS(--sp) = scr;  DS(sp+1) = tos;  NEXT;
/*$p rot */     case ROT:
    scr = tos;  tos = DS(sp+1);  DS(sp+1) = DS(sp+0);  DS(sp+0) = scr;
    NEXT;
/*$p -rot */    case MINUS_ROT:
    scr = tos;  tos = DS(sp+0);  DS(sp+0) = DS(sp+1);  DS(sp+1) = scr;
    NEXT;

/*$p pick */    case PICK:      tos = DS(sp+tos); NEXT;
/*$p roll */    case ROLL:      
    for (scr = DS(sp+tos); tos != 0; --tos)
        DS(sp+tos) = DS(sp+tos-1);
    tos = scr;
    ++sp;
    NEXT;

/*$p ?dup */    case QUES_DUP:  if (tos != 0) { DS(--sp) = tos; }    NEXT;
/*$p >r */      case TO_R:      RS(--rp) = POP;        NEXT;
/*$p r> */      case R_FROM:    PUSH( RS(rp++) );      NEXT;
/*$p r@ */      case R_FETCH:   PUSH( RS(rp) );        NEXT;
/*$p 2>r */     case TWOTO_R:
    RS(--rp) = DS(sp++);
    RS(--rp) = POP;
    NEXT;

/*$p 2r> */     case TWOR_FROM:
    DS(--sp) = tos;
    tos = RS(rp++);
    DS(--sp) = RS(rp++);
    NEXT;

/*$p 2r@ */     case TWOR_FETCH:
    DS(--sp) = tos;
    DS(--sp) = RS(rp+1);
    tos = RS(rp);
    NEXT;

/*$p ip! */     case IP_STORE:
    RS(--rp) = tos;
    LOADTOS;
    NEXT;

/*$p ip@ */     case IP_FETCH:  PUSH( RS(rp++) );    NEXT;

    /* We don't have to account for the tos in a register, because */
    /* push has already pushed tos onto the stack before */
    /* V(SPZERO) - sp  is computed */

/*$p depth */   case DEPTH:             PUSH(V(SPZERO) - sp) ; NEXT;
/*$p < */       case LESS:              tos = ((DS(sp++) < tos)?-1:0);  NEXT;
/*$p = */       case EQUAL:             tos = ((DS(sp++) == tos)?-1:0); NEXT;
/*$p > */       case GREATER:           tos = ((DS(sp++) > tos)?-1:0); NEXT;
/*$p 0< */      case ZERO_LESS:         tos = ((tos < 0)?-1:0);      NEXT;
/*$p 0= */      case ZERO_EQUAL:        tos = ((tos == 0)?-1:0);     NEXT;
/*$p 0> */      case ZERO_GREATER:      tos = ((tos > 0)?-1:0);      NEXT;
/*$p u< */      case U_LESS: 
#ifdef JAVA
                    scr = DS(sp++);
                    // JAVA doesn't have unsigned comparisons
                    if (scr < 0  &&  tos >= 0)
                        tos = 0;
                    else if (tos < 0  &&  scr >= 0)
                        tos = -1;
                    else
                        tos = (scr < tos) ? -1 : 0;
#else
    tos = ((cell) DS(sp++) < (u_cell) tos) ? -1 : 0;
#endif
    NEXT;

/*$p 1+ */      case ONE_PLUS:     tos++;            NEXT;
/*$p 2+ */      case TWO_PLUS:     tos += 2;     NEXT;
/*$p 2- */      case TWO_MINUS:    tos -= 2;     NEXT;

#ifdef JAVA
#define UTOLONG(low)   (((long)low << 32) >>> 32)
#define TOLONG(low, high) (((long)(high) << 32) + UTOLONG(low))
#define SETLONG(l, low, high)   low = (int)l; high = (int)(l >>> 32)
#define PUTLONG(l)   SETLONG(l, DS(sp), tos)
#else
#define UTOLONG(low)   ((unsigned long long)(unsigned)low)
#define TOLONG(low, high) (((unsigned long long)((unsigned)high) << 32) + UTOLONG(low))
#define SETLONG(l, low, high)   low = (int)l; high = (int)(l >> 32)
#endif

/*$p um* */     case U_M_TIMES:   
#ifdef JAVA
                {
                    long l;
                    l = UTOLONG(DS(sp)) * UTOLONG(tos);
                    PUTLONG(l);
                }
#else
    --sp;
    umtimes((u_cell *)&DS(sp), (u_cell *)&DS(sp+1),
            (u_cell)DS(sp+1), (u_cell)tos);
    LOADTOS;
#endif
    NEXT;

/*$p m* */      case M_TIMES:
#ifdef JAVA
                {
                    long l;
                    l = (long)(DS(sp)) * (long)tos;
                    PUTLONG(l);
                }
#else

    scr = 1;        /* Sign */
    if (DS(sp) < 0) {
        DS(sp) = -DS(sp);
        scr = -1;
    }
    if (tos < 0) {
        tos = -tos;
        scr = -scr;
    }
    --sp;
    umtimes((u_cell *)&DS(sp), (u_cell *)&DS(sp+1),
            (u_cell)DS(sp+1), (u_cell)tos);
    LOADTOS;
    if (scr < 0)      /* 2's complement dnegate */
        tos = ~tos + ((DS(sp) = -DS(sp)) == 0);
#endif
    NEXT;

/*$p m%/ */     case M_TIMDIV:
#ifdef JAVA
                {
                    // XXX this isn't quite right - it is supposed to have
                    // a triple-precision intermediate result.
                    long l;
                    l = TOLONG(DS(sp+2), DS(sp+1));
                    l = (l * UTOLONG(DS(sp))) / tos;
                    sp += 2;
                    l /= tos;
                    PUTLONG(l);
                }
#else
    scr = DS(sp++);
    mtimesdiv(&DS(sp), &DS(sp+1), scr, tos);
    LOADTOS;
#endif
    NEXT;

/*$p 2/ */      case TWO_DIVIDE:   tos >>= 1;  NEXT;
/*$p max */     case PMAX:  scr = DS(sp++); if (tos < scr) { tos = scr; }  NEXT;
/*$p min */     case PMIN:  scr = DS(sp++); if (tos > scr) { tos = scr; }  NEXT;
/*$p abs */     case ABS:    if (tos < 0)   { tos = -tos; }   NEXT;
/*$p negate */  case NEGATE:    tos = -tos;  NEXT;
/*$p @ */       case FETCH:     tos = nfetch(tos); NEXT;
/*$p c@ */      case C_FETCH:   tos = CHARS(tos);  NEXT;
/*$p w@ */      case W_FETCH:   tos = DATA(tos);   NEXT;
/*$p l@ */      case L_FETCH:   tos = DATA(tos);   NEXT;

/*$p token@ */  case TOK_FETCH:
    token = TOKEN(tos);
    if (token < MAXPRIM) {
        token = TOKEN(token);
    }
    tos = token;
    NEXT;

/*$p ! */       case STORE:
    nstore(tos, DS(sp++));
    LOADTOS;
    NEXT;

/*$p c! */      case C_STORE:
    CHARS(tos) = (char)DS(sp++);
    LOADTOS;
    NEXT;

/*$p w! */      case W_STORE:
    DATA(tos) = DS(sp++);
    LOADTOS;
    NEXT;

/*$p l! */      case L_STORE:
    DATA(tos) = DS(sp++);
    LOADTOS;
    NEXT;

/*$p token! */  case TOK_STORE:
    ascr = DS(sp++);
    if ( ascr < V(BOUNDARY) && TOKEN(ascr) < MAXPRIM ) {
        TOKEN(tos) = TOKEN(ascr);
    } else {
        TOKEN(tos) = ascr;
    }
    LOADTOS;
    NEXT;

/*$p branch! */  case BRANCH_STORE:
    TOKEN(tos) = DS(sp++);
    LOADTOS;
    NEXT;

/*$p branch@ */  case BRANCH_FETCH:
    tos = TOKEN(tos);
    NEXT;

/*$p +! */      case PLUS_STORE:
    nstore(tos, nfetch(tos) + DS(sp++));
    LOADTOS;
    NEXT;

/*$p cmove */    case CMOVE:
    ascr  = DS(sp++);
    ascr1 = DS(sp++);
    cmove(ascr1, ascr, tos);
    LOADTOS;
    NEXT;

/*$p cmove> */  case CMOVE_UP:
    ascr  = DS(sp++);
    ascr1 = DS(sp++);
    cmove_up(ascr1, ascr, tos);
    LOADTOS;
    NEXT;

/*$p fill */    case FILL: 
    scr  = DS(sp++);
    ascr = DS(sp++);
    fill_bytes(ascr, scr, tos);
    LOADTOS;
    NEXT;

/*$p compare */ case COMPARE:
    ascr  = DS(sp++);
    scr   = DS(sp++);
    ascr1 = DS(sp++);
    tos = compare(ascr1, scr, ascr, tos);
    NEXT;

/*$p count */   case COUNT: 
    DS(--sp) = tos + 1;
    tos = CHARS(tos);
    NEXT;

/*$p -trailing */ case DASH_TRAILING: 
    ascr  = DS(sp) + tos;
    tos++;
    while ((--tos != 0) && (CHARS(--ascr) == ' '));
    NEXT;

/*$p cell+ */   case CELL_PLUS: tos++; NEXT;

/*$p i */       case I:   PUSH(RS(rp) + RS(rp+1));  NEXT;
/*$p j */       case J:   PUSH(DATA(rp+3) + RS(rp+4));  NEXT;

/*$p branch */  case PBRANCH:  ip += TOKEN(ip);  NEXT;

/*$p ?branch */ case QUES_BRANCH:
    if (tos == 0) {
        ip += TOKEN(ip);
    } else {
        ip++;
    }
    LOADTOS;
    NEXT;

/*$p unnest */  case UNNEST:
/*$p exit */    case XEXIT:    ip = RS(rp++);  NEXT;
/*$p execute */ case EXECUTE:
    ascr = POP;
    token = ascr;
    DOEXECUTE;

/*$p key */     case KEY:        PUSH(key()); NEXT;
/*$p key? */    case KEY_QUESTION:    PUSH(key_avail()); NEXT;
/*$p emit */    case EMIT:    emit (tos, up);    LOADTOS;    NEXT;
/*$p cr */      case CR:    emit ('\n', up);    NEXT;

/*$p type */    case TYPE:  type( TOKEN(sp++), tos, up);  LOADTOS;  NEXT;

/*$p >body */    case TO_BODY:   tos++; NEXT;
/*$p allot */    case ALLOT:
    V(DP) += tos;
    LOADTOS;
    if (V(DP) > V(LIMIT))
        ERROR( "Out of dictionary space\n");
    NEXT;

/*$p $find */    case ALFIND:
    scr = alfind(DS(sp), tos, up);
    if (scr != 0) {
        DS(sp) = scr;
        tos = isimmediate(scr);
    } else {
        PUSH(scr);
    }
    NEXT;

/*$p search-wordlist */    case SEARCH_WORDLIST:  // ( adr len wid -- [ xt ] flag )
    scr = DS(sp++);  // scr:len  tos:wid
    tos = canon_search_wid(DS(sp++), scr, tos, up);  // tos: xt or 0
    if (tos != 0) {
        DS(--sp) = tos;
        tos = isimmediate(tos);
    }
    NEXT;

/*$p $canonical */      case CANONICAL: 
    ip_canonical (DS(sp), tos, up);
    NEXT;

/*$p sys-accept */ case SYS_ACCEPT:
    RS(--rp) = ip;          // Save all the interpreter state in the user area
    V(XSP) = sp+1;     /* Account for DS(sp++) below */
    V(XRP) = rp;
    // Since the state is in the user area, caccept doesn't have to
    // return cleanly; it can suspend the task and register a callback
    // that will re-execute inner_interpreter.
    tos = caccept (DS(sp++), tos, up);
    if (tos == -1)
        return 2;
    // Restore the interpreter state
    sp = V(XSP);
    rp = V(XRP);
    ip = RS(rp++);
    NEXT;

/*$p accept */      case ACCEPT:    token = T(TICK_ACCEPT);    DOEXECUTE;
/*$p interpret */   case INTERPRET: token = T(TICK_INTERPRET); DOEXECUTE;

/*$p finished */ case FINISHED:
     // Restore the local copies of the virtual machine
     // registers to the external copies and exit to the
     // outer interpreter.
     DS(--sp) = tos;    V(XSP) = (cell)sp;    V(XRP) = (cell)rp;
     return(0);

/*$p 0 */       case ZERO:      PUSH(0);                 NEXT;
/*$p here */    case HERE:      PUSH(V(DP));             NEXT;
/*$p tib */     case TIB:       PUSH(V(TICK_TIB));       NEXT;
/*$p /tib */    case SLASH_TIB: PUSH(TIBSIZE);           NEXT;
/*$p parse */   case PARSE:     tos = parse(tos, --sp, up);  NEXT;
/*$p parse-word */ case PARSE_WORD:
    DS(--sp) = tos;
    tos = parse_word(--sp, up);
    NEXT;

/*$p , */       case COMMA:    
 DOCOMMA;  NEXT;

/*$i ; */       case SEMICOLON:    
    compile(UNNEST);
    reveal(up);
    V(STATE) = 0;
    NEXT;

/*$p :noname */ case COLON_NONAME:
    PUSH(V(DP));
    compile(DOCOLON);
    V(STATE) = -1;
    V(NUMINS) = 0;
    NEXT;

/*$p : */       case COLON:
    create_word (DOCOLON, up);
    hide(up);
    V(STATE) = -1;
    V(NUMINS) = 0;
    NEXT;

/*$p constant */    case CONSTANT: create_word (DOCON, up);   DOCOMMA;   NEXT;
/*$p user */        case USER:     create_word (DOUSER, up);  DOCOMMA;   NEXT;
/*$p variable */    case VARIABLE: create_word (DOVAR, up);
                        ncomma(V(NUM_USER)); V(NUM_USER)++;
                        NEXT;
/*$p create */      case CREATE:   create_word (DOCREATE, up);  NEXT;

/*$p $header */     case HEADER:   header(DS(sp++), tos, up); LOADTOS;  NEXT;

/*$p colon-cf    */ case COLONCF:    compile(DOCOLON);    NEXT;
/*$p constant-cf */ case CONSTANTCF: compile(DOCON);      NEXT;
/*$p nnvariable  */ case NNVARIABLE: compile(DOVAR); ncomma(0); NEXT;
/*$p create-cf   */ case CREATECF:   compile(DOCREATE);   NEXT;

/*$p $create */     case STR_CREATE:
    ascr = DS(sp++);
  alerror(ascr, tos, up);
  ERROR(" --\n");

    str_create (ascr, tos, DOCREATE, up);
    LOADTOS;
    NEXT;

/*$p user-size */   case USER_SIZE:   PUSH(MAXUSER);     NEXT;
/*$p immediate */   case IMMEDIATE:   makeimmediate(up);  NEXT;

/*$p +level */      case PLUS_LEVEL:
    if (V(COMPLEVEL) != 0)
        ++V(COMPLEVEL);
    else if (V(STATE) == 0) {
        V(COMPLEVEL) = 1;
        V(SAVED_DP) = V(DP);
        V(SAVED_LIMIT) = V(LIMIT);
        V(DP) = V(COMPBUF);
        V(LIMIT) = V(COMPBUF) + CBUFSIZE;
        V(STATE) = -1;
        /* XXX should save stack depth */
    }
    NEXT;

/*$p -level */      case MINUS_LEVEL:
    if (V(STATE) == 0)
        ERROR("Conditionals not paired\n");
    if (V(COMPLEVEL) != 0) {
        --V(COMPLEVEL);
        if (V(COMPLEVEL) == 0) {      // Dropped back to level 0
            compile(FINISHED);        // compile(EXIT);
            V(DP) = V(SAVED_DP);
            V(LIMIT) = V(SAVED_LIMIT);
            V(STATE) = 0;
            // XXX should check stack depth
            RS(--rp) = V(COMPBUF);   // Arrange to execute the compile buffer
            DS(--sp) = tos;   V(XSP) = (cell)sp;    V(XRP) = (cell)rp;
            scr = inner_interpreter(up);
            rp = V(XRP);  sp = V(XSP);  LOADTOS;
        }
    }
    NEXT;

/*$p (') */     case PAREN_TICK:  PUSH(TOKEN(ip++));  NEXT;
/*$p (char) */  case PAREN_CHAR:
    scr = nfetch(ip++);
    PUSH(scr);
    NEXT;

/*$p (lit) */   case PAREN_LIT:
    scr = nfetch(ip++);
    PUSH(scr);
    NEXT;

/*$p (lit16) */   case PAREN_LIT16:
    scr = nfetch(ip++);
    PUSH(scr);
    NEXT;

/*$p xtliteral */ case XTLITERAL:
    compile(PAREN_TICK);
    compile(tos);
    LOADTOS;
    NEXT;

/*$p compile, */case COMPILE_COMMA:
    if ( tos < V(BOUNDARY)  &&  TOKEN(tos) < MAXPRIM )  {
        compile(TOKEN(tos));
    } else {
        compile (tos);
    }
    LOADTOS;
    NEXT;

/*$p dup. */    case DUPDOT:
#ifdef DEBUG
    printf("%x\n", tos);
#endif
    NEXT;
/* XXX need UNLOOP */

/*$p ?leave */  case QUES_LEAVE:
    scr = POP;
    if (scr == 0) { NEXT; }
    /* else fall through */

/*$p leave */   case LEAVE:
    rp += 2;         // Discard the loop indices
    ip = RS(rp++); // Go to location after (do
    ip += TOKEN(ip);          // Get the offset there
    NEXT;

/*$p (?do) */   case PAREN_QUESTION_DO:
    scr = DS(sp++);
    if ( scr == tos ) { LOADTOS; ip += TOKEN(ip); NEXT; }

    RS(--rp) = ip;                  // Addr of offset to end
    ip = ip + 1;
    RS(--rp) = scr ;        // limit value
    RS(--rp) = tos - scr ;  // Distance up to 0
    LOADTOS;
    NEXT;

/*$p (do) */    case P_DO: 
    scr = DS(sp++);

    RS(--rp) = ip;          // Addr of offset to end
    ip = ip + 1;
    RS(--rp) = scr ;        // limit value
    RS(--rp) = tos - scr ;  // Distance up to 0
    LOADTOS;
    NEXT;

/*$p (loop) */  case PAREN_LOOP: 
    if (++RS(rp) != 0) {
        ip += TOKEN(ip);
        NEXT;
    }
    // Loop termination: clean up return stack and skip branch offset
    rp += 3;
    ++ip;
    NEXT;

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

    scr = RS(rp);
    if ((((RS(rp) = scr+tos)^tos) < 0)
        || ((scr^tos) >= 0)) {
        LOADTOS; ip += TOKEN(ip); NEXT;
    }
    // Loop termination: clean up return stack and skip branch offset
    LOADTOS;
    rp += 3;
    ++ip;
    NEXT;

/*$p (does) */  case P_DOES:
    tokstore(ip, LAST);
    ip = RS(rp++);
    NEXT;

/*$p (.") */    case P_DOT_QUOTE:
    type( ip+1, CHARS(ip), up);
    ip += CHARS(ip) + 2;  // Change to 1 if we remove the extra null
    NEXT;

/*$p compile */ case COMPILE: compile(TOKEN(ip++));    NEXT;

/*$p bye */     case BYE:  return(-1);
/*$p lose */    case LOSE:
                     ERROR("Undefined word encountered\n");
                     PUSH(-1);
                     DOTHROW;

    // There's no need to modify sp to account for the top of stack
    // being in a register because push has already put tos on the
    // stack before the argument ( sp ) is evaluated

/*$p sp@ */     case SPFETCH:   PUSH(sp); NEXT;
/*$p sp! */     case SPSTORE:   sp = tos + 1;  NEXT;

/*$p rp@ */     case RPFETCH:   PUSH(rp); NEXT;
/*$p rp! */     case RPSTORE:   rp = tos;  LOADTOS;  NEXT;

/*$p up@ */     case UPFETCH:   PUSH(up); NEXT;
/*$p up! */     case UPSTORE:   up = tos;  LOADTOS;  NEXT;

#define FLOORFIX(dividend, divisor, remainder)  \
        ((dividend < 0) ^ (divisor < 0))  &&  (remainder != 0)
/*$p / */       case DIVIDE:
    {
    cell quot, rem;

    scr = DS(sp++);
    quot = scr/tos;
    rem  = scr - tos*quot;
    if (FLOORFIX(tos,scr,rem))
        tos = quot - 1;
    else
        tos = quot;
    }
    NEXT;

/*$p mod */     case MOD:
    {
    cell rem;

    scr = DS(sp++);  rem = scr%tos;
    if (FLOORFIX(tos,scr,rem))
        tos = tos + rem;
    else
        tos = rem;
    }
    NEXT;

/*$p x%/mod */  case TIM_DIV_MOD:
    {
        cell dividend;
        cell quot, rem;
        dividend = DS(sp++);
        dividend *= DS(sp++);
        quot = dividend/tos;
        rem  = dividend - tos*quot;
        if (FLOORFIX(dividend,tos,rem)) {
            DS(--sp) = rem + tos; 
            tos = quot - 1;
        } else {
            DS(--sp) = rem ;
            tos = quot;
        }
    }
    NEXT;

/*$p /mod */    case DIVIDE_MOD:
    scr = DS(sp); DS(sp) = scr%tos;
    if (((scr < 0) ^ (tos < 0))  &&  DS(sp) != 0) {
        DS(sp) += tos;
        tos = (scr/tos) - 1;
        NEXT;
    }
    tos = scr/tos;
    NEXT;

/*$p dnegate */ case DNEGATE:
    tos = ~tos + ((DS(sp) = -DS(sp)) == 0 ? 0 : 1);  /* 2's complement */

    NEXT;

/*$p d- */      case DMINUS:



#ifdef JAVA
                {
                    long l;
                    l = -TOLONG(DS(sp), tos);
                    PUTLONG(l);
                }
#else
/* Borrow calculation assumes 2's complement arithmetic */
#define BORROW(a,b)  ((u_cell)a < (u_cell)b)

#define al scr
#define bl tos
    { cell ah, bh;
        bh  = tos;      bl  = DS(sp++);
        ah  = DS(sp++);    al  = DS(sp);
        DS(sp) = al - bl;  tos = ah - bh - BORROW(al, bl);
    }
#undef al
#undef bl
#undef BORROW
#endif
    NEXT;

/*$p d+ */      case DPLUS:

#ifdef JAVA
                {
                    long l;
                    l = TOLONG(DS(sp+2), DS(sp+1)) + TOLONG(DS(sp), tos);
                    sp += 2;
                    PUTLONG(l);
                }
#else
/* Carry calculation assumes 2's complement arithmetic. */
#  define CARRY(res,b)  ((u_cell)res < (u_cell)b)

#  define al scr
#  define bl tos
    { cell ah, bh;
        bh  = tos;      bl  = DS(sp++);
        ah  = DS(sp++);    al  = DS(sp);
        DS(sp) = al += bl;  tos = ah + bh + CARRY(al, bl);
    }
#  undef al
#  undef bl
#  undef CARRY
#endif
    NEXT;

/*$p um/mod */  case U_M_DIVIDE_MOD:
#ifdef JAVA
                {
                    // this is really sm/rem but oh well
                    long l;
                    l = TOLONG(DS(sp+1), DS(sp));
                    sp++;
                    DS(sp) = (int)(l % tos);
                    tos = (int)(l / tos);
                }
#else
    (void)umdivmod((u_cell *)&DS(sp), (u_cell *)&DS(sp+1), (u_cell)tos);
    LOADTOS;
#endif
    NEXT;

/*$p sm/rem */  case S_M_DIVIDE_REM:
#ifdef JAVA
                {
                    long l;
                    l = TOLONG(DS(sp+1), DS(sp));
                    sp++;
                    DS(sp) = (int)(l % tos);
                    tos = (int)(l / tos);
                }
#else
    scr = 0;        /* Sign */

    if (DS(sp) < 0) {  /* dividend */
        DS(sp) = ~DS(sp) + ((DS(sp+1) = -DS(sp+1)) == 0);
        scr = 1;        /* dividend is negative */
    }                               
    if (tos < 0) {
        tos = -tos;
        scr += 2;       /* divisor is negative */
    }
                        
    (void)umdivmod((u_cell *)&DS(sp), (u_cell *)&DS(sp+1), (u_cell)tos);
    LOADTOS;

    /* Fix up signs of results */
    switch (scr) {
    case 0:  break;       /* +dividend, +divisor */
    case 1:  DS(sp) = -DS(sp);  /* -dividend, +divisor : Negate remainder, fall */
    case 2:  tos = -tos;  /* +dividend, -divisor : Negate quotient */
        break;
    case 3:  DS(sp) = -DS(sp);  /* -dividend, -divisor : Negate remainder*/
        break;
    }
#endif
    NEXT;

/*$p digit */   case DIGIT:
    if ( (scr = digit(tos, DS(sp))) >= 0 ) {
        DS(sp) = scr; tos = -1;
    } else
        tos = 0;
    NEXT;

/*$p $number? */        case ALNUM_QUESTION:  // ( adr len -- false | d true )
    ascr = DS(sp--);
    tos = alnumber(ascr, tos, sp, sp+1, up);
    if ( tos == 0 )
        sp += 2;
    NEXT;

/*$p >number */ case TO_NUMBER: tos = tonumber( sp, tos, sp+1, sp+2, up);  NEXT;
/*$p hide */    case HIDE:      hide(up);    NEXT;
/*$p reveal */  case REVEAL:    reveal(up);  NEXT;

/*$p interactive? */    case INTERACTIVEQ: PUSH(isinteractive());  NEXT;
/*$p more-input? */     case MOREINPUT:    PUSH(moreinput());      NEXT;
/*$p origin */          case ORIGIN:       PUSH(0);                NEXT;
/*$p unused */          case UNUSED:       PUSH(V(LIMIT)-V(DP));   NEXT;
/*$p /token */          case SLASH_TOKEN:  PUSH(1);                NEXT;
/*$p /branch */         case SLASH_BRANCH: PUSH(1);                NEXT;
/*$p maxprimitive */    case MAXPRIMITIVE: PUSH(MAXPRIM);          NEXT;

/*$p cells */   case CELLS:  tos *= 1;  NEXT;

#if 0
/*$p ccall */   case CCALL:
//    scr = POP; V(XSP) = (cell)sp; V(XRP) = (cell)rp;
//    tos = doccall ((cell (*)())ccalls[scr], (String)tos, up);
//    rp = (token_t **)V(XRP); sp = (cell *)V(XSP);
//    NEXT;
    tos = ccalls[tos];
    // Fall through

/*$p acall */   case ACALL:
    scr = POP; V(XSP) = sp; V(XRP) = rp;
    tos = doccall (scr, tos, up);
    rp = V(XRP); sp = V(XSP);
    NEXT;
#endif

#ifndef NOSYSCALL
/*$p syscall */ case SYSCALL:
    scr = POP; ascr1 = sp;
XXX how to return more values?
    tos = dosyscall(scr, tos, (cell **)&ascr1);
    sp = ascr1;
    NEXT;

/*$p $command */case COMMAND:
    PUSH(alsystem(DS(sp++), tos));
    NEXT;

/*$p $chdir */  case CHDIR:
    PUSH(alchdir(DS(sp++), tos));
    V(ERRNO) = (tos < 0) ? errno : 0;
    NEXT;

/*$p errno */   case PERRNO:    PUSH(V(ERRNO)); NEXT;  /* Self fetching */
/*$p why */     case WHY:       perror("", up); NEXT;
#endif

/*$p bl */      case BL:        PUSH(' ');  NEXT;
/*$p search */  case SEARCH:
    /* adr1 len1 adr2 len2 -- adr1' len1' flag */
    /* len2 in tos */
    ascr  = DS(sp++);         // adr2 in ascr
    scr = DS(sp);             // len1 in scr
    ascr1 = DS(sp+1);         // adr1 in ascr1
    tos = strindex(ascr1, scr, ascr, tos);
    if (tos == -1)              // Match not found
        tos = 0;                // Return FALSE
    else {                      // tos is offset to match
        DS(sp+1) += tos;      // advance address
        DS(sp+0) -= tos;      // decrement count
        tos = -1;               // Return TRUE
    }
    NEXT;

/*$p allocate */case ALLOCATE:
    if ((V(LIMIT) - (tos + 1)) < V(DP)) {
        DS(--sp) = 0;
        tos = -10;
    } else {
        V(LIMIT) -= (tos + 1);
        DATA(V(LIMIT)) = tos;
        DS(--sp) = V(LIMIT) + 1;
        tos = 0;
    }
    NEXT;

/*$p free */    case MFREE:
    if (tos != (V(LIMIT) + 1)) {
        ERROR("Unbalanced 'free'\n");
        PUSH(-1);
        DOTHROW;
    }
    V(LIMIT) += DATA(tos);
    tos = 0;
    NEXT;

#if 0
/*$p resize */  case RESIZE:
    tos = memresize(DS(sp), tos, up);
    DS(sp) = tos;
    tos = tos ? 0 : -13;      /* Error code */
    NEXT;
#endif

/*$p >relbit */ case TORELBIT:
     // return a "safe" address and a 0 bitmask.
     tos = 0;
     PUSH(0);
     NEXT;

#ifdef FLOATING
/*$p floatop */ case FLOATOP:
     floatop(tos);  tos = POP;
     NEXT;

/*$p fintop */  case FINTOP:
     sp = fintop(tos, sp);  tos = POP;
     NEXT;

/*$p (fliteral) */      case FPAREN_LIT:
     ip = fparenlit(ip);
     NEXT;

#endif
/*$i float? */  case FPRESENT:
#ifdef FLOATING
     PUSH(-1);
#else
     PUSH(0);
#endif
     NEXT;

#ifdef INCLUDE_LOCALS
/*$p get-local */   case GETLOC:  tos = DATA(V(XFP)+tos);  NEXT;
/*$p set-local */   case SETLOC:  DATA(V(XFP)+tos) = DS(sp++);  tos = POP;  NEXT;

/*$p allocate-locals */ case ALLOCLOC:
    ascr = rp;              /* #locals */
    rp -= tos;              /* + DS(sp++) */
    RS(--rp) = V(XFP);
    RS(--rp) = ascr;
    V(XFP) = rp+2;
    for (scr = 0; scr < tos; scr++)
        DATA(V(XFP)+scr) = DS(sp++);
    tos = POP;
    RS(--rp) = V(FREELOCBUF);  // Cast prevent "const" warning
    NEXT;

/*$p free-locals */ case FREELOC:
    V(XFP) = DATA(V(XFP)-1);
    rp = RS(rp);
    NEXT;

/*$p local-name */  case LOCNAME:        /* name-str data code -- */
    {
    struct local_name *locnames = (struct local_name *)V(LOCALS);
    locnames[V(NUMINS)].code = tos;
    locnames[V(NUMINS)].l_data = DS(sp++);
    locnames[V(NUMINS)].name[0] = (char)DS(sp++);
    cmove((String)(DS(sp++)),
          &locnames[V(NUMINS)].name[1],
          (unsigned cell)(locnames[V(NUMINS)].name[0]));
    ++V(NUMINS);
    tos = POP;
    }
    NEXT;

/*$p do-local-name */ case DOLOCNAME:
    {
    struct local_name *locnames = (struct local_name *)V(LOCALS);
    PUSH(locnames[V(LOCNUM)].l_data);
    token = locnames[V(LOCNUM)].code;
    }
    DOEXECUTE;
#endif

// File operations

/*$p save */        case SAVE:
    write_dictionary(DS(sp++), tos, V(DP), up, V(NUM_USER));
    LOADTOS;
    NEXT;

/*$p read-line */   case READ_LINE:  /* adr len fid -- actual more? ior */
    tos = freadline(tos, sp, up);
    NEXT;

/*$p r/o */         case R_O:  PUSH(READ_MODE);  NEXT;
/*$p open-file */   case OPEN_FILE:
    scr = tos;   // mode in ascr1
    LOADTOS;
  alerror(DS(sp), tos, up);
  ERROR("\n");

    tos = pfopen(DS(sp), tos, scr, up);
    DS(sp) = tos;
    tos = (tos != 0) ? 0 : -11;
    NEXT;

/*$p close-file */  case CLOSE_FILE:
    tos = pfclose(tos, up);     /* EOF on error */
    NEXT;

/*$p to-ram */  case TO_RAM:
    V(RAMTOKENS) = POP;
    V(RAMCT) = V(DP);
    V(DP) = V(RAMTOKENS);
    NEXT;

default:   // Non-primitives - colon defs, constants, etc.
    ascr = token;                        // Code field address
    scr  = TOKEN(ascr);                  // Code field value
    ascr++;                              // Body address
    switch (scr) {

/*$c (:) */         case DOCOLON:  RS(--rp) = ip;  ip = ascr;  NEXT;
/*$c (constant) */  case DOCON:
    PUSH(nfetch(ascr));
    NEXT;

/*$c (variable) */  case DOVAR:   /* PUSH(ascr); */
                           PUSH( up + TOKEN(ascr) );  
                            NEXT;
/*$c (create) */    case DOCREATE: PUSH(ascr); NEXT;
/*$c (user) */      case DOUSER:  PUSH(up + TOKEN(ascr));  NEXT;
/*$c (defer) */     case DODEFER: token = V(TOKEN(ascr));  DOEXECUTE;
/*$c (vocabulary) */case DOVOC:   tokstore(token, up + CONTEXT);  NEXT;
/*$c (code) */      case DOCODE:
#if 0
                        (*(void (*) ())ascr)();
#endif
                        NEXT;

default:    /* DOES> word */
    /* Push parameter field address */
    PUSH(ascr);

    /* Use the code field as the address of a colon definition */
    /* Maybe we should pick it up as a token? Then */
    /* we could do ;code stuff by adding its code to the switch */
    RS(--rp) = ip;
    ip = scr;
    NEXT;
    }

    } // End of switch

    // This is the tail of "execute"
    // We get here by  "break"  from the main switch
    if (token > MAXPRIM) {
        scr = TOKEN(token);
        if (scr < MAXPRIM)
            token = scr;
    }
    
   } // End of walk: while(true)

   // This is the tail of "throw"
   // We get here by  "goto throw" from C, "break walk" from Java.
#ifndef JAVA
   throw:
#endif

   if (V(HANDLER) == 0) {
       V(STATE) = 0;
       reveal(up);
       if (V(COMPLEVEL) != 0) {
           V(DP) = V(SAVED_DP);
           V(LIMIT) = V(SAVED_LIMIT);
           V(COMPLEVEL) = 0;
       }
       // Restore the local copies of the virtual
       // machine registers to the external copies
       // and exit to the outer interpreter.
       V(XSP) = V(SPZERO);
       V(XRP) = V(RPZERO);
       return(1);
   }
   {   int trp = V(RSSAVE);
       DATA(trp++) = ip;
       while (rp < V(HANDLER))
           DATA(trp++) = RS(rp++);
       V(RSMARK) = trp;
   }

   V(HANDLER) = RS(rp++);
   // Error num remains in tos
   sp = RS(rp++) + 1;  // Saved SP included acf location 
   ip = RS(rp++);

  } // End of outer while(true)
}

SCOPE2 void spush(cell n, int up)
{
    V(XSP)--;
    DS(V(XSP)) = n;
}

SCOPE2 int execute_xt(int xt, int up)
{
    TOKEN(V(CTBUF)) = xt;
    TOKEN(V(CTBUF)+1) = FINISHED;

    V(XRP) --;
    RS(V(XRP)) = V(CTBUF);

    return inner_interpreter(up);
}

SCOPE3 int
execute_word(String s
#ifndef JAVA
, int up
#endif
)
{
    int xt;
    int slen;
    slen = strtoal(s, V(TMPSTRBUF), up);

    if ((xt = alfind(V(TMPSTRBUF), slen, up)) == 0) {
        ERROR("Can't find '");
        alerror(up+TMP1, slen, up);
        ERROR("'\n");
        return(-2);
    }

    return execute_xt(xt, up);
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
/*$u freelocbuf e FREELOCBUF:   */
/*$u ctbuf      e CTBUF:        */
/*$u canonstr   e CANONSTR:     */
/*$u tmpstrbuf  e TMPSTRBUF:    */

/*$u 'sysptr    e SYSPTR:       */
/*$u boundary   e BOUNDARY:     */
/*$u tmp1       e TMP1:         */
/*$u tmp2       e TMP2:         */
/*$u tmp3       e TMP3:         */
/*$u tmp4       e TMP4:         */

/*$t current    e CURRENT:      */
/*$t context    e CONTEXT:      *$UUUUUUUUUUUUUUU */ /* 15 extra voc slots */

SCOPE1 void
type(int adr, int len, int up)
{
    while ((len--) != 0)
        emit(CHARS(adr++), up);
}

#ifdef INCLUDE_LOCALS
int
find_local(adr, int plen, xt_t *xtp, cell *up)
{
    int slen;
    struct local_name *locnames = (struct local_name *)V(LOCALS);

    /* The first character in the string is the Forth count field. */
    int s, p;

    for ( V(LOCNUM) = 0; V(LOCNUM) < V(NUMINS); V(LOCNUM)++) {
        s = locnames[V(LOCNUM)].name;
        p = adr;
        slen = CHARS(s++);
        if ( slen != plen)
            continue;

        while ((slen--) != 0)
            if ( CHARS(s++) != CHARS(p++) )
                break;

        if (slen < 0) {
            TOKEN(xtp) = TOKEN(DOLOCNAME);
            return (1);                     /* Immediate */
        }
    }
    return (0);
}
#endif

/*
 * It is tempting to try and eliminate this "hidden" variable by
 * checking to see if *threadp==threadp.  However, that doesn't
 * always work.  The first headerless definition after switching
 * to a different "current" vocabulary will break it; thus we need
 * the "hidden" variable to assert that there really is a hidden header.
 */

SCOPE1 void
hide(int up)
{
    int threadp = up + DATA(voc_unum + T(CURRENT));

    tokstore(TOKEN(LAST-1), threadp);
    V(THISDEF) = (cell)threadp;
}

SCOPE1 void
reveal(int up)
{
    if (V(THISDEF) != 0) {
        tokstore(T(LASTP), V(THISDEF));
        V(THISDEF) = 0;
    }
}

SCOPE1 void
cmove(int from, int to, int length)
{
    while ((length--) != 0)
        CHARS(to++) = CHARS(from++);
}

SCOPE1 void
cmove_up(int from, int to, int length)
{
    from += length;
    to += length;

    while ((length--) != 0)
        CHARS(--to) = CHARS(--from);
}

SCOPE1 void
fill_bytes(int to, int length, int with)
{
    while ((length--) != 0)
        CHARS(to++) = with;
}

SCOPE1 int
compare(int adr1, int len1, int adr2, int len2)
{
    while ((len1 != 0) && (len2 != 0)) {
        if (CHARS(adr1) != CHARS(adr2))
            return((CHARS(adr1) < CHARS(adr2)) ? -1 : 1);
        adr1++; adr2++; len1--; len2--;
    }
    if (len1 == len2)
        return(0);
    return((len1 < len2) ? -1 : 1);
}

// If string 1 is a proper substring of string2, return the offset from
// the start of string2 where string1 begins.  If string1 is not a
// substring of string2, return -1.
SCOPE1 int
strindex(int adr1, int len1, int adr2, int len2)
{
    int n;
    int p, q;
    int i;

    for(n = 0; len1 >= len2; adr1++, len1--, n++) {
        p = adr2;
        q = adr1;
        i = len2;
        while (true) {
            if (i == 0)  // Found match
                return n;
            if (CHARS(p++) != CHARS(q++))
                break;  
            i--;
        }   
    }
    return(-1);
}

#if later
int
strlen(int s)
{
    int p = s;
    while (CHARS(p)) { p++; }
    return p-s;
}

/* Interface to user-supplied C subroutines */
int
doccall(cell (*function_adr)(), String format, cell *up)
{
    cell DS(sp) = (cell *)V(XSP);
    cell arg0, arg1, arg2, arg3, arg4,  arg5,
           arg6, arg7, arg8, arg9, arg10, arg11;
    cell ret;
    char cstr[128];

/* The following cases are ordered by expected frequency of occurrence */
#define CONVERT(var) \
    switch(*format++) {\
        case 'i': var = DS(sp++); break;\
        case '-': goto doccall;\
        case '$': ret = DS(sp++); var = (cell) altostr((String)(DS(sp++)), ret, cstr, 128); break;\
        case 'a': var = (cell) (DS(sp++)); break;\
        case 'l': var = DS(sp++); break;\
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
    case '\0': ret = DS(sp++); break;
    case 's': DS(--sp) = ret;
              ret = (cell)strlen((String)ret); break;
    case 'a': break;
        /* Default: ret is correct already */
    }
    V(XSP) = (cell)sp;
    return(ret);
}
#endif

/*
 * scanf doesn't work because it would accept numbers which don't take up
 * the whole word, as in 123xyz
 */
SCOPE1 int
alnumber(int adr, int len, int nhigh, int nlow, int up)
{
/* XXX handle double numbers */
    int base = V(BASE);
    int c;
    int d;
    int isminus = 0;
    int accum = 0;

    V(DPL) = -100;
    if( CHARS(adr) == '-' ) {
        isminus = 1;
        len--;
        ++adr;
    }
    for( ; len > 0; len-- ) {
        c = CHARS(adr++);
        if( c == '.' )
            V(DPL) = 0;
        else {
            if( -1 == (d = digit( base, c )) )
                break;
            ++V(DPL);
            accum = accum * base + d;
        }
    }
    if (V(DPL) < 0)
        V(DPL) = -1;
    DATA(nlow)  = (isminus != 0) ? -accum : accum;
    DATA(nhigh) = (isminus != 0) ? -1 : 0;
    return( (len != 0) ? 0 : -1 );
}

SCOPE1 int
tonumber(int adrp, int len, int nhigh, int nlow, int up)
{
    int base = V(BASE);
    int c;
    int adr = DATA(adrp);
    int d;
#ifdef JAVA
    long n = 0;
#else
    unsigned long long n = 0;
#endif

    n = TOLONG(DATA(nlow), DATA(nhigh));

    for( ; len > 0; adr++, len-- ) {
        c = CHARS(adr);
//        if( -1 == (d = Char.digit(c, base)) )
        if( -1 == (d = digit(base, c)) )
            break;
        n = (n*base) + d;
    }

    DATA(nlow) = (int)n;
#ifdef JAVA
    DATA(nhigh) = (int)(n>>>32);
#else
    DATA(nhigh) = (int)(n>>32);
#endif
    DATA(adrp) = (int)adr;

    return(len);
}

#ifndef JAVA

void
dplus(int *dhighp, int *dlowp, int shigh, int slow)
{
    long long d;

    d = TOLONG(*dlowp, *dhighp);
    d += TOLONG(slow, shigh);
    SETLONG(d, *dlowp, *dhighp);
}

void
dminus(int *dhighp, int *dlowp, int shigh, int slow)
{
    long long d;
    d = TOLONG(*dlowp, *dhighp);
    d -= TOLONG(slow, shigh);
    SETLONG(d, *dlowp, *dhighp);
}

void
mplus(cell *dhighp, cell *dlowp, cell n)
{
    long long d;
    d = TOLONG(*dlowp, *dhighp);
    d += TOLONG(n, 0);
    SETLONG(d, *dlowp, *dhighp);
}

void
umtimes(unsigned int *dhighp, unsigned int *dlowp, unsigned int u1, unsigned int u2)
{
    unsigned long long d;

    d = UTOLONG(u1) * UTOLONG(u2);
    SETLONG(d, *dlowp, *dhighp);
}

void
mtimes(int *dhighp, int *dlowp, int n1, int n2)
{
    long long d;

    d = (long long)n1 * (long long)n2;
    SETLONG(d, *dlowp, *dhighp);
}

void
dutimes(unsigned int *dhighp, unsigned int *dlowp, unsigned int u)
{
    unsigned long long d;
    d = TOLONG(*dlowp, *dhighp);
    d *= UTOLONG(u);
    SETLONG(d, *dlowp, *dhighp);
}

// quotient in dhighp, remainder in dlowp
SCOPE1 void
umdivmod(unsigned int *dhighp, unsigned int *dlowp, unsigned int u) 
{
    unsigned long long d;
    d = TOLONG(*dlowp, *dhighp);
    *dhighp = d/u;
    *dlowp = d%u;
}

// ( d mul div -- )   d * mul / div with triple precision intermediate
SCOPE1 void
mtimesdiv(int *dhighp, int *dlowp, int n1, int n2)
{
    int sign;
    unsigned int thigh, tmid, tlow, temp;

    sign = *dhighp ^ n1;        /* Determine the sign of the final result */

    if ( n1 < 0 )               /* Make n1 positive */
        n1 = -n1;

    if (*dhighp < 0)            /* Make d positive */
        *dhighp = ~*dhighp + ((*dlowp = -*dlowp) == 0);         /* dnegate */
        
    umtimes(&tmid, &tlow, *dlowp, n1);  /* now we have tlow and partial tmid */
    umtimes(&thigh, &temp, *dhighp, n1);
    mplus((int *)&thigh, (int *)&tmid, temp);

    /* Now we have the absolute value of the triple intermediate result */

    *dhighp = thigh;
    *dlowp  = tmid;
    umdivmod((unsigned int *)dhighp, (unsigned int *)dlowp, n2);/* quot in dhighp, rem in dlowp */
    temp = tlow;
    umdivmod((unsigned int *)dlowp, &temp, n2);

    /* Now we have the absolute value of the double final result */

    if (sign < 0)               /* Correct the sign of the result */
        *dhighp = ~*dhighp + ((*dlowp = -*dlowp) == 0);
}
#endif

// Converts the character c into a digit in base 'base'.
// Returns the digit or -1 if not a valid digit.
// Accepts either lower or upper case letters for bases larger than ten.
SCOPE1 int
digit(int base, int c)
{
    int ival = c;

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

SCOPE1 void
ip_canonical(int adr, int len, int up)   // Canonicalize string "in place"
{
    int p;
    int c;

    if (V(CAPS) == 0)
        return;

    for (p = adr; (len--) != 0; p++) {
        c = CHARS(p);
        CHARS(p++) = (c >= 'A' && c <= 'Z') ? (c - 'A' + 'a') : c;
    }
}
