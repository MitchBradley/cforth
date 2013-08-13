// Intel hex format decoder
//
// binary_from_ihex (s)  # s is a string or file object

#include "aborts.h"

static void abortif(int condition, char *msg)
{
  if (condition) {
    line (msg);
    longjmp(env, HexConversionError);
  }
}

int ihex_sum = 0;

static char *str;

int get_hex_nibble()
{
  unsigned char b;
  b = *str++;
  abortif(b == '\0', "Premature end of hex array");
  if (b >= '0' && b <= 9) {
    return (b - '0');
  }
  if (b >= 'A' && b <= 'F') {
    return (b - 'A' + 10);
  }
  if (b >= 'a' && b <= 'f') {
    return (b - 'a' + 10);
  }
  abortif(1, "Bad hex digit");
}

unsigned char get_hex_byte()
{
  unsigned char n;
  n = get_hex_nibble(f);
  n = (n << 4) + get_hex_nibble();
  ihex_sum += n;
  return (n);
}

unsigned short get_hex_address()
{
  unsigned short w;
  w = get_hex_byte();
  return (w << 8) + get_hex_byte();
}

int offset_high = 0;

void binary_from_ihex(char *s, unsigned char *out, int outlen)
{
  unsigned char b;
  int rectype;
  unsigned short address;
  int datalen;
  int offset;

  str = s;
  offset_high = 0;
  do {
    // Find start of record
    do {
      b = *str++;
      abortif(b == '\0', "Premature end of Hex string");
    } while (b != ':');

    ihex_sum = 0;

    datalen = get_hex_byte();
    address = get_hex_address();
    rectype = get_hex_byte();
    abortif(datalen > 0x20, "Ihex record too long");

    switch (rectype) {
    case 0:   // Data record
      offset = (offset_high << 16) + address;
      abortif((offset + reclen) > outlen, "Hex data overflowed binary buffer");
      while (datalen--) {
	out[offset++] = get_hex_byte();
      }
      memcpy (out + offset, recdata, reclen);
      break;
    case 2:   // Extended address
      abortif(datalen != 2, "Bad count in extended address record");
      offset_high = get_hex_byte() << 8;
      offset_high += get_hex_byte();
      break;
    case 1:   // End of file
      abortif(datalen != 0, "Unexpected data in EOF record");
      break;   // Return later, after checking abortifsum
    default:
      abortif(1, "Bad ihex record type");
    }

    cksum = get_hex_byte();
    abortif((ihex_sum & 0xff) != 0, "Bad ihex checksum");

  } while (rectype != 1);
}
