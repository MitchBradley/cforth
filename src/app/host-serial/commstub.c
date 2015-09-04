/*
 * Communications stub for debugging from a host CForth process.
 * The host can send a stream of bytes to tell this stub to perform
 * various operations including memory access and executing
 * subroutines.
 * The basic idea is that the host pushes numbers on a stack,
 * then sends a command byte that performs an operation using
 * the data on the stack.  The result of that operation can
 * be sent back to the host.
 *
 * Call tether_loop() from your app to enable the debugging.
 *
 * Depends on external definition of
 *   void sendbyte(unsigned char byte);
 *   unsigned char getbyte(void);
 */

extern void sendbyte(unsigned char byte);
extern unsigned char getbyte(void);

// Protocol byte values:
// Result:
// 10nn.nnnn, [0mmm.mmmm]*, 1100.0000

// 10nn.nnnn Push and set TOS to nnnnnn
// 0mmm.mmmm TOS = TOS << 7 | mmmmmmm
// 11pp.pppp Execute function P

// P=0 : ACK (noop) - used in target to host direction
// P=1 : @
// P=2 : w@
// P=3 : c@
// P=4 : !
// P=5 : w!
// P=6 : l!
// P=7 : Send TOS back to host
// P=8 : EXIT from command processing loop
// P=9 : Push address of scratch buffer 0
// P=10: Push address of scratch buffer 1
// P=11: Read n (TOS) bytes from host and store in target memory at address (SOS)
// P=12: Send n (TOS) bytes from target memory at address (SOS) to host
// P=13: PING - just send ACK
// P=1xxxx0 : Execute TOS with rest of stack as args
// P=1xxxx1 : Execute TOS with rest of stack as args, return result to host

void sendack()
{
	sendbyte(0xc0);
}

void send(unsigned int u)
{
	if (u < 0x40) {
		sendbyte(u | 0x80);
		goto tail0;
	}
	if (u < 2000) {
		sendbyte((u >>  7) | 0x80);
		goto tail1;
	}
	if (u < 100000) {
		sendbyte((u >> 14) | 0x80);
		goto tail2;
	}
	if (u < 8000000) {
		sendbyte((u >> 21) | 0x80);
		goto tail3;
	}

	sendbyte((u >> 28) | 0x80);
	sendbyte((u >> 21) & 0x7f);
tail3:
	sendbyte((u >> 14) & 0x7f);
tail2:
	sendbyte((u >>  7) & 0x7f);
tail1:
	sendbyte( u        & 0x7f);
tail0:
	sendack();
}

#define SCRATCHSIZE 0x40
unsigned char scratch0[SCRATCHSIZE];
unsigned char scratch1[SCRATCHSIZE];

#define STACKSIZE 10
unsigned int stack[STACKSIZE];

void push(void)
{
	stack[9] = stack[8];
	stack[8] = stack[7];
	stack[7] = stack[6];
	stack[6] = stack[5];
	stack[5] = stack[4];
	stack[4] = stack[3];
	stack[3] = stack[2];
	stack[2] = stack[1];
	stack[1] = stack[0];
// Some libs don't have memmove, and memcpy doesn't work with overlapping ranges
//	memmove(&stack[1], &stack[0], (STACKSIZE-1) * sizeof(stack[0]));
}

void copy_in(unsigned char *adr, int len)
{
	while (len--) {
		*adr++ = getbyte();
	}
}

void copy_out(unsigned char *adr, int len)
{
	while (len--) {
		sendbyte(*adr++);
	}
}

int perform(unsigned char b)
{
	int (*func)() = (void *)stack[0];

	if (b & 0x20) {
		stack[0] = func(stack[1], stack[2], stack[3], stack[4], stack[5], stack[6], stack[7]);
		if (b & 1)
			send(stack[0]);
		else
			sendbyte(0xc0);
	} else {
		switch (b)
		{
		case 0: break;

		case 1: stack[0] = *(int            *)stack[0]; send(stack[0]); break;
		case 2: stack[0] = *(unsigned short *)stack[0]; send(stack[0]); break;
		case 3: stack[0] = *(unsigned char  *)stack[0]; send(stack[0]); break;

		case 4: *(int   *)stack[0] =        stack[1]; break;
		case 5: *(short *)stack[0] = (short)stack[1]; break;
		case 6: *(char  *)stack[0] = (char )stack[1]; break;

		case 7: send(stack[0]); break;
		case 8: return (1);

		case 9: push(); stack[0] = (unsigned int)scratch0; break;
		case 10: push(); stack[0] = (unsigned int)scratch1; break;
		case 11: copy_in((void *)stack[1], stack[0]); break;
		case 12: copy_out((void *)stack[1], stack[0]); break;
		case 13: sendack(); break;
		}
	}
	return (0);
}

int handle_byte(unsigned char b)
{
	if ((b & 0x80) == 0) {
		stack[0] = (stack[0] << 7) | b;
		return 0;
	}
	if ((b & 0x40) == 0) {
		push();
		stack[0] = b & 0x3f;
		return 0;
	}
	return perform(b & 0x3f);
}

void tether_loop()
{
	sendack();		// This ACK informs the host that we are ready
	while (handle_byte(getbyte()) == 0)
		;
}
