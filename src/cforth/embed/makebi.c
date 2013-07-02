#include <stdio.h>
#include <stdlib.h>

int
test_little_endian()
{
    long cell = 1;
    return *(char *)&cell == 1;
}

longs_to_file(char *filename, FILE *infile, int len, int *dsizep, int *usizep)
{
    FILE *outfile;
    int val;
    int le;
    int i;

    if ((outfile = fopen(filename, "w")) == 0) {
        fprintf(stderr, "Can't open output file %s\n", filename);
        exit(1);
    }

    le = test_little_endian();

    for (i=0; i<8; i++) {
        if (le) {
            val  =  (unsigned char)fgetc(infile);
            val |= ((unsigned char)fgetc(infile) << 8);
            val |= ((unsigned char)fgetc(infile) << 16);
            val |= ((unsigned char)fgetc(infile) << 24);
        } else {
            val  = ((unsigned char)fgetc(infile) << 24);
            val |= ((unsigned char)fgetc(infile) << 16);
            val |= ((unsigned char)fgetc(infile) << 8);
            val |=  (unsigned char)fgetc(infile);
        }
        if (i == 3) {
            *dsizep = val;
        }
        if (i == 5) {
            *usizep = val;
        }
        fprintf(outfile, "0x%08x, ", val);
    }
    fputc('\n', outfile);
    fclose(outfile);
}

void
bytes_to_file(char *filename, FILE *infile, int len)
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

main(argc, argv)
    int argc;
    char **argv;
{
    char *dictionary_file;
    FILE *infile;
    int dictsize, uasize;

    if(argc != 2)
        dictionary_file = "forth.dic";
    else
        dictionary_file = argv[1];

    if ((infile = fopen(dictionary_file, "r")) == 0) {
        fprintf(stderr, "Can't open input file %s\n", dictionary_file);
        exit(1);
    }

    longs_to_file("dicthdr.h", infile, 8, &dictsize, &uasize);
    bytes_to_file("dict.h", infile, dictsize);
    bytes_to_file("userarea.h", infile, uasize);

    fclose(infile);
    exit(0);
}
