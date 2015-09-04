#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>
#define STDIN_FILENO 0

static int rawmode = 0; /* For atexit() function to check if restore is needed*/
static struct termios orig_termios; /* In order to restore at exit.*/

static void keyboard_cooked() {
    /* Don't even check the return value as it's too late. */
    if (rawmode && tcsetattr(STDIN_FILENO,TCSAFLUSH,&orig_termios) != -1)
        rawmode = 0;
}

/* At exit we'll try to fix the terminal to the initial conditions. */
static void keyAtExit(void) {
    keyboard_cooked();
}

int keyboard_raw() {
    struct termios raw;

    if (rawmode) return 1;
    if (!isatty(STDIN_FILENO)) goto fatal;
    if (tcgetattr(STDIN_FILENO,&orig_termios) == -1) goto fatal;

    raw = orig_termios;  /* modify the original mode */
    /* input modes: no break, no CR to NL, no parity check, no strip char,
     * no start/stop output control. */
    raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    /* output modes - disable post processing */
//    raw.c_oflag &= ~(OPOST);
    /* control modes - set 8 bit chars */
    raw.c_cflag |= (CS8);
    /* local modes - choing off, canonical off, no extended functions,
     * no signal chars (^Z,^C) */
    raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
    raw.c_lflag |= ISIG;
    raw.c_cc[VINTR] = 3; /* Ctrl-C interrupts process */
    /* control chars - set return condition: min number of bytes and timer.
     * We want read to return every single byte, without timeout. */
    raw.c_cc[VMIN] = 1; raw.c_cc[VTIME] = 0; /* 1 byte, no timer */

    /* put terminal in raw mode after flushing */
    if (tcsetattr(STDIN_FILENO,TCSAFLUSH,&raw) < 0) goto fatal;
    rawmode = 1;
    atexit(keyAtExit);
    return 1;

fatal:
    return 0;
}

#include <poll.h>
int key_avail()
{
    if(!isatty(STDIN_FILENO))
        return 0;
    struct pollfd fd = { STDIN_FILENO, POLLIN, 0 };
    fflush(stdout);
    return poll(&fd, 1, 0) > 0;
}

int key(void)
{
    struct termios ostate;
    struct termios kstate;
    int c;
    unsigned char cchar;

    fflush(stdout);
    (void)keyboard_raw();

    if (read(STDIN_FILENO, &cchar, 1) == 1)
	    return (unsigned int)cchar;

    // Exit if the keyboard has disappeared
    exit(0);
    return(0);  /* To avoid compiler warnings */
}

// Returns -1 to indicate that ansi_emit did nothing
// On Linux and similar systems, terminal windows typically
// emulate ANSI terminals, so there is no need to do ANSI
// escape sequence processing inside CForth.
int ansi_state = 0;

// Returns -1 if stdout is not a console,
// 0 if the character was part of an escape sequence,
// 1 if a character was written to the screen, thus advancing the cursor
// We can use the system's terminal emulator to do the real work, but
// we need to track the escape sequence to determine the cursor position.
int ansi_emit(int c, FILE *fd)
{
    switch (ansi_state)
    {
    case 0:  // Normal state, not in an escape sequence
	if (c == 0x1b) // ESC
	    ansi_state = 1;
	else
	    if (c == 0x9b)
		ansi_state = 2;
	    else {
		putc(c,fd);
                (void)fflush(fd);
		return 1;
	    }
	break;
    case 1: // Received ESC but not yet [
	ansi_state = (c == '[') ? 2 : 0;
	break;
    case 2: // Received ESC[ or 0x9b and possibly some digits
	if (c == ';')
	    ansi_state = 3;
	else if (c < '0' || c > '9')
	    ansi_state = 0; // End received, return to normal
	break;
    case 3: // Received ; and possibly some more digits
	if (c < '0' || c > '9')
	    ansi_state = 0; // End received, return to normal
	break;
    }
    putc(c,fd);
    (void)fflush(fd);
    return 0;
}
