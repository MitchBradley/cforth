#include <stdio.h>
#include <windows.h>

#include "specialkeys.h"

static int rawmode = 0; /* For atexit() function to check if restore is needed*/
static DWORD orig_consolemode = 0;

void keyboard_cooked() {
    if (rawmode)
	SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), orig_consolemode);
    rawmode = 0;
    return;
}

/* At exit we'll try to fix the terminal to the initial conditions. */
static void keyAtExit(void) {
    keyboard_cooked();
}

/* Returns false on failure */
int keyboard_raw() {
    if (rawmode) return 1;
    if (GetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), &orig_consolemode)) {
	// ENABLE_PROCESSED_INPUT handles ^C
	rawmode = SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), ENABLE_PROCESSED_INPUT);
    }
    if (rawmode)
	atexit(keyAtExit);
//  rawmode = SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE),0);
    return rawmode;
}

#if 0
int kbhit(void);
int key_avail(void)
{
    return kbhit();
}
#else

int key_avail(void)
{
    INPUT_RECORD buf;
    DWORD nEvents;
    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);

    if (!keyboard_raw())
	return 0;
    do {
//	(void)GetNumberOfConsoleInputEvents(hStdin, &nEvents);
        (void)PeekConsoleInput(hStdin, &buf, 1, &nEvents);
	if (nEvents == 0) {
//	    keyboard_cooked();
	    return 0;
	}
	if (buf.EventType == KEY_EVENT && buf.Event.KeyEvent.bKeyDown) {
//	    printf("ev %d %d %x\n", buf.EventType, buf.Event.KeyEvent.bKeyDown, buf.Event.KeyEvent.uChar.AsciiChar);
//	    keyboard_cooked();
	    return 1;
	}
	(void)ReadConsoleInput(hStdin, &buf, 1, &nEvents);	
    } while(1);
}
#endif

int key(void)
{
    char buf[1];
    DWORD nEvents;
    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
    
#if 0
    (void)keyboard_raw();
    (void)ReadConsole(hStdin, (LPVOID)buf, 1, &nEvents, NULL);
//    keyboard_cooked();
    return (int)buf[0];
#else
    (void)keyboard_raw();
    while (1) {
        INPUT_RECORD irec;
        DWORD n;
        if (WaitForSingleObject(GetStdHandle(STD_INPUT_HANDLE), INFINITE) != WAIT_OBJECT_0) {
            break;
        }
        if (!ReadConsoleInput (GetStdHandle(STD_INPUT_HANDLE), &irec, 1, &n)) {
            break;
        }
        if (irec.EventType == KEY_EVENT && irec.Event.KeyEvent.bKeyDown) {
            KEY_EVENT_RECORD *k = &irec.Event.KeyEvent;
            if (k->dwControlKeyState & ENHANCED_KEY) {
                switch (k->wVirtualKeyCode) {
                 case VK_LEFT:
                    return SPECIAL_LEFT;
                 case VK_RIGHT:
                    return SPECIAL_RIGHT;
                 case VK_UP:
                    return SPECIAL_UP;
                 case VK_DOWN:
                    return SPECIAL_DOWN;
                 case VK_DELETE:
                    return SPECIAL_DELETE;
                 case VK_HOME:
                    return SPECIAL_HOME;
                 case VK_END:
                    return SPECIAL_END;
                }
            }
            /* Note that control characters are already translated in AsciiChar */
            else {
#ifdef USE_UTF8
                return k->uChar.UnicodeChar;
#else
		/* Suppress NUL character for bare SHIFT and CTRL */
		if (k->uChar.AsciiChar)
		    return k->uChar.AsciiChar;
		/* But do return NUL if the user explicitly types ctrl-@ (ctrl-shift-2 */
		if (k->wVirtualKeyCode == '2')
		    return 0;
#endif
            }
        }
    }
//    (void)keyboard_cooked();
    return -1;
#endif
}

int inverse;
int attributes;
int original_attributes;
int bright = 1;

