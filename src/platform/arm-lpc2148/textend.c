// Edit this file to include C routines that can be called as Forth words.
// See "ccalls" below.

// This is the only thing that we need from forth.h
#define cell long

// Prototypes

#if 0   // Examples
cell sum(cell b, cell a);
cell byterev(cell n);
#endif

cell ((* const ccalls[])()) = {
// Add your own routines here
#if 0  // Examples
    (cell (*)())sum,          // Entry # 0
    (cell (*)())byterev,      // Entry # 1
#endif
};

// Forth words to call the above routines may be created by:
//
//  system also
//  0 ccall: sum      { i.a i.b -- i.sum }
//  1 ccall: byterev  { s.in -- s.out }
//
// and could be used as follows:
//
//  5 6 sum .
//  p" hello"  byterev  count type
