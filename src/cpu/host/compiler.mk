# Compiler specification for the case where the compilation host
# and target are the same

TCC=$(CC)
TLD=$(LD)
LIBDIRS=-L$(dir $(shell $(TCC) -print-libgcc-file-name))

TOBJDUMP=objdump
TOBJCOPY=objcopy
