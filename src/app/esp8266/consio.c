/*
 * Stub I/O subroutines for C Forth 93, supporting only console I/O.
 *
 * Exported definitions:
 *
 * emit(char);                  Output a character
 * n = key_avail();             How many characters can be read?
 * error(s);                    Print a string on the error stream
 * char = key();                Get the next input character
 */

#include "spiffs.h"
#include "forth.h"
#include "compiler.h"

int isinteractive() {  return (1);  }
int isstandalone() {  return (1);  }

void emit(u_char c, cell *up)
{
    (void)putchar((char)c);
}

void cprint(const char *str, cell *up)
{
    while (*str)
        emit((u_char)*str++, up);
}

void title(cell *up)
{
    cprint("C Forth 2005.  Copyright (c) 1997-2005 by FirmWorks\n", up);
}

void read_dictionary(char *name, cell *up) {  FTHERROR("No file I/O\n");  }

void write_dictionary(char *name, int len, char *dict, int dictsize,
                      cell *up, int usersize)
{
    FTHERROR("No file I/O\n");
}

#define MAXNAMELEN 64
cell pfflush(cell f, cell *up) {
  return myspiffs_flush((int)f);
}
cell pfsize(cell f, cell *up) {
  return (cell)myspiffs_size((int)f);
}

void pfmarkinput(void *fp, cell *up) {}
void pfprint_input_stack(void) {}

static spiffs_flags open_modes[] = { SPIFFS_RDONLY, SPIFFS_WRONLY, SPIFFS_RDWR };

cell pfopen(char *name, int len, int mode, cell *up)  {
  char cstrbuf[MAXNAMELEN];
  char *s = altocstr(name, len, cstrbuf, MAXNAMELEN);
  cell ret = myspiffs_open(s, open_modes[mode]);
  // spiffs returns negative number on error, like Unix open(),
  // but pfopen() is supposed to return NULL like fopen()
  return ret<0 ? 0 : ret ;
}

static spiffs_flags create_modes[] = { SPIFFS_CREAT|SPIFFS_APPEND|SPIFFS_RDWR, SPIFFS_CREAT|SPIFFS_TRUNC|SPIFFS_WRONLY, SPIFFS_CREAT|SPIFFS_TRUNC|SPIFFS_RDWR };

cell pfcreate(char *name, int len, int mode, cell *up)  {
  char cstrbuf[MAXNAMELEN];
  char *s = altocstr(name, len, cstrbuf, MAXNAMELEN);
  cell ret = myspiffs_open(s, create_modes[mode]);
  // spiffs returns negative number on error, like Unix open(),
  // but pfopen() is supposed to return NULL like fopen()
  return ret<0 ? 0 : ret ;
}

cell pfclose(cell fd, cell *up) {
  return myspiffs_close((int)fd);
}

cell freadline(cell f, cell *sp, cell *up)        /* Returns IO result */
{
    // Stack: adr len -- actual more?

    u_char *adr = (u_char *)sp[1];
    register cell len = sp[0];

    cell actual;
    int c;
    int err;

    sp[0] = -1;         // Assume not end of file
    myspiffs_clearerr((int)f);

    for (actual = 0; actual < len; ) {
        if ((err = myspiffs_error((int)f)) != 0) {
            sp[1] = actual;
            sp[0] = err;
            return(READFAIL);
        }
        if ((c = myspiffs_getc((int)f)) == EOF) {
            if (actual == 0)
                sp[0] = 0;
            break;
        }
        if (c == CNEWLINE) {    // Last character of an end-of-line sequence
            break;
        }

        // Don't store the first half of a 2-character newline sequence
        if (c == SNEWLINE[0])
            continue;

        *adr++ = c;
        ++actual;
    }

    sp[1] = actual;
    return(0);
}

cell
pfread(cell *sp, cell len, void *fid, cell *up)  // Returns IO result, actual in *sp
{
    *sp = (cell)myspiffs_read((int)fid, (void *)*sp, (size_t)len);
    if (*sp == 0) {
      cell ret = (cell)myspiffs_error((int)fid);
      myspiffs_clearerr((int)fid);
      return ret;
    }
    return 0;
}

cell
pfwrite(void *adr, cell len, void *fid, cell *up)
{
  cell ret = (cell)myspiffs_write((int)fid, adr, (size_t)len);
    if (ret == 0) {
      ret = myspiffs_error((int)fid);
      return ret;
    }
    return 0;
}

void clear_log(cell *up) { }
void start_logging(cell *up) { }
void stop_logging(cell *up) { }
cell log_extent(cell *log_base, cell *up) { *log_base = 0; return 0; }
