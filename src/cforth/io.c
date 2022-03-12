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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include "forth.h"
#include "compiler.h"

int ansi_emit(int c, FILE *fd);
extern int key();
extern void exit();
extern FILE *fopen();

FILE *input_file;
FILE *output_file;
FILE *open_next_file();

int gargc;
char **gargv;

// The following input-marking mechanism maintains the path name
// for the current input file so that relative paths can be based
// on the path to the current input file.
// It works as follows:
// Whenever a file is opened:
// a) If its name is relative, the name is appended to the directory
//    name of the current input file.
// b) Its full path is recorded in a open file list.
// If a file is then used for interpreter input its path record

// is moved from the open file list and pushed on a stack of input
// files.  The top of that stack is the current input file.
// When a file is closed its record is removed from whichever
// list or stack it is on.

typedef struct filepath {
    struct filepath *next;
    FILE *fp;
    char *path;
} filepath_t;

void free_filepath(filepath_t *p)
{
    free(p->path);
    free(p);
}

filepath_t filepaths = { NULL, NULL, NULL } ;
filepath_t input_stack = { NULL, NULL, NULL } ;

static filepath_t *remove_path(FILE *fp)
{
    filepath_t *prev, *this;

    for (prev = &filepaths; (this = prev->next) != NULL; prev = this) {
        if (this->fp == fp) {
            prev->next = this->next;  // Unlink
            return this;
        }
    }
    return NULL;
}

void delete_path(FILE *fp)
{
    filepath_t *this = remove_path(fp);
    if (this) {
        free_filepath(this);
    }
}

// Pushes the path record for fp onto the input stack
void pfmarkinput(void *fp, cell *up)
{
    filepath_t *this = remove_path((FILE *)fp);
    if (this) {
        this->next = input_stack.next;
        input_stack.next = this;
    }
}

void pfprint_input_stack(void)
{
    filepath_t *this;

    for (this = input_stack.next; this; this = this->next) {
        printf("%s\n", this->path);
    }
}

void delete_input(FILE *fp)
{
    filepath_t *prev, *this;

    for (prev = &input_stack; (this = prev->next) != NULL; prev = this) {
        if (this->fp == fp) {
            if (prev != &input_stack) {
                printf("Warning - funny file unnesting\n");
            }
            prev->next = this->next;  // Unlink
            free_filepath(this);
            return;
        }
    }
}

char *input_dir(size_t *len)
{
    *len = 0;
    if (input_stack.next) {
        char *input_path = input_stack.next->path;

        char *end1 = strrchr(input_path, '/');
        char *end2 = strrchr(input_path, '\\');
        if (end2 > end1) {
            end1 = end2;
        }
        if (end1) {
            *len = 1 + end1 - input_path;
        }
        return input_path;
    } else {
        char *wd = getcwd(NULL, 0);
        char *wpath = malloc(strlen(wd) + 2);
        strcpy(wpath, wd);
        free(wd);
        strcat(wpath, "/");
        *len = strlen(wpath);
        return wpath;
    }
}

// absolute paths begin with '/' or '\\' or e.g. "C:\"
int isabsolute(char *name)
{
    if (!name)
        return 0;
    if (*name == '/' || *name == '\\')
        return 1;
    if ((strlen(name) > 2) && name[1] == ':' && (name[2] == '/' || name[2] == '\\'))
        return 1;
    return 0;
}

// Given a filename name, return its absolute path.  If name is already
// absolute, there is no more to be done.  Otherwise, append name to
// the path of the current input.
char *make_path(char *name)
{
    if (isabsolute(name)) {
        return strdup(name);
    }

    // input_dir() includes the final '/' if len is nonzero
    size_t len;
    char *current = input_dir(&len);
    if (len == 0) {
        printf("Warning - empty base path\n");
        return strdup(current);
    }

    char *new = malloc(len + strlen(name) + 1);
    strncpy(new, current, len);
    strcpy(new+len, name);
    return new;
}

void add_path(FILE *fp, char *name)
{
    filepath_t *new = malloc(sizeof(filepath_t));
    new->fp = fp;
    new->next = filepaths.next;
    filepaths.next = new;
    new->path = make_path(name);
}

#define STRINGINPUT (FILE *) -1

int isinteractive()
{
    if ( input_file == STRINGINPUT )
	return 0;
    return isatty(fileno(input_file));
}

int isstandalone() { return 0; }

void title(cell *up)
{
    cprint("C Forth ", up);
    cprint(" Copyright (c) 2008 FirmWorks\n", up);
}

void init_io(int argc, char **argv, cell *up)
{
    gargc = argc; gargv = argv;

    output_file = stdout;

    if (gargc <= 1) {
        input_file = stdin;
        title(up);
    } else {
        input_file = open_next_file(up);
    }
    if (input_file == (FILE *)0) {
        FTHERROR("No input stream\n");
        exit(1);
    }
}

static int logging = 0;
static u_char *log_buf = NULL;
static size_t log_index = 0;
static size_t log_buf_size = 0;
static const int log_increment = 0x4000;
void log_char(u_char c)
{
    if (!logging) {
        return;
    }
    if (log_index == log_buf_size) {
        u_char *new_log_buf;
        new_log_buf = realloc(log_buf, log_buf_size + log_increment);
        if (new_log_buf) {
            log_buf = new_log_buf;
            log_buf_size += log_increment;
            log_buf[log_index++] = c;
        } else {
            // Do nothing; just leave things as-is
        }
    } else {
        log_buf[log_index++] = c;
    }
}