void do_color(int arg)
{
    HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE); 
    unsigned char fg_colors[] = { 0x00, 0x04, 0x02, 0x06, 0x01, 0x05, 0x03, 0x07 };
    unsigned char bg_colors[] = { 0x00, 0x40, 0x20, 0x60, 0x10, 0x50, 0x30, 0x70 };
    switch (arg)
    {
    case 0: attributes = original_attributes; inverse = 0;  break;
    case 1: bright = 1; break;
    case 2: bright = 0; break;
    case 7: inverse = 1; break;
    case 27: inverse = 0; break;
    default:
	if (arg >= 30 && arg <= 37) {
	    attributes &= ~0xf;
	    attributes |= fg_colors[arg-30];
	    if (bright)
		attributes |= 8;
	} else if (arg >= 40 && arg <= 47) {
	    attributes &= ~0xf0;
	    attributes |= bg_colors[arg-40];
	    if (bright)
		attributes |= 0x80;
	}
    }
	
    bright = 1;
    SetConsoleTextAttribute(hStdout, attributes);
}

void set_colors(int arg0, int arg1, int numargs)
{
    do_color(arg0);
    if (numargs > 1)
	do_color(arg1);
}

void kill_screen(int arg)
{
    HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE); 
    CONSOLE_SCREEN_BUFFER_INFO csbiInfo;
    SMALL_RECT srctScrollRect, srctClipRect, srctWindow; 
    CHAR_INFO chiFill; 
    COORD coordDest; 
    int line, column, left, top, right, bottom;

    GetConsoleScreenBufferInfo(hStdout, &csbiInfo);
    srctWindow = csbiInfo.srWindow;
 
    line     = csbiInfo.dwCursorPosition.Y;
    column   = csbiInfo.dwCursorPosition.X;

    left   = srctWindow.Left;
    top    = srctWindow.Top;
    right  = srctWindow.Right;
    bottom = srctWindow.Bottom;

    // Clip to the display window
    srctClipRect = csbiInfo.srWindow;

    // Fill with the current attributes
    chiFill.Attributes = attributes; 
    chiFill.Char.AsciiChar = (char)' '; 
 
    // This is an erase, so put the destination off-screen
    coordDest.X = right;
    coordDest.Y = bottom;
 
    switch(arg)
    {
    case 2:  // Entire screen
	srctScrollRect = srctWindow;
	break;
    case 1:  // Beginning of screen to cursor
	// First erase the rectangle above the cursor line
	srctScrollRect.Top    = top;
	srctScrollRect.Bottom = line;
	srctScrollRect.Left   = left;
	srctScrollRect.Right  = right;
	ScrollConsoleScreenBuffer(hStdout,&srctScrollRect,&srctClipRect,coordDest,&chiFill);
	// Followed by the part of the cursor line left of the cursor
	srctScrollRect.Top    = line;
	srctScrollRect.Bottom = line+1;
	srctScrollRect.Left   = left;
	srctScrollRect.Right  = column;
	break;
    default:  // 0 or any other number - cursor to end of screen
	// First erase the rectangle below the cursor line
	srctScrollRect.Top    = line;
	srctScrollRect.Bottom = bottom;
	srctScrollRect.Left   = left;
	srctScrollRect.Right  = right;
	ScrollConsoleScreenBuffer(hStdout,&srctScrollRect,&srctClipRect,coordDest,&chiFill);
	// Followed by the part of the cursor line right of the cursor
	srctScrollRect.Top    = line;
	srctScrollRect.Bottom = line+1;
	srctScrollRect.Left   = column;
	srctScrollRect.Right  = right;
	break;
    }
    ScrollConsoleScreenBuffer(hStdout,&srctScrollRect,&srctClipRect,coordDest,&chiFill);
}

