// Forth interfaces to SPIFFS FLASH filesystem

#include "forth.h"
#include "compiler.h"
#include "stdio.h"

#include "esp_stdint.h"
#include "arch/cc.h"
#define NODEMCU_SPIFFS_NO_INCLUDE  // Prevents stdint type collisions
#include "spiffs.h"

extern spiffs fs;

void read_dictionary(char *name, cell *up) {  FTHERROR("No file I/O\n");  }

void write_dictionary(char *name, int len, char *dict, int dictsize,
                      cell *up, int usersize)
{
  FTHERROR("No file I/O\n");
}

#define MAXNAMELEN 64
cell pfflush(cell f, cell *up) {
  return SPIFFS_fflush(&fs, (spiffs_file)f);
}

cell pfsize(cell f, u_cell *high, u_cell *low, cell *up) {
  int32_t curpos = SPIFFS_tell(&fs, (spiffs_file)f);
  int32_t size = SPIFFS_lseek(&fs, (spiffs_file)f, 0, SPIFFS_SEEK_END);
  (void) SPIFFS_lseek(&fs, (spiffs_file)f, curpos, SPIFFS_SEEK_SET);
  *high = 0;
  *low = size;
  return (cell)0;  // SPIFFS_tell has no error returns
}

void pfmarkinput(void *fp, cell *up) {}
void pfprint_input_stack(void) {}

static spiffs_flags open_modes[] = { SPIFFS_RDONLY, SPIFFS_WRONLY, SPIFFS_RDWR };

cell pfopen(char *name, int len, int mode, cell *up)  {
  char cstrbuf[MAXNAMELEN];
  char *s = altocstr(name, len, cstrbuf, MAXNAMELEN);
  cell ret = SPIFFS_open(&fs, s, (spiffs_flags)open_modes[mode], 0);
  // spiffs returns negative number on error, like Unix open(),
  // but pfopen() is supposed to return NULL like fopen()
  return ret<0 ? 0 : ret ;
}

static spiffs_flags create_modes[] = { SPIFFS_CREAT|SPIFFS_APPEND|SPIFFS_RDWR, SPIFFS_CREAT|SPIFFS_TRUNC|SPIFFS_WRONLY, SPIFFS_CREAT|SPIFFS_TRUNC|SPIFFS_RDWR };

cell pfcreate(char *name, int len, int mode, cell *up)  {
  char cstrbuf[MAXNAMELEN];
  char *s = altocstr(name, len, cstrbuf, MAXNAMELEN);
  cell ret = SPIFFS_open(&fs, s, (spiffs_flags)create_modes[mode], 0);
  // spiffs returns negative number on error, like Unix open(),
  // but pfopen() is supposed to return NULL like fopen()
  return ret<0 ? 0 : ret ;
}

cell pfclose(cell fd, cell *up) {
  return SPIFFS_close(&fs, (spiffs_file)fd);
}

cell freadline(cell f, cell *sp, cell *up)        /* Returns IO result */
{
  // Stack: adr len -- actual more?

  u_char *adr = (u_char *)sp[1];
  register cell len = sp[0];

  cell actual;
  u_char c;
  int err;

  sp[0] = -1;         // Assume not end of file
  SPIFFS_clearerr(&fs);

  for (actual = 0; actual < len; ) {
    if ((err = SPIFFS_errno(&fs) != 0)) {
      sp[1] = actual;
      sp[0] = err;
      return(READFAIL);
    }
    if (SPIFFS_eof(&fs, (spiffs_file)f)) {
      if (actual == 0)
	sp[0] = 0;
      break;
    }	  
    if (SPIFFS_read(&fs, (spiffs_file)f, &c, 1) != 1) {
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
  *sp = (cell)SPIFFS_read(&fs, (spiffs_file)(int)fid, (void *)*sp, (size_t)len);
  if (*sp < 0) {
    *sp = 0;
    cell ret = (cell)SPIFFS_errno(&fs);
    SPIFFS_clearerr(&fs);
    return ret;
  }
  return 0;
}

cell
pfwrite(void *adr, cell len, void *fid, cell *up)
{
  cell ret = (cell)SPIFFS_write(&fs, (spiffs_file)(int)fid, adr, (size_t)len);
  if (ret < 0) {
    return SPIFFS_errno(&fs);
  }
  return 0;
}

cell
pfseek(void *fid, u_cell high, u_cell low, cell *up)
{
  (void)SPIFFS_lseek(&fs, (spiffs_file)(int)fid, low, 0);
  return 0;
}

cell
pfposition(void *fid, u_cell *high, u_cell *low, cell *up)
{
  *low = SPIFFS_tell(&fs, (spiffs_file)(int)fid);
  *high = 0;
  return 0;
}

void clear_log(cell *up) { }
void start_logging(cell *up) { }
void stop_logging(cell *up) { }
cell log_extent(cell *log_base, cell *up) { *log_base = 0; return 0; }


extern spiffs fs;

void rename_file(char *new, char *old)
{
  SPIFFS_rename(&fs, old, new);
}
cell fs_avail(void)
{
  u32_t total, used;
  SPIFFS_info(&fs, &total, &used);
  return (cell)(total - used);
}

void delete_file(char *path)
{
  SPIFFS_remove(&fs, path);
}

static struct spiffs_dirent dirent;
static spiffs_DIR dir;
struct spiffs_dirent *next_file(void)
{
  struct spiffs_dirent *dp = &dirent;
  while ((dp = SPIFFS_readdir(&dir, dp)) != NULL) {
    if (dp->type == SPIFFS_TYPE_FILE) {
      return dp;
    }
  }
  return 0;
}
struct spiffs_dirent *first_file(void)
{
  if (SPIFFS_opendir(&fs, "", &dir))
    return next_file();
  return 0;
}

cell dirent_size(struct spiffs_dirent *d)
{
  return d->size;
}

cell dirent_name(struct spiffs_dirent *d)
{
  return (cell)(d->name);
}
