#ifdef notdef
/*
 * Automatically generates the primitive number include file and the
 * corresponding Forth dictionary initialization file.
 *
 * Reads  "forth.ip" looking for lines like:
 *	/*$p not */  case NOT:
 *
 * Creates "init.x" dictionary initialization file with lines like:
 *	p not
 *
 * Creates "prims.h" include file with sequentially-numbered lines like:
 *	#define NOT 12
 *
 */
#endif

#include <stdio.h>

int
main(argc, argv)
	int argc;
	char *argv[];
{
	FILE *ffd;	/* forth.c */
	FILE *ifd;	/* init.x */
	FILE *pfd;	/* prims.h */
	FILE *vfd;	/* vars.h */

	int c;
	int lastc;
	int primtype;
	int primno = 1;
	int varno  = 1;  // Var 0 is the threads for the forth vocabulary
	int nvocs  = 1;
	int cfseen = 0;

    if (argc != 2) {
		fprintf(stderr, "Usage: makename filename\n");
		return(1);
    }

	if ((ffd = fopen(argv[1], "r")) == NULL) {
		perror("makename: input file");
		return(1);
	}

	if ((ifd = fopen("init.x",  "w")) == NULL) {
		perror("makename: init.x");
		return(1);
	}

	if ((pfd = fopen("prims.h", "w")) == NULL) {
		perror("makename: prims.h");
		return(1);
	}

	if ((vfd = fopen("vars.h",  "w")) == NULL) {
		perror("makename: vars.h");
		return(1);
	}
    fprintf(vfd, "// 'forth' vocabulary threads are at index 0\n");

	for ( ; (c = fgetc(ffd)) != EOF; lastc = c) {
		if (lastc != '*' || c != '$')
			continue;

		/* Copy out e.g. "p not" */
		primtype=fgetc(ffd);	/* 'p','i','c','u','U','t' */
		if (primtype == 'c' && !cfseen) {
			fprintf(pfd, "#define\tMAXPRIM\t%d\n", primno);
			cfseen = 1;
		}

		if (primtype == 'U') {	/* Allocate unnamed user locations */
			do {
				nvocs++;
				varno++;
				primtype = fgetc(ffd);
			
			} while (primtype == 'U');
			continue;
		}
		fputc(primtype, ifd);
		fputc(fgetc(ffd), ifd);	/* ' ' */
		while ((c = fgetc(ffd)) != ' ') {
			/*
			 * The forth word times-divide-mod looks like
			 * the end of a C comment, so we write its
			 * '*' character as '%' in forth.c .
			 */
			if (c == '%')
				c = '*';
			fputc(c,ifd);
		}
		fputc('\n', ifd);

		/* Search for "case " */
		while ((c = fgetc(ffd)) != 'e')
			;
		(void)fgetc(ffd);			/* Eat ' ' */

		if (primtype == 'u' || primtype == 't' || primtype == 'd') {
			/* Write, for example    #define LAST 12   */
			fputs("#define\t", vfd);
			while ((c = fgetc(ffd)) != ':')	/* Copy name */
				fputc(c,vfd);

			fprintf(vfd, "\t%d\n", varno++);
		} else {
			/* Write, for example    #define NOT 12   */
			fputs("#define\t", pfd);
			while ((c = fgetc(ffd)) != ':')	/* Copy name */
				fputc(c,pfd);

			fprintf(pfd, "\t%d\n", primno++);
		}
	}
	fprintf(vfd, "#define\tNVOCS\t%d\n", nvocs);
	fprintf(vfd, "#define\tNEXT_VAR\t%d\n", varno);
	fprintf(pfd, "#define\tMAXCF\t%d\n", primno);
	fprintf(ifd, "e\n");	/* End of list code */
	fclose(ffd);
	fclose(ifd);
	fclose(pfd);

	return(0);
}