void kill_line(int arg)
{
    HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE); 
    CONSOLE_SCREEN_BUFFER_INFO csbiInfo;
    SMALL_RECT srctScrollRect, srctClipRect, srctWindow; 
    CHAR_INFO chiFill; 
    COORD coordDest; 
    int line, column, left, top, right, bottom;

    GetConsoleScreenBufferInfo(hStdout, &csbiInfo);
    srctWindow = csbiInfo.srWindow;
 
    line     = csbiInfo.dwCursorPosition.Y;
    column   = csbiInfo.dwCursorPosition.X;

    left   = srctWindow.Left;
    top    = srctWindow.Top;
    right  = srctWindow.Right;
    bottom = srctWindow.Bottom;

    // Clip to the display window
    srctClipRect = csbiInfo.srWindow;

    // Fill with the current attributes
    chiFill.Attributes = attributes; 
    chiFill.Char.AsciiChar = (char)' '; 
 
    // This is an erase, so put the destination off-screen
    coordDest.X = right;
    coordDest.Y = bottom;
 
    // Source rectangle - only the current line
    srctScrollRect.Top    = line;
    srctScrollRect.Bottom = line+1;
 
    switch(arg)
    {
    case 2:  // Entire line
	srctScrollRect.Left   = left;
	srctScrollRect.Right  = right;
	break;
    case 1:  // Beginning of line to cursor
	srctScrollRect.Left   = left;
	srctScrollRect.Right  = column;
	break;
    default:  // 0 or any other number - cursor to end of line
	srctScrollRect.Left   = column;
	srctScrollRect.Right  = right;
	break;
    }
    ScrollConsoleScreenBuffer(hStdout,&srctScrollRect,&srctClipRect,coordDest,&chiFill);
}

#define NUM_ARGS(state) (state - 1)
void set_cursor(int arg0, int arg1, int nargs)
{
    HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE); 
    COORD pos;
    CONSOLE_SCREEN_BUFFER_INFO csbiInfo; 
    int left, top, x, y;

    GetConsoleScreenBufferInfo(hStdout, &csbiInfo);

    left = csbiInfo.srWindow.Left;
    top = csbiInfo.srWindow.Top;
    x = left + (arg0-1);
    y = nargs==2 ? top + (arg1-1) : top;
    pos.X = x;
    pos.Y = y;
    SetConsoleCursorPosition(hStdout, pos);
#if 0
    printf("left %d top %d right %d bottom %d x %d y %d X %d Y %d nargs %d arg0 %d arg1 %d\n",
	   csbiInfo.srWindow.Left,
	   top, // csbiInfo.srWindow.Top,
	   csbiInfo.srWindow.Right,
	   csbiInfo.srWindow.Bottom,
	   x, y,
	   pos.X, pos.Y,
	   nargs, arg0, arg1
	);
#endif
}
void move_cursor(int dx, int dy)
{
    CONSOLE_SCREEN_BUFFER_INFO info;
    COORD pos;
    GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &info);
    pos.X = info.dwCursorPosition.X + dx;
    pos.Y = info.dwCursorPosition.Y + dy;
    SetConsoleCursorPosition(GetStdHandle(STD_OUTPUT_HANDLE), pos);
}

// dx<0 delete chars, dx>0 insert chars, dy<0 delete lines, dy>0 insert lines
void move_rectangle(int dx, int dy)
{
    HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE); 
    CONSOLE_SCREEN_BUFFER_INFO csbiInfo; 
    SMALL_RECT srctScrollRect, srctClipRect, srctWindow; 
    CHAR_INFO chiFill; 
    COORD coordDest; 
    int line, column, left, top, right, bottom;

    GetConsoleScreenBufferInfo(hStdout, &csbiInfo);
    srctWindow = csbiInfo.srWindow;
 
    line     = csbiInfo.dwCursorPosition.Y;
    column   = csbiInfo.dwCursorPosition.X;

    left   = srctWindow.Left;
    top    = srctWindow.Top;
    right  = srctWindow.Right;
    bottom = srctWindow.Bottom;

    // Clip to the display window
    srctClipRect = csbiInfo.srWindow;

    // Fill with the current attributes
    chiFill.Attributes = attributes; 
    chiFill.Char.AsciiChar = (char)' '; 
 
    // Source rectangle
 
    srctScrollRect.Top = dy<0 ? line-dy : line;

    if (dx) {
	// Operating on characters
	srctScrollRect.Left = dx<0 ? column-dx : column;
	srctScrollRect.Bottom = line+1;
	coordDest.X = dx<0 ? column : column+dx;
    } else {
	// Operating on lines
	srctScrollRect.Left = left;
	srctScrollRect.Bottom = dy<0 ? bottom+dy : bottom;
	coordDest.X = left;
    }
    srctScrollRect.Right = right;
    coordDest.Y = dy<0 ? line : line+dy ;
 
    ScrollConsoleScreenBuffer(  
        hStdout,         // screen buffer handle 
        &srctScrollRect, // source rectangle 
        &srctClipRect,   // clipping rectangle 
        coordDest,       // top left destination cell 
        &chiFill);      // fill character and color
}

