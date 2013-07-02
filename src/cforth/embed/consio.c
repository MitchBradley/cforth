/*
 * Stub I/O subroutines for C Forth 93, supporting only console I/O.
 *
 * Exported definitions:
 *
 * emit(char);                  Output a character
 * n = key_avail();             How many characters can be read?
 * error(s);                    Print a string on the error stream
 * n = caccept(addr, count);    Collect a line of input
 * char = key();                Get the next input character
 */

#include "forth.h"
#include "compiler.h"

extern int key();

int isinteractive() {  return (1);  }

#define CTRL(c) (c & 0x1f)

#define BS 8
#define DEL 127

void emit(u_char c, cell *up)
{
    if ( c == '\n' || c == '\r' ) {
        V(NUM_OUT) = 0;
        V(NUM_LINE)++;
    } else
        V(NUM_OUT)++;
    (void)putchar((char)c);
}

void cprint(char *str, cell *up)
{
    while (*str)
        emit((u_char)*str++, up);
}

void title(cell *up)
{
    cprint("C Forth 2005.  Copyright (c) 1997-2005 by FirmWorks\n", up);
}

void alerror(char *str, int len, cell *up)
{
    while (len--)
        emit((u_char)*str++, up);

    /* Sequences of calls to error() eventually end with a newline */
    V(NUM_OUT) = 0;
}

int moreinput() {    return (1);  }


static char *thisaddr;
static char *startaddr;
static char *endaddr;
static char *maxaddr;

void addchar(char c, cell *up) {
    char *p;
    if (thisaddr < maxaddr) {
        if (endaddr < maxaddr)
            ++endaddr;
        for (p = endaddr; --p >= thisaddr+1; ) {
            *p = *(p-1);
        }
        *thisaddr++ = c;
        emit(c, up);
        for (++p ; p < endaddr; p++) {
            emit (*p, up);
        }
        for (; p > thisaddr; --p) {
            emit(BS, up);
        }
    }
}

void erase_char(cell *up) {
    char *p;
    if (thisaddr > startaddr) {
        --thisaddr;
        --endaddr;
        emit(BS, up);
        for( p = thisaddr; p < endaddr; p++) {
            *p = *(p+1);
            emit(*p, up);
        }
        emit(' ', up);
        for( ++p; p > thisaddr; --p ) {
            emit(BS, up);
        }
    }
}

void erase_line(cell *up) {
    for ( ; thisaddr < endaddr; ++thisaddr)
        emit(*thisaddr, up);
    while (thisaddr > startaddr)
        erase_char(up);
    endaddr = startaddr;
}

#define MAXHISTORY 400
static int saved_length;
static char lastline[MAXHISTORY];

void validate_history()
{
    int i;

    // Clear history if it is invalid
    if (saved_length == 0 || saved_length > MAXHISTORY)
        goto clear_history;

    for (i=0; i < MAXHISTORY; i++) {
        if (lastline[i] & 0x80)
            goto clear_history;
    }
    return;

  clear_history:
    for (i=0; i < MAXHISTORY; i++) {
        lastline[i] = '\0';
    }
    saved_length = 0;
}

int already_in_history(char *adr, int len)
{
    char *p, *first, *this;
    int i;
    if (!saved_length)
        return 0;

    this = adr;
    first = lastline;
    for (p = lastline; p < &lastline[MAXHISTORY];) {
        if (*p == '\0') {
            if ((p - first) == len) {
                // Found a match; reorder history so the match
                // is at the beginning.
                while ((--p - lastline) > len) {
                    *p = p[-len-1];
                }
                *p = '\0';
                for (i = 0; i < len; i++) {
                    lastline[i] = adr[i];
                }
                return 1;
            }
            if (++p == &lastline[MAXHISTORY])
                return 0;
            this = adr;
            first = p;
            continue;
        }
        if (*p == *this) {
            // Match
            ++p;
            ++this;
        } else {
            // Mismatch
            while (*++p != '\0') {}
            ++p;
            this = adr;
            first = p;
        }
    }
    return 0;
}

add_to_history(char *adr, int len)
{
    int i;
    int new_length;

    validate_history();
    if (len && !already_in_history(adr, len)) {
        len += 1;  // Room for null
        new_length = (len > MAXHISTORY) ? MAXHISTORY : len;

        // Make room for new history line
        for (i = MAXHISTORY; --i >= new_length; )
            lastline[i] = lastline[i-new_length];

        lastline[MAXHISTORY-1] = '\0';  // Truncate the last line
        lastline[i] = '\0';

        while (--i >= 0)
            lastline[i] = adr[i];

        saved_length += new_length;
        if (saved_length > MAXHISTORY)
            saved_length = MAXHISTORY;
    }
}

