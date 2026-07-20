// I/O subroutines for C Forth 93.
// This code mostly uses C standard I/O, so it should work on most systems.
//
// Exported definitions:
//
// init_io(argc,argv);		Initialize io system
// emit(char, up);		Output a character
// n = key_avail();		How many characters can be read?
// error(s, up);		Print a string on the error stream
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
#include <fcntl.h>
#include <errno.h>

#include "forth.h"
#include "compiler.h"

static char path[16] = "/esp-32/";
static char *expand_name(char *name);

int ansi_emit(int c, FILE *fd);
extern int key();
extern void exit();
extern FILE *fopen();

#define STRINGINPUT (FILE *) -1

cell freadline(cell f, cell *sp, cell *up)
{
    // Stack input:  sp[0] = len, sp[1] = buffer address
    // f = file handle
    // Returns: actual more? ior  (sp adjusted: actual, more?)
    
    u_char *adr = (u_char *)sp[1];
    cell len = sp[0];
    cell actual = 0;
    int c;
    
    // Assume more data available (true= -1 in Forth)
    sp[0] = -1;  // more? = true (-1)
    
    for (actual = 0; actual < len; actual++) {
        c = getc((FILE *)f);
        
        if (c == EOF) {
            if (actual == 0) {
                sp[0] = 0;  // more? = false (0), no data anymore
            }
            
            if (ferror((FILE *)f)) {
                sp[1] = actual;  // actual bytes read
                return -EIO;     // I/O error
            }
            
            // EOF zonder error
            break;
        }
        
        // Check for newline
        if (c == '\n') {
            // We read the newline but don't store it
            break;
        }
        
        // Skip carriage return
        if (c == '\r') {
            actual--;  // Don't count this character
            continue;
        }
        
        // Store character
        *adr++ = (u_char)c;
    }
    
    sp[1] = actual;  // actual bytes read (without newline)
    return 0;        // ior = 0 (success)
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


static char *expand_name(char *name);
static char *create_modes[] = { "a+b", "wb", "w+b", "" };

static char *expand_name(char *name)
{
    static char fullname[PATH_MAX];
    // Absolute path
    if (strncmp(name, "/sdcard/", 8) == 0 || strncmp(name, "/esp-32/", 8) == 0)
        return name;
    // Relatief path
    snprintf(fullname, PATH_MAX, "%s%s", path, name);
    return fullname;
}

// r/o                Open existing file for reading only
// r/w or w/o         Open existing file for reading and writing at beginning
// r/w create-file    Open or create file for reading and writing (truncates if exists)

cell pfopen(char *name, int len, int mode, cell *up)
{
    char cstrbuf[PATH_MAX];
    if (mode == -9) {
        if (len == 0) return (cell)path;  // GET path
        if (len < 0) {    // SET path of expand
            char *exp = expand_name(altocstr(name, -len, cstrbuf, PATH_MAX));
            if (strcmp(exp, "/sdcard/") == 0 || strcmp(exp, "/esp-32/") == 0)
                strncpy(path, exp, sizeof(path)-1);
            return (cell)exp;
        }
    }
    char *fullpath = expand_name(altocstr(name, len, cstrbuf, PATH_MAX));
    static const char *c_modes[] = {
        [0] = "rb",
        [1] = "r+b",
        [2] = "r+b",
        [3] = "w+b"
    };
    if ((mode & 3) != 3) {  // Only create mode (3) does not need to exist
        struct stat st;
        if (stat(fullpath, &st) == -1) return 0;
    }
    FILE *fp = fopen(fullpath, c_modes[mode & 3]);
    if (!fp) return 0;
    if ((mode & 3) == 1 || (mode & 3) == 2)
        fseek(fp, 0, SEEK_SET);
    return (cell)fp;
}

cell pfcreate(char *name, int len, int mode, cell *up)
{
    char cstrbuf[512];
    char *fullpath = expand_name(altocstr(name, len, cstrbuf, 512));
    FILE *fp = fopen(fullpath, create_modes[mode & 3]);
    return (cell)fp;
}

cell pfread(cell *sp, cell len, void *fid, cell *up)  // Returns IO result, actual in *sp
{
//    size_t ret;
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
