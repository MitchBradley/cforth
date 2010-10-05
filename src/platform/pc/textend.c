// Edit this file to include C routines that can be called as Forth words.
// See "ccalls" below.

#include <io.h>

// This is the only thing that we need from forth.h
#define cell long

// Prototypes

cell pcfetch(cell port);
void pcstore(cell port, cell value);
cell pwfetch(cell port);
void pwstore(cell port, cell value);
cell plfetch(cell port);
void plstore(cell port, cell value);
cell cbfetch(cell port);
void cbstore(cell port, cell value);
cell cwfetch(cell port);
void cwstore(cell port, cell value);
cell clfetch(cell port);
void clstore(cell port, cell value);

cell pcfetch(cell port)
{
    return inb(port);
}

void pcstore(cell port, cell value)
{
    outb(value, port);
}

cell pwfetch(cell port)
{
    return inw(port);
}

void pwstore(cell port, cell value)
{
    outw(value, port);
}

cell plfetch(cell port)
{
    return inl(port);
}

void plstore(cell port, cell value)
{
    return outl(value, port);
}

#define CFG_SETUP(cfgadr) outl((cfgadr | 0x80000000) & ~3, 0xcf8)
#define CFG_DATA(cfgadr) (0xcfc + (cfgadr&3))

cell cbfetch(cell cfgadr)
{
    CFG_SETUP(cfgadr);
    return inb(CFG_DATA(cfgadr));
}

void cbstore(cell cfgadr, cell value)
{
    CFG_SETUP(cfgadr);
    outb(value, 0xcfc + (cfgadr&3));
}

cell cwfetch(cell cfgadr)
{
    CFG_SETUP(cfgadr);
    return inw(CFG_DATA(cfgadr));
}

void cwstore(cell cfgadr, cell value)
{
    CFG_SETUP(cfgadr);
    outw(value, CFG_DATA(cfgadr));
}

cell clfetch(cell cfgadr)
{
    CFG_SETUP(cfgadr);
    return inl(CFG_DATA(cfgadr));
}

void clstore(cell cfgadr, cell value)
{
    CFG_SETUP(cfgadr);
    outl(value, CFG_DATA(cfgadr));
}

cell ((* const ccalls[])()) = {
    (cell (*)())pcfetch,      // Entry # 0
    (cell (*)())pcstore,      // Entry # 1
    (cell (*)())pwfetch,      // Entry # 2
    (cell (*)())pwstore,      // Entry # 3
    (cell (*)())plfetch,      // Entry # 4
    (cell (*)())plstore,      // Entry # 5
    (cell (*)())cbfetch,      // Entry # 6
    (cell (*)())cbstore,      // Entry # 7
    (cell (*)())cwfetch,      // Entry # 8
    (cell (*)())cwstore,      // Entry # 9
    (cell (*)())clfetch,      // Entry # 10
    (cell (*)())clstore,      // Entry # 11
};
