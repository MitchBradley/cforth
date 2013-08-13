#include "regs.h"

u_long get_32lsbs();
u_long put_lsbs(int nbits, u_long bits);
u_long get_32msbs();
void   put_32msbs(u_long bits);
void state_transition(u_long bits, int nbits);
void shift_dr();
void exit1_to_update();
void update_to_idle();
void exit1_to_idle();
void test_logic_reset();
void jtag_instruction(u_long n);
void jtag_restart();
void select_scan_chain(u_int n);

