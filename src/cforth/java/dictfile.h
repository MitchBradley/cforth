#define MAGIC 0x581120

#ifndef JAVA
struct header {
	cell magic, serial, dstart, dsize, ustart, usize, entry, res1;
};
extern struct header file_hdr;
extern const struct header builtin_hdr;
#endif
