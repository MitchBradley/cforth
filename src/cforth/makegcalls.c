/*
 * Extracts Forth ccall definitions from a C source file
 *
 * Reads stdin looking for lines like:
 *	case GLFOO: //c gl-foo  { a.adr i.fh -- i.error }
 *
 * Writes to glops.h lines like:
 *      #define GLFOO nn
 *
 * Writes to gcalls.fth lines like:
 *	#nn gcall: gl-foo  { a.adr i.fh -- i.error }
 */

#include <stdio.h>
#include <string.h>

int main(argc, argv)
	int argc;
	char *argv[];
{
	FILE *hfile = fopen("glops.h", "w");
	FILE *ffile = fopen("gcalls.fth", "w");

	int callno = 0;

	while (!feof(stdin)) {
		char linebuf[256];
		char identifier[256];
		char forth[256];
		int res;
		res = fscanf(stdin, " case %[^:]: //g %[^\n]\n", identifier, forth);
		if (res == 0) {
			fgets(linebuf, 256, stdin);
			continue;
		}
		if (res == EOF) {
			return 0;
		}
		if (res == 1) {
			fprintf(hfile, "#define %s %d\n", identifier, callno);
			callno++;
		}
		if (res == 2) {
			fprintf(hfile, "#define %s %d\n", identifier, callno);
			fprintf(ffile, "#%02d gcall: %s\n", callno, forth);
			callno++;
		}
        }
	return(0);
}
