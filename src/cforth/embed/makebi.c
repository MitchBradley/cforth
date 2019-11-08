#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include "config.h"

int
test_little_endian()
{
    long cell = 1;
    return *(char *)&cell == 1;
}

void cells_to_file(char *filename, FILE *infile, int len, u_cell *dsizep, u_cell *usizep)
{
    FILE *outfile;
    u_cell val;
    int le;
    int i, j;

    if ((outfile = fopen(filename, "w")) == 0) {
        fprintf(stderr, "Can't open output file %s\n", filename);
        exit(1);
    }

    le = test_little_endian();

    for (i=0; i<8; i++) {
        val = 0;
        for (j=0; j<sizeof(val); j++) {
            if (le) {
                val = (val>>8) | ((u_cell)(unsigned char)fgetc(infile) << ((sizeof(val) - 1)*8));
            } else {
                val = (val<<8) | (unsigned char)fgetc(infile);
            }
        }
        if (i == 3) {
            *dsizep = val;
        }
        if (i == 5) {
            *usizep = val;
        }
        fprintf(outfile, "0x%" PRIxPTR ", ", val);
    }
    fputc('\n', outfile);
    fclose(outfile);
}

void bytes_to_file(char *filename, FILE *infile, int len)
{
    int i;
    int c;
    FILE *outfile;

    if ((outfile = fopen(filename, "w")) == 0) {
        fprintf(stderr, "Can't open output file %s\n", filename);
        exit(1);
    }
    for (i = 0; i < len; i++) {
        c = fgetc(infile);
        if (c == EOF) {
            fprintf(stderr, "Short read from %s\n", filename);
            exit(1);
        }
        fprintf(outfile, "0x%02x, ", c);
        if ((i&7) == 7) {
            fputc('\n', outfile);
        }
    }
    if ((i&7) != 0) {
        fputc('\n', outfile);
    }
    fclose(outfile);
}

int main(argc, argv)
    int argc;
    char **argv;
{
    char *dictionary_file;
    FILE *infile;
    //    int dictsize, uasize;
    u_cell dictsize, uasize;

    if(argc != 2)
        dictionary_file = "forth.dic";
    else
        dictionary_file = argv[1];

    if ((infile = fopen(dictionary_file, "rb")) == 0) {
        fprintf(stderr, "Can't open input file %s\n", dictionary_file);
        exit(1);
    }

    cells_to_file("dicthdr.h", infile, 8, &dictsize, &uasize);
    bytes_to_file("dict.h", infile, dictsize);
    bytes_to_file("userarea.h", infile, uasize);

    if (fgetc(infile) != EOF) {
        fprintf(stderr, "Extra data in the input file %s\n", dictionary_file);
        exit(1);
    }

    fclose(infile);
    return 0;
}
