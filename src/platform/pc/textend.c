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
    C(pcfetch)  //c pc@        { i.port -- i.byte }
    C(pcstore)  //c pc!        { i.byte i.port -- }
    C(pwfetch)  //c pw@        { i.port -- i.word }
    C(pwstore)  //c pw!        { i.word i.port -- }
    C(plfetch)  //c pl@        { i.port -- i.long }
    C(plstore)  //c pl!        { i.long i.port -- }
    C(cbfetch)  //c config-b@  { i.cfgadr -- i.byte }
    C(cbstore)  //c config-b!  { i.byte i.cfgadr -- }
    C(cwfetch)  //c config-w@  { i.cfgadr -- i.word }
    C(cwstore)  //c config-w!  { i.word i.cfgadr -- }
    C(clfetch)  //c config-l@  { i.cfgadr -- i.word }
    C(clstore)  //c config-l!  { i.long i.cfgadr -- }
};
