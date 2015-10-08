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
#include <regex.h>

int main(argc, argv)
	int argc;
	char *argv[];
{
	FILE *hfile = fopen("glops.h", "w");
	FILE *ffile = fopen("gcalls.fth", "w");

	int callno = 0;

	int res;
	regex_t regex;
//	if ((res = regcomp(&regex, ".*case  *\\([^ :]*\\):  *//g  *\\(.*\\)", REG_EXTENDED)) != 0) {
//	if ((res = regcomp(&regex, "case \\(.*\\):  *//g *\\(.*\\)", REG_EXTENDED)) != 0) {
	if ((res = regcomp(&regex, "  *case  *(.*):  *//g *(.*)$", REG_EXTENDED)) != 0) {
		char errbuf[256];
		regerror(res, &regex, errbuf, 256);
		fprintf(stderr, "%s\n", errbuf);
		return 1;
	}

	char linebuf[256];
	while (!feof(stdin) && fgets(linebuf, 256, stdin)) {
		if (linebuf[strlen(linebuf)-1] == '\n') {
			linebuf[strlen(linebuf)-1] = '\0';
		}
		regmatch_t match[3];
		if (regexec(&regex, linebuf, 3, match, 0) == 0) {
			char identifier[256];
			size_t idlen = match[1].rm_eo - match[1].rm_so;
			strncpy(identifier, linebuf + match[1].rm_so, idlen);
			identifier[idlen] = '\0';
			fprintf(hfile, "#define %s %d\n", identifier, callno);

			char forth[256];
			size_t forthlen = match[2].rm_eo - match[2].rm_so;
			strncpy(forth,      linebuf + match[2].rm_so, forthlen);
			forth[forthlen] = '\0';
			fprintf(ffile, "#%02d gcall: %s\n", callno, forth);

			callno++;
		}
        }
	return(0);
}
