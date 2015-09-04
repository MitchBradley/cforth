/* The MIT License

   Copyright (C) 2011 Zilong Tan (labytan@gmail.com)

   Permission is hereby granted, free of charge, to any person obtaining
   a copy of this software and associated documentation files (the
   "Software"), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to
   the following conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
*/

#ifndef __ULIB_SHA256_H
#define __ULIB_SHA256_H

#include <inttypes.h>

#define SHA256_HASH_SIZE 32	/* 256 bit */
#define SHA256_HASH_WORDS 8

struct _SHA256Context {
	uint64_t totalLength;
	uint32_t hash[SHA256_HASH_WORDS];
	uint32_t bufferLength;
	union {
		uint32_t words[16];
		uint8_t bytes[64];
	} buffer;
};
typedef struct _SHA256Context SHA256Context;

#ifdef __cplusplus
extern "C" {
#endif

	void SHA256Init(SHA256Context * sc);

	void SHA256Update(SHA256Context * sc, const void *data, uint32_t len);

	void SHA256Final(SHA256Context * sc, uint8_t hash[SHA256_HASH_SIZE]);

#ifdef __cplusplus
}
#endif

#endif  /* __ULIB_SHA256_H */
