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

#if 1
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