// history_num is the number of the history line to fetch
// returns true if that line exists.
int get_history(int history_num, cell *up)
{
    int i;
    int hn;
    char *p;

    validate_history();

    if (saved_length == 0)
        return 0;

    if (history_num < 0)
        return 0;

    p = lastline;
    for (hn = 0; hn < history_num; hn++) {
        while (*p++ != '\0') {}
        if ((p - lastline) >= saved_length)
            return 0;
    }

    erase_line(up);
    for (i = 0; i < maxaddr-startaddr-1; i++) {
        if (*p == '\0') {
            break;
        }
        addchar(*p++, up);
    }

    return 1;
}

int backward_char(cell *up)
{
    if (thisaddr > startaddr) {
        emit(BS, up);
        --thisaddr;
    }
}

int forward_char(cell *up)
{
    if (thisaddr < endaddr) {
        emit(*thisaddr, up);
        ++thisaddr;
    }
}

int caccept(char *addr, cell count, cell *up)
{
    int c;
    int escaping;
    int length;
    int history_num = -1;
    
    if (isinteractive()) {
        linemode();
    }

    startaddr = endaddr = thisaddr = addr;
    escaping = 0;
    maxaddr = addr + count;

    /* Uses the operating system's terminal driver to do the line editing */ 
    while (1) {
        c = getchar();

        if (escaping == 0) {

            switch (c)
            {
            case 27:  // Escape
                escaping = 1;
                break;
            case '\n':
            case '\r':
            case -1:
                goto done;
            case DEL:
            case BS:
                if (thisaddr > startaddr)
                    erase_char(up);
                break;
            case CTRL('a'):
                while (thisaddr > startaddr)
                    backward_char(up);
                break;
            case CTRL('b'):
                backward_char(up);
                break;
            case CTRL('d'):
                if (thisaddr < endaddr ) {
                    forward_char(up);
                    erase_char(up);
                }
                break;
            case CTRL('e'):
                while (thisaddr < endaddr)
                    forward_char(up);
                break;
            case CTRL('f'):
                forward_char(up);
                break;
            case CTRL('k'):
                while (thisaddr < endaddr) {
                    forward_char(up);
                    erase_char(up);
                }
                break;
            case CTRL('u'):
                erase_line(up);
                break;
            case CTRL('p'):
                if (get_history(history_num+1, up))
                    ++history_num;
                break;
            case CTRL('n'):
                if (get_history(history_num-1, up))
                    --history_num;
                break;
            case CTRL('w'):
                while (thisaddr > addr && thisaddr[-1] == ' ')
                    erase_char(up);
                while (thisaddr > addr && thisaddr[-1] != ' ')
                    erase_char(up);
                break;
                
            default:
                if (c >= ' ')
                    addchar(c, up);
            }
        } else if (escaping == 1) {
            escaping = (c == '[') ? 2 : 0;
        } else if (escaping == 2) {
            escaping = 0;
            switch (c)
            {
            case '2': // Home key
            case '5': // End key
                escaping = c;
                break;
            case 'A': // Up arrow
                if (get_history(history_num+1, up))
                    ++history_num;
                break;
            case 'B': // Down arrow
                if (get_history(history_num-1, up))
                    --history_num;
                break;
            case 'C': // Right arrow
                forward_char(up);
                break;
            case 'D': // Left arrow
                backward_char(up);
                break;
            }
        } else {
            if (c == '~') {
                switch (escaping)
                {
                case '2': // Home key
                    while (thisaddr > startaddr)
                        backward_char(up);
                    break;
                case '5': // End key
                    while (thisaddr < endaddr)
                        forward_char(up);
                    break;
                }
            }
            escaping = 0;
        }
    }

  done:
    if (isinteractive()) { 
        emit('\n', up);
        V(NUM_OUT) = 0;
    }
    
    length = (cell)(endaddr - startaddr);
    add_to_history(addr, length);

    return (length);
}

int key()
{
    keymode();
    return(getchar());
}

int
key_avail()
{
    return kbhit();
}

void read_dictionary(char *name, cell *up)
{
    ERROR("No file I/O\n");
}

void write_dictionary(char *name, int len, char *dict, int dictsize,
                 char *user, int usersize, cell *up)
{
    ERROR("No file I/O\n");
}

cell pfopen(char *name, char *mode)  {  return (0);  }

cell pfclose(cell fd) {  return (0);  }

cell freadline(cell f, cell *sp)        /* Returns IO result */
{
    sp[0] = 0;
    sp[1] = 0;
    return (READFAIL);
}
