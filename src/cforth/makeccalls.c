/*
 * Extracts Forth ccall definitions from a C source file
 *
 * Reads stdin looking for lines like:
 *	//c mmap { a.adr i.fh -- i.error }
 *
 * Writes to stdout lines like:
 *	#nn ccall: mmap { a.adr i.fh -- i.error }
 */

#include <stdio.h>
#include <string.h>

int main(argc, argv)
	int argc;
	char *argv[];
{
	char linebuf[256];

	int ccallno = 0;

	char *tag = "//c ";
	while (!feof(stdin) && fgets(linebuf, 256, stdin)) {
		char *loc = strstr(linebuf, tag);
		if (loc) {
			printf("#%d ccall: %s", ccallno++, loc+strlen(tag));
                }
        }

	return(0);
}
