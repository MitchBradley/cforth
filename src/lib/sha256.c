/*
 * From:
 * https://code.google.com/p/ulib/source/browse/trunk/src/base/sha256sum.c?r=39
 *
 * Adapted by ënimai Inc.
 *
 * The MIT License
 * Copyright (C) 2011 Zilong Tan (tzlloch@gmail.com)
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Original code is derived from the author: Allan Saddi
 */

#include <inttypes.h>
#include <string.h>
#include "sha256.h"

#define ROTL(x, n)    (((x) << (n)) | ((x) >> (32 - (n))))
#define ROTR(x, n)    (((x) >> (n)) | ((x) << (32 - (n))))

#define Ch(x, y, z)   ((z) ^ ((x) & ((y) ^ (z))))
#define Maj(x, y, z)  (((x) & ((y) | (z))) | ((y) & (z)))
#define SIGMA0(x)     (ROTR((x), 2) ^ ROTR((x), 13) ^ ROTR((x), 22))
#define SIGMA1(x)     (ROTR((x), 6) ^ ROTR((x), 11) ^ ROTR((x), 25))
#define sigma0(x)     (ROTR((x), 7) ^ ROTR((x), 18) ^ ((x) >> 3))
#define sigma1(x)     (ROTR((x), 17) ^ ROTR((x), 19) ^ ((x) >> 10))

#define DO_ROUND() {                                      \
    t1 = h + SIGMA1(e) + Ch(e, f, g) + *(Kp++) + *(W++);  \
    t2 = SIGMA0(a) + Maj(a, b, c);                        \
    h = g;                                                \
    g = f;                                                \
    f = e;                                                \
    e = d + t1;                                           \
    d = c;                                                \
    c = b;                                                \
    b = a;                                                \
    a = t1 + t2;                                          \
  }

static const uint32_t K[64] = {
  0x428a2f98L, 0x71374491L, 0xb5c0fbcfL, 0xe9b5dba5L,
  0x3956c25bL, 0x59f111f1L, 0x923f82a4L, 0xab1c5ed5L,
  0xd807aa98L, 0x12835b01L, 0x243185beL, 0x550c7dc3L,
  0x72be5d74L, 0x80deb1feL, 0x9bdc06a7L, 0xc19bf174L,
  0xe49b69c1L, 0xefbe4786L, 0x0fc19dc6L, 0x240ca1ccL,
  0x2de92c6fL, 0x4a7484aaL, 0x5cb0a9dcL, 0x76f988daL,
  0x983e5152L, 0xa831c66dL, 0xb00327c8L, 0xbf597fc7L,
  0xc6e00bf3L, 0xd5a79147L, 0x06ca6351L, 0x14292967L,
  0x27b70a85L, 0x2e1b2138L, 0x4d2c6dfcL, 0x53380d13L,
  0x650a7354L, 0x766a0abbL, 0x81c2c92eL, 0x92722c85L,
  0xa2bfe8a1L, 0xa81a664bL, 0xc24b8b70L, 0xc76c51a3L,
  0xd192e819L, 0xd6990624L, 0xf40e3585L, 0x106aa070L,
  0x19a4c116L, 0x1e376c08L, 0x2748774cL, 0x34b0bcb5L,
  0x391c0cb3L, 0x4ed8aa4aL, 0x5b9cca4fL, 0x682e6ff3L,
  0x748f82eeL, 0x78a5636fL, 0x84c87814L, 0x8cc70208L,
  0x90befffaL, 0xa4506cebL, 0xbef9a3f7L, 0xc67178f2L
};

#ifndef RUNTIME_ENDIAN

#ifdef WORDS_BIGENDIAN

#define BYTESWAP(x) (x)
#define BYTESWAP64(x) (x)

#else /* !WORDS_BIGENDIAN */

#define BYTESWAP(x) ((ROTR((x), 8) & 0xff00ff00L) | \
                     (ROTL((x), 8) & 0x00ff00ffL))
#define BYTESWAP64(x) _byteswap64(x)

static inline uint64_t _byteswap64(uint64_t x)
{
  uint32_t a = x >> 32;
  uint32_t b = (uint32_t) x;
  return ((uint64_t) BYTESWAP(b) << 32) | (uint64_t) BYTESWAP(a);
}