void stop_logging(cell *up)
{
    logging = 0;
}

void start_logging(cell *up)
{
    logging = 1;
}

void clear_log(cell *up)
{
    free(log_buf);
    log_buf = NULL;
    log_buf_size = 0;
    log_index = 0;
}

cell log_extent(cell *log_base, cell *up)
{
    *log_base = (cell)log_buf;
    return log_index;
}

void emit(u_char c, cell *up)
{
    log_char(c);

    if (output_file) {
	if (ansi_emit(c, output_file) == -1) {
	    (void)putc((char)c, output_file);
	    if ( c == '\r')
		(void)fflush(output_file);
	}
    }
}

void cprint(const char *str, cell *up)
{
    while (*str)
        emit((u_char)*str++, up);
    (void)fflush(output_file);
}

void alerror(char *str, int len, cell *up)
{
    (void)fwrite(str, 1, len, stdout);
    (void)fflush(stdout);
    // Sequences of calls to error() eventually end with a newline
    V(NUM_OUT) = 0;
}

char *strptr;

int
nextchar()
{
    register int c;
    unsigned char cchar;

    if ( input_file == STRINGINPUT ) {
        if( (c = *strptr) != '\0') {
            strptr++;
            return (c);
        }
        return (EOF);
    }

    return(getc(input_file));
}

int
moreinput(cell *up)
{
    if ( input_file == STRINGINPUT )
        return (*strptr != '\0');

    return (!feof(input_file));
}

int
caccept(char *addr, cell count, cell *up)
{
    int len;

    if (isinteractive()) {
	len = lineedit(addr, count, up);
    } else {
	/* The line is coming from a file or memory; just find the line end */
	int c;
	char *p;
	for (p = addr; count > 0; count--) {
	    c = nextchar();
	    if (c == '\n' || c == EOF) {
		break;
	    }
	    *p++ = c;
	}
	len = ((cell)(p - addr));
    }

    V(NUM_OUT) = 0;
    return len;
}

void file_error(char *str, char *filename, cell *up)
{
    extern size_t strlen(const char *);

    alerror(str, strlen(str), up);
    alerror(filename, strlen(filename), up);
    FTHERROR("\n");
}

void name_input(char *filename, cell *up)
{
    FILE *file;

    if ((file = fopen(filename, "r")) == (FILE *)0) {
        file_error("Can't open ", filename, up);
    } else {
        add_path(file, filename);
        pfmarkinput(file, up);
        input_file = file;
    }
}

FILE *
open_next_file(cell *up)
{
    register FILE * file;

    while (--gargc > 0) {
        if ( (*++gargv)[0]=='-' ) {
            if ((*gargv)[1]=='\0') {
                return(stdin);
            } else if ((*gargv)[1] == 's') {
                char *p;

                ++gargv; --gargc;
                strptr = *gargv;
                return(STRINGINPUT);
            } else {
                file_error("Unknown flag ",*gargv, up);
            }
        }
        else {
            if ((file = fopen(*gargv, "r")) == (FILE *)0) {
                file_error("Can't open ",*gargv, up);
                continue;
            } else {
                add_path(file, *gargv);
                pfmarkinput(file, up);
                return(file);
            }
        }
    }
    return((FILE *)0);
}

int
next_arg(cell *up)
{
    if (input_file && input_file != STRINGINPUT && !isinteractive()) {
        pfclose((cell)input_file, up);
    }
    input_file = open_next_file(up);
    return input_file != (FILE *)0;
}

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
    delete_input((FILE *)f);
    delete_path((FILE *)f);
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

#define MAXPATHLEN 2048
char *
expand_name(char *name)
{
  char envvar[64], *fnamep, *envp, paren, *fullp;
  static char fullname[MAXPATHLEN];
  int ndx;

  fullp = fullname;
  fullname[0] = '\0';

  fnamep = name;

  while (*fnamep) {
    if (*fnamep == '$') {
      fnamep++;
      ndx = 0;
      if (*fnamep == '{' || *fnamep == '(') {	// multi char env var
        paren = (*fnamep++ == '{') ? '}' : ')';

        while (*fnamep != paren && ndx < MAXPATHLEN && *fnamep != '\0') {
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
    char cstrbuf[MAXPATHLEN];
    char *s = expand_name(altocstr(name, len, cstrbuf, MAXPATHLEN));

    if (!strncmp("popen:", s, 6)) {
	FILE *stream;
	stream = popen(s+6, popen_modes[mode&3]);
	setbuf(stream, 0);
        return (cell)stream;
    }

    if (!isabsolute(s)) {
        char absbuf[MAXPATHLEN];
        size_t len;
        char *current = input_dir(&len);
        if (len) {
            strncpy(absbuf, current, len);
            strcpy(absbuf+len, s);
            s = absbuf;
        }
    }

    FILE *res = fopen(s, open_modes[mode&3]);
    if (res) {
        add_path(res, s);
    }
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
