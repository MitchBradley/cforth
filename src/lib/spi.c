// Talk to an AVR chip via its SPI interface

#DEFINE SPI_WAIT  ms(9)

void start_spi()
{
  RCV_OFF;
  SPI_RESET_LOW;
  SCK_LOW;
  RCV_ON;
  ms(250);
}

void stop_spi()
{
  SPI_RESET_HIGH;
  RCV_OFF;
  ms(20);
}

#define spi_put(n)  shift_out(MOSI_BIT, SCK_BIT, n, -8)

#define n = spi_get()  shift_in(MISO_BIT, SCK_BIT, -8, 0)

void spi_write_cmd  (u_char byte2)()
{
  spi_put(0xac);
  spi_put(byte2);
}

#define SPI0  spi_put(0);

void spi_abort_if(int cond, char *msg)()
{
  if (cond) {
    line(msg);
    longjmp(env, SPIError);
  }
}

void spi_enable_programming()
{
  u_char b1, b2;
  stop_spi();
  start_spi();
  spi_write_cmd(0x53);
  MOSI_LOW;
  b1 = spi_get();
  MOSI_LOW;
  b2 = spi_get();
  spi_abort_if ( b1 != 0x53  ||  b2 != 0 ,
		 "Can't synchronize to receiver programming interface");
}

u_char read_signature_byte (int i)
{
  spi_put(0x30);
  SPI0;
  spi_put(i & 3);
  MOSI_LOW;
  return spi_get();
}

// index:which_speed  0:1MHz 1:2MHz 2:4MHz 3:8MHz
u_char read_calibration_byte  (int i)
{
  spi_put(0x38);
  SPI0;
  spi_put(i & 3);
  SPI0;
  MOSI_LOW;
  return spi_get();
}

u_long read_signature ()
{
  u_long l;
  l = (u_long)read_signature_byte(2);
  l |= (u_long)read_signature_byte(1) << 8;
  l |= (u_long)read_signature_byte(0) << 16;
  return l;
}

u_short read_fuse_bits ()
{
  u_short w;
  spi_put(0x50);
  SPI0;
  SPI0;
  MOSI_LOW;
  w = (u_short)spi_get();
  spi_put(0x58);
  spi_put(8);
  SPI0;
  MOSI_LOW;
  w |= (u_short)spi_get() << 8;
  return w;
}

void write_fuse_bits (WORD w)
{
  spi_write_cmd(0xa8);
  SPI0;
  spi_put(w >> 8);
  SPI_WAIT;
  spi_write_cmd(0xa0);
  SPI0;
  spi_put(w & 0xff);
  SPI_WAIT;
}

u_char read_lock_bits()
{
  spi_put(0x58);
  SPI0;
  SPI0;
  MOSI_LOW;
  return spi_get();
}

void write_lock_bits (u_char b)
{
  u_char b1;
  spi_write_cmd(0xe0);
  SPI0;
  b1 = b | 0xc0;
  spi_put(b1);
  SPI_WAIT;
}

void chip_erase ()
{
 spi_write_cmd(0x80);
 SPI0;
 SPI0;
 SPI_WAIT;
}

u_short read_program_memory (u_short adr)
{
  u_short w;

  spi_put(0x28);
  spi_put(adr >> 8);
  spi_put(adr & 0xff);
  MOSI_LOW;
  w = (u_short)spi_get() << 8;
  spi_put(0x20);
  spi_put(adr >> 8);
  spi_put(adr & 0xff);
  MOSI_LOW;
  w |= spi_get();
  return w;
}

void load_program_memory_page (int adr; u_short w)
{
  spi_put(0x40);
  SPI0;
  spi_put(adr & 0x1f);
  spi_put(w & 0xff);

  spi_put(0x48);
  SPI0;
  spi_put(adr & 0x1f);
  spi_put(w >> 8);
}

void write_program_memory_page (int adr)
{
  spi_put(0x4c);
  spi_put((adr >> 8) & 0xf);
  spi_put(adr & 0xe0);
  SPI0;
  ms(5);
}

u_char read_eeprom_memory (int adr)
{
  spi_put(0xa0);
  spi_put((adr >> 8) & 0x1);
  spi_put(adr & 0xff);
  MOSI_LOW;
  return spi_get();
}