#endif /* WORDS_BIGENDIAN */

#else /* RUNTIME_ENDIAN */

static int littleEndian;

#define BYTESWAP(x) _byteswap(x)
#define BYTESWAP64(x) _byteswap64(x)

#define _BYTESWAP(x) ((ROTR((x), 8) & 0xff00ff00L) |  \
          (ROTL((x), 8) & 0x00ff00ffL))
#define _BYTESWAP64(x) __byteswap64(x)

static inline uint64_t __byteswap64(uint64_t x)
{
  uint32_t a = x >> 32;
  uint32_t b = (uint32_t) x;
  return ((uint64_t) _BYTESWAP(b) << 32) | (uint64_t) _BYTESWAP(a);
}

static inline uint32_t _byteswap(uint32_t x)
{
  if (!littleEndian)
    return x;
  else
    return _BYTESWAP(x);
}

static inline uint64_t _byteswap64(uint64_t x)
{
  if (!littleEndian)
    return x;
  else
    return _BYTESWAP64(x);
}

static inline void setEndian(void)
{
  union {
    uint32_t w;
    uint8_t b[4];
  } endian;

  endian.w = 1L;
  littleEndian = endian.b[0] != 0;
}

#endif /* RUNTIME_ENDIAN */

static const uint8_t padding[64] = {
  0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

void SHA256Init(SHA256Context * sc)
{
#ifdef RUNTIME_ENDIAN
  setEndian();
#endif /* RUNTIME_ENDIAN */

  sc->totalLength = 0LL;
  sc->hash[0] = 0x6a09e667L;
  sc->hash[1] = 0xbb67ae85L;
  sc->hash[2] = 0x3c6ef372L;
  sc->hash[3] = 0xa54ff53aL;
  sc->hash[4] = 0x510e527fL;
  sc->hash[5] = 0x9b05688cL;
  sc->hash[6] = 0x1f83d9abL;
  sc->hash[7] = 0x5be0cd19L;
  sc->bufferLength = 0L;
}

static void burnStack(int size)
{
  char buf[128];

  memset(buf, 0, sizeof(buf));
  size -= sizeof(buf);
  if (size > 0)
    burnStack(size);
}

static void SHA256Guts(SHA256Context * sc, const uint32_t * cbuf)
{
  uint32_t buf[64];
  uint32_t *W, *W2, *W7, *W15, *W16;
  uint32_t a, b, c, d, e, f, g, h;
  uint32_t t1, t2;
  const uint32_t *Kp;
  int i;

  W = buf;

  for (i = 15; i >= 0; i--) {
    *(W++) = BYTESWAP(*cbuf);
    cbuf++;
  }

  W16 = &buf[0];
  W15 = &buf[1];
  W7 = &buf[9];
  W2 = &buf[14];

  for (i = 47; i >= 0; i--) {
    *(W++) = sigma1(*W2) + *(W7++) + sigma0(*W15) + *(W16++);
    W2++;
    W15++;
  }

  a = sc->hash[0];
  b = sc->hash[1];
  c = sc->hash[2];
  d = sc->hash[3];
  e = sc->hash[4];
  f = sc->hash[5];
  g = sc->hash[6];
  h = sc->hash[7];

  Kp = K;
  W = buf;

#ifndef SHA256_UNROLL
#define SHA256_UNROLL 1
#endif

#if SHA256_UNROLL == 1
  for (i = 63; i >= 0; i--)
    DO_ROUND();
#elif SHA256_UNROLL == 2
  for (i = 31; i >= 0; i--) {
    DO_ROUND(); DO_ROUND();
  }
#elif SHA256_UNROLL == 4
  for (i = 15; i >= 0; i--) {
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  }
#elif SHA256_UNROLL == 8
  for (i = 7; i >= 0; i--) {
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  }
#elif SHA256_UNROLL == 16
  for (i = 3; i >= 0; i--) {
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  }
#elif SHA256_UNROLL == 32
  for (i = 1; i >= 0; i--) {
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
    DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  }
#elif SHA256_UNROLL == 64
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
  DO_ROUND(); DO_ROUND(); DO_ROUND(); DO_ROUND();
#else
#error "SHA256_UNROLL must be 1, 2, 4, 8, 16, 32, or 64!"
#endif

  sc->hash[0] += a;
  sc->hash[1] += b;
  sc->hash[2] += c;
  sc->hash[3] += d;
  sc->hash[4] += e;
  sc->hash[5] += f;
  sc->hash[6] += g;
  sc->hash[7] += h;
}

void SHA256Update(SHA256Context * sc, const void *data, uint32_t len)
{
  uint32_t bufferBytesLeft;
  uint32_t bytesToCopy;
  int needBurn = 0;

  if (sc->bufferLength) {
    bufferBytesLeft = 64L - sc->bufferLength;

    bytesToCopy = bufferBytesLeft;
    if (bytesToCopy > len)
      bytesToCopy = len;

    memcpy(&sc->buffer.bytes[sc->bufferLength], data, bytesToCopy);

    sc->totalLength += bytesToCopy * 8L;

    sc->bufferLength += bytesToCopy;
    data = ((uint8_t *) data) + bytesToCopy;
    len -= bytesToCopy;

    if (sc->bufferLength == 64L) {
      SHA256Guts(sc, sc->buffer.words);
      needBurn = 1;
      sc->bufferLength = 0L;
    }
  }

  while (len > 63L) {
    sc->totalLength += 512L;

    SHA256Guts(sc, data);
    needBurn = 1;

    data = ((uint8_t *) data) + 64L;
    len -= 64L;
  }

  if (len) {
    memcpy(&sc->buffer.bytes[sc->bufferLength], data, len);

    sc->totalLength += len * 8L;

    sc->bufferLength += len;
  }

  if (needBurn)
    burnStack(sizeof(uint32_t[74]) + sizeof(uint32_t *[6]) + sizeof(int));
}

void SHA256Final(SHA256Context * sc, uint8_t hash[SHA256_HASH_SIZE])
{
  uint32_t bytesToPad;
  uint64_t lengthPad;
  int i;

  bytesToPad = 120L - sc->bufferLength;
  if (bytesToPad > 64L)
    bytesToPad -= 64L;

  lengthPad = BYTESWAP64(sc->totalLength);

  SHA256Update(sc, padding, bytesToPad);
  SHA256Update(sc, &lengthPad, 8L);

  if (hash) {
    for (i = 0; i < SHA256_HASH_WORDS; i++) {
      *((uint32_t *) hash) = BYTESWAP(sc->hash[i]);
      hash += 4;
    }
  }
}

#ifdef TEST_SHA256
int sha256_test(void)
{
  static const struct {
      char *msg;
      unsigned char hash[32];
  } tests[] = {
    { "abc",
      { 0xba, 0x78, 0x16, 0xbf, 0x8f, 0x01, 0xcf, 0xea,
        0x41, 0x41, 0x40, 0xde, 0x5d, 0xae, 0x22, 0x23,
        0xb0, 0x03, 0x61, 0xa3, 0x96, 0x17, 0x7a, 0x9c,
        0xb4, 0x10, 0xff, 0x61, 0xf2, 0x00, 0x15, 0xad }
    },
    { "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
      { 0x24, 0x8d, 0x6a, 0x61, 0xd2, 0x06, 0x38, 0xb8,
        0xe5, 0xc0, 0x26, 0x93, 0x0c, 0x3e, 0x60, 0x39,
        0xa3, 0x3c, 0xe4, 0x59, 0x64, 0xff, 0x21, 0x67,
        0xf6, 0xec, 0xed, 0xd4, 0x19, 0xdb, 0x06, 0xc1 }
    },
  };

  int i;
  unsigned char tmp[32];
  SHA256Context sc;

  for (i = 0; i < sizeof(tests) / sizeof(tests[0]); i++) {
      SHA256Init(&sc);
      SHA256Update(&sc, tests[i].msg, strlen(tests[i].msg));
      SHA256Final(&sc, tmp);
      if (memcmp(tmp, tests[i].hash, 32) != 0) {
         return 1;
      }
  }
  return 0;
}
#endif