void write_character(char c)
{
    HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE); 
    DWORD actual;
    WriteConsole(hStdout, &c, 1, &actual, NULL);
}

int firsttime = 1;
int is_console(void)
{
    HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE); 
    DWORD mode;
    int ret;
    ret = GetConsoleMode(hStdout, &mode);
    if (ret && firsttime) {
	CONSOLE_SCREEN_BUFFER_INFO csbiInfo; 

	firsttime = 0;
	GetConsoleScreenBufferInfo(hStdout, &csbiInfo);
	original_attributes = attributes = csbiInfo.wAttributes;
    }
    return ret;
}

int ansi_state = 0;
int arg0;
int arg1;


// Returns -1 if stdout is not a console,
// 0 if the character was part of an escape sequence,
// 1 if a character was written to the screen, thus advancing the cursor
int ansi_emit(int c, FILE *fd)
{
    int arg01;
    int arg11;

    if (!is_console())
	return -1;
    switch (ansi_state)
    {
    case 0:
	if (c == 0x1b) // ESC
	    ansi_state = 1;
	else
	    if (c == 0x9b) {
		ansi_state = 2;
		arg0 = arg1 = 0;
	    } else {
		write_character(c);
		return 1;
	    }
	break;
    case 1:
	ansi_state = (c == '[') ? 2 : 0;
	arg0 = arg1 = 0;
	break;
    case 2:
	if (c >= '0' && c <= '9')
	    arg0 = arg0 * 10 + (c - '0');
	else if (c == ';')
	    ansi_state = 3;
	else
	    goto do_command;
	break;
    case 3:
	if (c >= '0' && c <= '9')
	    arg1 = arg1 * 10 + (c - '0');
	else
	    goto do_command;
	break;
    }
    return 0;

// End of escape sequence
do_command:
    arg01 = arg0 ? arg0 : 1;
    arg11 = arg1 ? arg1 : 1;

    switch (c)
    {
    case '@': move_rectangle(arg01, 0); break;  // Insert characters
    case 'A': move_cursor(0,arg01); break;
    case 'B': move_cursor(0,-arg01); break;
    case 'C': move_cursor(arg01,0); break;
    case 'D': move_cursor(-arg01,0); break;
//  case 'E': set_line(arg0); break;
//  case 'h': set_modes(arg0, arg1, ansi_state); break;
//  case 'l': reset_modes(arg0, arg1, ansi_state); break;
    case 'H': set_cursor(arg11, arg01, NUM_ARGS(ansi_state)); break;
    case 'J': kill_screen(arg0); break;
    case 'K': kill_line(arg0); break;
    case 'L': move_rectangle(0, arg01); break;   // Insert lines
    case 'M': move_rectangle(0,-arg01); break;   // Delete lines
    case 'P': move_rectangle(-arg01, 0); break;  // Delete characters
    case 'm': set_colors(arg0, arg1, NUM_ARGS(ansi_state)); break;
//    case 'p': uninvert_screen(); break;
//    case 'q': invert_screen(); break;
    }
    ansi_state = 0;
    return 0;
}