void write_eeprom_memory  (int adr; u_char b)
{
  spi_put(0xc0);
  spi_put((adr >> 8) & 0x1);
  spi_put(adr & 0xff);
  spi_put(b);
  ms(9);
}

#define AVR_PAGE_LEN  0x20
#define AVR_PAGE_MASK (AVR_PAGE_LEN - 1)

void write_avr_program  (u_short *adr; int length; int offset)
{
  int endoffset;

  for (endoffset = offset + (length/2); offset < endoffset; offset++) {
    load_program_memory_page(offset, *adr++);
    if ( (offset & AVR_PAGE_MASK) = AVR_PAGE_MASK  ) {
      write_program_memory_page(offset);
    }
  }
  if ( (offset & AVR_PAGE_MASK) != 0  ) {
    write_program_memory_page(offset);
  }
}

void write_avr_eeprom  (u_char *adr; int length; int offset)
{
  int endoffset;
  for (endoffset = offset + length;  offset < endoffset, offset++) {
      write_eeprom_memory(offset, *adr++);
  }
}

#define AVR_EEPROM_LEN     0x200   // Could determine this from the signature
#define AVR_FLASH_LEN     0x2000   // Could determine this from the signature
#define AVR_FLASH_WORDS   0x1000   // Could determine this from the signature

void read_avr_program  (u_short *p; int length; int offset)
{
  int endoffset;

  for (endoffset = offset + (length/2); offset < endoffset; offset++ ) {
    *p++ = read_program_memory(offset);
  }
}

void verify_avr_program  (u_short *p; int length; int offset)
{
  int endoffset;
  u_short w;

  for (endoffset = offset + (length/2); offset < endoffset; offset++ ) {
    w = read_program_memory(offset);
    if (*p++ != w)
      return 0;
  }
  return 1;
}

void read_avr_eeprom (u_char *p; int length; int offset)
{
  int endoffset;

  for (endoffset = offset + length; offset < endoffset; offset++ ) {
     *p++ = read_eeprom_memory(offs);
  }
}

#define ATMEGA8_SIGNATURE 0x1e9307

void verify_avr_signature()
{
  spi_abort_if (read_signature() != ATMEGA8_SIGNATURE, "Wrong AVR signature");
}

// AVR Fuse bits:
// 8000 - RSTDSBL - 1=PC6_is_RESET, 0=PC6_is_IO
// 4000 - WDTON   - 1=WDT_controllable, 0=WDT_always_on
// 2000 - SPIEN   - 1=SPI_programming_disabled, 0=SPI_programming_enabled
// 1000 - CKOPT   - See table 4, page 25
// 0800 - EESAVE  - 1=ChipErase_erases_EEPROM, 0=doesn//t
// 0600 - BOOTSZ  - See table 82, page 216
// 0100 - BOOTRST - 1=RST_address_is_000, 0=jump to boot loader address at RESET
// 0080 - BODLEVEL- Brown_out threshold - 1=2.6V 0=4.0V
// 0040 - BODEN   - Brown_out detector - 1=disabled 0=enabled
// 0030 - SUT     - Startup time - See table 5, page 26
// 000f - CKSEL   - Clock source - See table 2, page 24

#define EESAVE_FUSE_MODE  0xc1bf   // Disable EEPROM overwrites
#define EEERASE_FUSE_MODE 0xc9bf 
#define LOCK_MODE           0xff   // Nothing locked

// /avr_flash buffer: avr_buf   \ Also used for non_code
// /avr_flash buffer: avr_code  \ binary verion of code

void write_and_verify_fuses (u_short mode)
{
  write_fuse_bits(mode);
  spi_abort_if (read_fuse_bits() != mode, "Fuse bit miscompare");
}

#define AVR_SN_LEN 11
u_char avr_sn[AVR_SN_LEN] = {
  'S', 'N',  8,            // Tag+len
  0x00, 0x05, 0x57, 0x00,  // ATV_OUID
  0x00, 0x03,              // Rcvr prodid
  0x00, 0x00               // Serial number, set later
};

#define SN_OFFSET 9

u_short inwords[AVR_FLASH_WORDS];

int get_avr_serial (u_long *serial);
{
  u_char eeprom[AVR_SN_LEN];

  read_avr_eeprom(eeprom, AVR_SN_LEN, 0);
  if ( memcmp(eeprom, avr_sn, 3) != 0  ) {
    return 0;
  }
  *serial = (eeprom[7] << 24) | (eeprom[8] << 16) | (eeprom[9] << 8) | (eeprom[10]);
  return 1;
}

