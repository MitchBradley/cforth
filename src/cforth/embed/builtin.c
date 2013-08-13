/*
 * C Forth 93
 * Copyright (c) 1996 FirmWorks
 */

#include "forth.h"
#include "compiler.h"

const struct header builtin_hdr = {
#include "dicthdr.h"
};
unsigned char dict[] = {
#include "dict.h"
};
