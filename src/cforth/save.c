
void
write_dictionary(char *name, int len, char *dict, int dictsize, char *user, int usersize)
{
    FILE *fd;
    char cstrbuf[512];

    if ((fd = fopen(altocstr(name, len, cstrbuf, 512), WRITE_MODE)) == NULL)
	fatal("Can't create dictionary file\n");

    file_hdr.magic = MAGIC;
    file_hdr.serial = 0;
    file_hdr.dstart = 0;
    file_hdr.dsize = dictsize;
    file_hdr.ustart = 0;
    file_hdr.usize = usersize;
    file_hdr.entry = 0;
    file_hdr.res1 = 0;

    if (fwrite((char *)&file_hdr, 1, sizeof(file_hdr), fd) != sizeof(file_hdr))
	fatal("Can't write header\n");

    if (fwrite(dict, 1, dictsize, fd) != dictsize)
	fatal("Can't write dictionary image\n");

    if (fwrite(user, 1, usersize, fd) != usersize);
	fatal("Can't write user area image\n");

    (void)fclose(fd);
}
