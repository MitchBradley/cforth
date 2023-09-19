// I/O subroutines for C Forth 93.
// This code mostly uses C standard I/O, so it should work on most systems.
//
// Exported definitions:
//
// init_io(argc,argv);		Initialize io system
// emit(char, up);			Output a character
// n = key_avail();		How many characters can be read?
// error(s, up);			Print a string on the error stream
// n = caccept(addr, count);	Collect a line of input
// char = key();		Get the next input character
// name_input(filename);

// newlib configuration to match esp-idf/components/newlib/include/sys/config.h
// If we do not do this, we get linker errors about undefined _impure_ptr
#define __DYNAMIC_REENT__
#define _REENT_SMALL_

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <limits.h>

#include "forth.h"
#include "compiler.h"

int ansi_emit(int c, FILE *fd);
extern int key();
extern void exit();
extern FILE *fopen();

#define STRINGINPUT (FILE *) -1

cell
freadline(cell f, cell *sp, cell *up) // Returns IO result, actual and more? on stack
{
    // Stack: adr len -- actual more?

    u_char *adr = (u_char *)sp[1];
    register cell len = sp[0];

    register cell actual;
    register int c;

    sp[0] = -1;         // Assume not end of file

    for (actual = 0; actual < len; ) {
        if ((c = getc((FILE *)f)) == EOF) {
            if (actual == 0)
                sp[0] = 0;

            if (ferror((FILE *)f)) {
                sp[1] = actual;
                return(READFAIL);
            }
            break;
        }
        if (c == CNEWLINE) {    // Last character of an end-of-line sequence
            break;
        }

        // Don't store the first half of a 2-character newline sequence
        if (c == SNEWLINE[0])
            continue;

        *adr++ = c;
//      printf("%c", c);
        ++actual;
    }
//    printf("\n");


    sp[1] = actual;
    return(0);
}

cell
pfclose(cell f, cell *up)
{
    return( (cell)fclose((FILE *)f) );
}

cell
pfflush(cell f, cell *up)
{
    return( (cell)fflush((FILE *)f) );
}

cell
pfsize(cell f, u_cell *high, u_cell *low, cell *up)
{
    FILE *fd = (FILE *)f;
    long old, end;
    old = ftell(fd);
    fseek(fd, 0L, SEEK_END);
    end = ftell(fd);
    fseek(fd, old, SEEK_SET);
    *high = 0;
    *low = end;
    return((cell)(end==-1 ? SIZEFAIL : 0));
}

char *
expand_name(char *name)
{
  char envvar[64], *fnamep, *envp, paren, *fullp;
  static char fullname[PATH_MAX];
  int ndx;

  strcpy(fullname, "/spiffs/");
  fullp = fullname + strlen(fullname);

  fnamep = name;

  while (*fnamep) {
    if (*fnamep == '$') {
      fnamep++;
      ndx = 0;
      if (*fnamep == '{' || *fnamep == '(') {	// multi char env var
        paren = (*fnamep++ == '{') ? '}' : ')';

        while (*fnamep != paren && ndx < PATH_MAX && *fnamep != '\0') {
          envvar[ndx++] = *(fnamep++);
        }
        if (*fnamep == paren) {
          fnamep++;
        } else {
          ndx = 0;
          fnamep = name;
        }
      } else		/* single char env. var. */
        envvar[ndx++] = *(fnamep++);
      envvar[ndx] = '\0';

      if (ndx > 0 && (envp = getenv(envvar)) != NULL) {
        strcpy(fullp, envp);
        fullp += strlen(envp);
      } else {
        printf("Can't find environment variable %s in %s\n", envvar,name);
        exit(1);
      }
      ndx = 0;
    } else {
      *fullp++ = *fnamep++;
    }
  }
  *fullp = '\0';
  return (fullname);
}

// r/o                Open existing file for reading
// w/o                Open or create file for appending
// r/w                Open existing for reading and writing
// r/o create-flag or Open or create file for appending, read at beginning
// w/o create-flag or ???

// 0:r/o 1:w/o 2:r/w 3: undefined
static char *open_modes[]   = { "rb",  "ab", "r+b", "" };
static char *popen_modes[]  = { "r",  "w", "rw", "" };
cell pfopen(char *name, int len, int mode, cell *up)
{
    char cstrbuf[PATH_MAX];
    char *s = expand_name(altocstr(name, len, cstrbuf, PATH_MAX));

    FILE *res = fopen(s, open_modes[mode&3]);
    return (cell)res;
}

static char *create_modes[] = { "a+b", "wb", "w+b", "" };
cell pfcreate(char *name, int len, int mode, cell *up)
{
    char cstrbuf[512];

    return( (cell)fopen(expand_name(altocstr(name, len, cstrbuf, 512)), create_modes[mode&3]) );
}

cell pfread(cell *sp, cell len, void *fid, cell *up)  // Returns IO result, actual in *sp
{
    size_t ret;
    *sp = (cell)fread((void *)*sp, 1, (size_t)len, (FILE *)fid);

    return (*sp == 0) ? ferror((FILE *)fid) : 0;
}

cell pfwrite(void *adr, cell len, void *fid, cell *up)  // Returns IO result, actual in *sp
{
    size_t ret;
    ret = (cell)fwrite(adr, 1, (size_t)len, (FILE *)fid);

    return (ret == 0) ? ferror((FILE *)fid) : 0;
}

cell pfseek(void *fid, u_cell high, u_cell low, cell *up)
{
  (void)fseek((FILE *)fid, low, 0);
  return 0;
}

cell pfposition(void *fid, u_cell *high, u_cell *low, cell *up)
{
  *low = ftell((FILE *)fid);
  *high = 0;
  return 0;
}

void clear_log(cell *up) { }
void start_logging(cell *up) { }
void stop_logging(cell *up) { }
cell log_extent(cell *log_base, cell *up) { *log_base = 0; return 0; }

void pfmarkinput(void *fp, cell *up) {}
void pfprint_input_stack(void) {}

void read_dictionary(char *name, cell *up) {  FTHERROR("read_dictionary unsupported\n");  }

void write_dictionary(char *name, int len, char *dict, int dictsize,
                      cell *up, int usersize)
{
  FTHERROR("write_dictionary unsupported\n");
}