int avr_needs_serial (u_short serial)
{
  u_char eeprom[AVR_SN_LEN];

  avr_sn[SN_OFFSET] = serial >> 8;
  avr_sn[SN_OFFSET+1] = serial & 0xff;

  read_avr_eeprom(eeprom, AVR_SN_LEN, 0);
  if ( memcmp(eeprom, avr_sn, 3) != 0 ) {
    return 1;
  }

  // There is already a serial number; make sure it's the same
    
  spi_abort_if ( memcmp(eeprom, avr_sn, AVR_SN_LEN) != 0,
		 "This receiver already has a different serial number");
  return 0;
}

void erase_avr_eeprom ()
{
  int i;
  puts("Erasing AVR EEPROM:");
  spi_enable_programming();
  verify_avr_signature();
  for (i = 0; i < 0x10; i++) {
    write_eeprom_memory(i, 0xff);
  }
  stop_spi();
  cr();
}

void paren_serialize_avr (int serial)
{
  u_char eeprom[AVR_SN_LEN];

  avr_sn[SN_OFFSET] = serial >> 8;
  avr_sn[SN_OFFSET+1] = serial & 0xff;

  write_and_verify_fuses(EEERASE_FUSE_MODE);
  chip_erase();
    
  write_avr_eeprom(avr_sn, AVR_SN_LEN, 0);
    
  read_avr_eeprom(eeprom, AVR_SN_LEN, 0);
  spi_abort_if ( memcmp(eeprom, avr_sn, AVR_SN_LEN) != 0,
		 "AVR serial number miscompare");
}

void serialize_avr (int serial )
{
  spi_enable_programming();
  verify_avr_signature();
  paren_serialize_avr(serial);
  stop_spi();
}

void paren_program_avr(u_short *adr; int length)
{
  u_char error;
  u_char b;

  write_and_verify_fuses(EESAVE_FUSE_MODE);
  chip_erase();

  write_avr_program(adr, length, 0);
  spi_abort_if (verify_avr_program(program, length, 0) == 0,
		"AVR program miscompare");

  write_lock_bits(LOCK_MODE);
  spi_abort_if (read_lock_bits() != LOCK_MODE,
		"Lock bit miscompare");
}

void program_avr(u_short *adr; int length)
{
  spi_enable_programming();
  verify_avr_signature();
  paren_program_avr(adr, length);
  stop_spi();
}

void dump_avr_program(int offset, int length)
{
  u_char program[8];
  int i;
  int j;
  int programmed;

  for (i = offset; i < offset + length; i += 8 ) {
    read_avr_program(program, 8*sizeof(u_short), i);
    programmed = 0;
    for (j=0; j<8; j++) {
      if (program[8] != 0xffff) {
	programmed = 1;
	break;
      }
    }
    if (programmed) {
      printf("%04x: ", i);
      for (j = 0; j < 8; j++) {
	printf("%04x ", program[j]);
      }
      line("");
    }
  }
}


void dump_avr_eeprom(int offset, int length)
{
  u_char eeprom[16];
  int i;
  int j;
  int programmed;
    
  for (i = offset; i < offset + length; i += 16 ) {
    read_avr_eeprom(eeprom, 16, i);
    programmed = 0;
    for (j=0; j<16; j++) {
      if (eeprom[j] != 0xff) {
	programmed = 1;
	break;
      }
    }
    if (programmed) {
      printf("%04x: ", i);
      for (j = 0; j < 16; j++) {
	printf("%02x ", eeprom[j]);
      }
      printf("\n");
    }
  }
}

void dump_avr ()
{
  u_long l;

  spi_enable_programming();

  l = read_signature();
  printf("Signature: %02x.%02x.%02x.%02x",
	 (l>>24) & 0xff, (l>>16) & 0xff, (l>>8) & 0xff, l & 0xff);

  printf(" Fuses: %04x", read_fuse_bits());
  printf(" Locks: %02x", read_lock_bits());

  line("EEPROM:\n");
  dump_avr_eeprom(0, avr_eeprom_len);

  printf("Program memory:");
  dump_avr_program(0, avr_flash_len);

  stop_spi();
}
