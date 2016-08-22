#include "forth.h"
#include "specialkeys.h"
#include "string.h"

extern int key();

#define CTRL(c) (c & 0x1f)

#define BS 8
#define DEL 127

static char *thisaddr;
static char *startaddr;
static char *endaddr;
static char *maxaddr;

void addchar(char c, void *up) {
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

void erase_char(void *up) {
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

void erase_line(void *up) {
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

void add_to_history(char *adr, int len, void *up)
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
int get_history(int history_num, void *up)
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

void backward_char(void *up)
{
    if (thisaddr > startaddr) {
        emit(BS, up);
        --thisaddr;
    }
}

void forward_char(void *up)
{
    if (thisaddr < endaddr) {
        emit(*thisaddr, up);
        ++thisaddr;
    }
}

void forward_word(void *up)
{
    while ((thisaddr < endaddr) && (*thisaddr == ' ')) {
        emit(*thisaddr, up);
        ++thisaddr;
    }
    while ((thisaddr < endaddr) && (*thisaddr != ' ')) {
        emit(*thisaddr, up);
        ++thisaddr;
    }
}

void backward_word(void *up)
{
    if (startaddr >= endaddr) {
	return;
    }
    // If already at the beginning of a word, dislodge the cursor
    if ((thisaddr < endaddr) && (*thisaddr != ' ') &&
	(thisaddr > startaddr) && (thisaddr[-1] == ' ')) {
        emit(BS, up);
        --thisaddr;
    }
    // Scan backward over spaces
    while ((thisaddr < endaddr) && (*thisaddr == ' ') && (thisaddr > startaddr)) {
        emit(BS, up);
        --thisaddr;
    }
    // Scan backward to a non-space just after a space
    while ((thisaddr > startaddr) && (thisaddr[-1] != ' ')) {
        emit(BS, up);
        --thisaddr;
    }
}

int isdelim(char *addr)
{
    return (addr < startaddr) || (addr == endaddr) || (*addr == ' ');
}

static char word[32];
void find_word_under_cursor(cell *up)
{
    int i = 0;
    word[i] = '\0';
    char *taddr = thisaddr;

    if (startaddr == endaddr) {
	return;
    }
    if ( (taddr < endaddr) && (*taddr == ' ') &&
	  (taddr > startaddr) && (taddr[-1] == ' ')
	) {
	return;
    }
    while ((taddr > startaddr) && (taddr[-1] != ' ')) {
	--taddr;
    }
    while ((taddr < endaddr) && (*taddr != ' ')) {
	if (i != 32) {
	    word[i++] = *taddr;
	}
	++taddr;
    }
    word[i] = '\0';
    while (thisaddr < taddr) {
	emit(*thisaddr++, up);
    }
}

int num_initial_matches(char *adr, cell len, int matchnum, char **namep, int *actual_len, cell *up);

static void highlight(cell *up)
{
    emit(0x1b, up);
    emit('[', up);
    emit('3', up);
    emit('4', up);
    emit('m', up);
}

static void lowlight(cell *up)
{
    emit(0x1b, up);
    emit('[', up);
    emit('0', up);
    emit('m', up);
}

#ifndef NO_COMPLETION
static int nmatches = 0;
static int matchlen;
static int thismatch = 0;

void complete_word(cell *up)
{
    find_word_under_cursor(up);
    if (*word == '\0') {
	return;
    }
    char *name;
    int len = strlen(word);
    nmatches = num_initial_matches(word, len, 0, &name, &matchlen, up);

    if (nmatches == 0) {
	return;
    }
    if (nmatches == 1) {
	while(len < matchlen) {
	    addchar(name[len++], up);
	}
	addchar(' ', up);
	nmatches = 0;
	return;
    }

    while (len < matchlen) {
	int nmatches2, matchlen2;
	char *name2;
	word[len] = name[len];
	nmatches2 = num_initial_matches(word, len+1, 0, &name2, &matchlen2, up);
	if (nmatches2 != nmatches) {
	    break;
	}
	addchar(word[len++], up);
    }
    word[len] = '\0';

    thismatch = 0;
    highlight(up);
    while (len < matchlen) {
	addchar(name[len++], up);
    }
    lowlight(up);
}

void propose_word(cell *up)
{
    if (++thismatch == nmatches) {
	thismatch = 0;
    }
    int newmatchlen;
    char *name;
    int len = strlen(word);
    int nmatches = num_initial_matches(word, len, thismatch, &name, &newmatchlen, up);
    while (matchlen > len) {
	erase_char(up);
	--matchlen;
    }
    highlight(up);
    while (matchlen < newmatchlen) {
	addchar(name[matchlen++], up);
    }
    lowlight(up);
}
#endif

static int escaping;
static int history_num = -1;

void lineedit_start(char *addr, int count, cell *up)
{
    startaddr = endaddr = thisaddr = addr;
    escaping = 0;
    maxaddr = addr + count;
    history_num = -1;
}

int lineedit_finish(cell *up)
{
    int length = (int)(endaddr - startaddr);
    add_to_history(startaddr, length, up);

    return (length);
}

// Returns true when the line is complete
int lineedit_step(int c, cell *up)
{
    // If we are running on Windows, key() returns the SPECIAL_* values
    // for non-ASCII movement keys.  Under a terminal emulator, such keys
    // generate escape sequences that we parse herein and convert to
    // those SPECIAL_* values.

	// Expecting [ as second character of escape sequence
	if (escaping == 1) {
	    if (c >= 'A' && c <= 'Z') {
		c += 'a' - 'A';
	    }
	    switch (c)
	    {
	    case '[': escaping = 2;  return 0;
	    case 'f': forward_word(up); break;
	    case 'b': backward_word(up); break;
	    }
	    escaping = 0;
	    return 0;
	}

	// Expecting third character of escape sequence
	if (escaping == 2) {
	    escaping = 0;
            switch (c)
            {
            // In these 3 cases we have to get one more byte, typically ~
            case '2': escaping = SPECIAL_HOME;   return 0; // esc[2~ HOME
            case '5': escaping = SPECIAL_END;    return 0; // esc[5~ END
            case '3': escaping = SPECIAL_DELETE; return 0; // esc[3~ DELETE

            // In these cases we are done so translate to the special code
            case 'H': c = SPECIAL_HOME;  break;  // esc[H Home key
            case 'F': c = SPECIAL_END;   break;  // esc[F End key
            case 'A': c = SPECIAL_UP;    break;  // esc[A Up arrow
            case 'B': c = SPECIAL_DOWN;  break;  // esc[B Down arrow
            case 'C': c = SPECIAL_RIGHT; break;  // esc[C Right arrow
            case 'D': c = SPECIAL_LEFT;  break;  // esc[D Left arrow
            }
	    // Fall through to the switch below (escaping is now 0)
	}

	// This handles the ESC[n~ case - escaping is one of SPECIAL_{HOME,END,DELETE}
	if (escaping) {
	    if (c == '~') {
		c = escaping;
		escaping = 0;
	    } else {
		escaping = 0;
		return 0;
	    }
	}

#ifndef NO_COMPLETION
	if (c == CTRL('i')) {
	    if (nmatches) {
		propose_word(up);
	    } else {
		complete_word(up);
	    }
	    return 0;
	}
	nmatches = 0;
#endif

	switch (c)
	{
	case 27:  // Escape
	    escaping = 1;
	    break;
	case '\n':
	case '\r':
	    emit('\n', up);
            V(NUM_OUT) = 0;
	    return 1;
	case -1:
	    return 1;
	case DEL:
	case BS:
	    if (thisaddr > startaddr)
		erase_char(up);
	    break;
	case CTRL('a'):
	case SPECIAL_HOME:
	    while (thisaddr > startaddr)
		backward_char(up);
	    break;
	case CTRL('b'):
	case SPECIAL_LEFT:
	    backward_char(up);
	    break;
	case CTRL('d'):
	case SPECIAL_DELETE:
	    if (thisaddr < endaddr ) {
		forward_char(up);
		erase_char(up);
	    }
	    break;
	case CTRL('e'):
	case SPECIAL_END:
	    while (thisaddr < endaddr)
		forward_char(up);
	    break;
	case CTRL('f'):
	case SPECIAL_RIGHT:
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
	case SPECIAL_UP:
	    if (get_history(history_num+1, up))
		++history_num;
	    break;
	case CTRL('n'):
	case SPECIAL_DOWN:
	    if (get_history(history_num-1, up))
		--history_num;
	    break;
	case CTRL('w'):
	    while (thisaddr > startaddr && thisaddr[-1] == ' ')
		erase_char(up);
	    while (thisaddr > startaddr && thisaddr[-1] != ' ')
		erase_char(up);
	    break;

	default:
	    if (c >= ' ')
		addchar(c, up);
	}
        return 0;
}

// Line editor with history and intra-line editing
int lineedit(char *addr, int count, void *up)
{
    lineedit_start(addr, count, up);
    while (lineedit_step(key(), up) == 0) {
    }
    return lineedit_finish(up);
}
