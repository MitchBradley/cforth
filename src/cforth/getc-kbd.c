#include <stdio.h>
int key()  {  return(getc(stdin));  }
int key_avail() { return 0;  }
int ansi_emit(int c, FILE *fd) { return -1; }
