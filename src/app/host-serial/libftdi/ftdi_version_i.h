// This file is supposed to be generated automatically by building libftdi,
// but building libftdi requires a huge collection of tools that we really
// don't care about.  So instead of building the library we just compile
// the one source file that we do want, which is ftdi.c, and we cache this
// include file here.
#ifndef FTDI_VERSION_INTERNAL_H
#define FTDI_VERSION_INTERNAL_H

#define FTDI_MAJOR_VERSION 1
#define FTDI_MINOR_VERSION 2
#define FTDI_MICRO_VERSION 0

const char FTDI_VERSION_STRING[] = "1.2";
const char FTDI_SNAPSHOT_VERSION[] = "v1.2-1-g3e078e1";

#endif
