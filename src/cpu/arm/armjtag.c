// JTAG functions that are specific to ARM processors

// Requires jtag.c
#include "types.h"
#include "jtag.h"

void TDI_LOW();
void TMS_HIGH();

u_long indata[100];

u_long idcode() {
    u_char final;
    u_long n;

    jtag_instruction(0xe);
    shift_dr();

    // Shift out 32 bits little-endian
    TDI_LOW;                  // shift in zeros
    n = get_32lsbs();
    state_transition(0x1, 1);   // Go to exit1_dr state
    exit1_to_update();
    return n;
}

u_long ice_get(long regnum) {
    u_char final;
    u_long n;

    select_scan_chain(2);
    shift_dr();

    // Shift in the R/W bit (0 for read) while advancing to exit1_dr state
    (void)put_lsbs(5, regnum);    // Shift in the register number
    TMS_HIGH;
    (void)put_lsbs(1, 0);         // Send R/W = 0 and advance to exit1_dr
    exit1_to_idle();

    shift_dr();

    // Shift out 33 bits little-endian, ignoring the last one
    TDI_LOW;                      // shift in zeros
    n = get_32lsbs();
    state_transition(0x1, 1);   // Go to exit1_dr state

    exit1_to_update();

    // get_le() shifts in zeros while shifting out the 32 data bits.
    // The zeros end up in the adr and R/W fields (and some in the data field),
    // which means the core will execute a " read debug_control register"
    // instruction at update_dr state.  That is probably innocuous.
    return n;
}

void ice_set(u_long regnum, u_long data32) {
    select_scan_chain(2);
    shift_dr();
    // Shift in the R/W bit (1 for write) while advancing to exit1_dr state
    (void)put_lsbs(32, data32);      // Shift in the data value
    (void)put_lsbs(5, regnum);       // Shift in the register number
    TMS_HIGH;
    (void)put_lsbs(1, 1);            // Send R/W = 1 and advance to exit1_dr state
    exit1_to_update();
}

// (RW except as noted)  adr #bits
#define debug_ctl              0 //  3    // RO
#define debug_status           1 //  5    // RO
#define debug_comms_ctl        4 //  6    // RO
#define debug_comms_data       5 // 32
#define watchpoint0_adr        8 // 32
#define watchpoint0_adr_mask   9 // 32
#define watchpoint0_data      10 // 32
#define watchpoint0_data_mask 11 // 32
#define watchpoint0_ctl       12 //  9
#define watchpoint0_ctl_mask  13 //  8
#define watchpoint1_adr       16 // 32
#define watchpoint1_adr_mask  17 // 32
#define watchpoint1_data      18 // 32
#define watchpoint1_data_mask 19 // 32
#define watchpoint1_ctl       20 //  9
#define watchpoint1_ctl_mask  21 //  8

void wait_memory_access() {
    u_long ds;
    ds = 0;
    while ((ds & 9) != 9) {
        ds = ice_get(debug_status);
    }
}

void stop_core()  { // page 12
    u_long ds;

    ice_set(watchpoint0_adr,                0);
    ice_set(watchpoint0_adr_mask,          -1);
    ice_set(watchpoint0_data,               0);
    ice_set(watchpoint0_data_mask,         -1);
    ice_set(watchpoint0_ctl,            0x100);
    ice_set(watchpoint0_ctl_mask,  0xfffffff7);
    ds = 0;
    while ((ds & 1) == 0) {
        ds = ice_get(debug_status);
    }
    ice_set(watchpoint0_ctl, 0);
    test_logic_reset();
}

void scan1_out(u_long n, u_int breakpoint_bit) {
    select_scan_chain(1);
    shift_dr();
    (void)put_lsbs(1, breakpoint_bit);

    // Shift out 32 bits big-endian
    put_32msbs(n);

    exit1_to_idle();
}

u_long get_data() {
    u_long n;

    select_scan_chain(1);
    shift_dr();

    // Shift out and ignore the breakpoint bit
    (void)put_lsbs(1, 0);

    // Shift out 32 bits, MSB first, setting TMS prior to the last one
    n = get_32msbs();

    exit1_to_idle();
    return n;
}

// ... Use selected ARM machine instruction sequences to access
// registers inside the ARM processor core

#define ARM_NOP        0xe1a00000   // MOV R0, R0
#define ARM_REG_STORE  0xe58e0000   // STR reg, [R14]
#define ARM_REG_LOAD   0xe59e0000   // LDR reg, [R14]
#define ARM_LDMIA      0xe89e0000   // LDMIA R14,{mask}
#define ARM_STMIA      0xe88e0000   // STMIA R14,{mask}
#define ARM_CPSR_LOAD  0xe10f0000   // MRS R0, CPSR
#define ARM_CPSR_STORE 0xe12ff000   // MSR CPSR, R0
#define ARM_LD         0xe4901004   // LD R1,[R0],4
#define ARM_ST         0xe4801004   // ST R1,[R0],4
#define ARM_LDMIAUPD   0xe8be0000   // LDMIA R14!,{mask}
#define ARM_STMIAUPD   0xe8ae0000   // STMIA R14!,{mask}
#define ARM_BR         0xeafffffa   // BR ._6

#define slow_nop()  scan1_out(ARM_NOP, 0);

void slow_instruction1nop(u_long opcode) {
    scan1_out(opcode, 0);
    slow_nop();
}

void slow_instruction2nops(u_long opcode) {
    scan1_out(opcode, 0);
    slow_nop();
    slow_nop();
}

void fast_mode() {
    slow_nop();
    scan1_out(ARM_NOP, 1);   // Fast NOP
}

u_long get_register(u_char regnum) { // Page 13
    u_long instruction;
    instruction = (regnum << 12) | ARM_REG_STORE;
    slow_instruction2nops(instruction);  // STR Rn,[R14]
    return get_data();
}

void set_register(u_char regnum, u_long data32) {       // Page 13
    u_long instruction;
    instruction = (regnum << 12) | ARM_REG_LOAD;  // LDR Rn,[R14]
    slow_instruction2nops(instruction);
    slow_instruction1nop(data32);
    if (regnum == 15) {           // Special behavior after updating PC
        slow_nop();
        slow_nop();
    }
}

u_long get_cpsr() {
    u_long cpsr;
    u_long old_r0;
    old_r0 = get_register(0);
    slow_instruction2nops(ARM_CPSR_LOAD);
    cpsr = get_register(0);
    set_register(0, old_r0);
    return cpsr;
}

void set_cpsr(u_long cpsr) {
    u_long old_r0;
    old_r0 = get_register(0);
    set_register(0, cpsr);
    slow_instruction2nops(ARM_CPSR_STORE);
    set_register(0, old_r0);
}

void memory_instruction(u_long opcode) {
    fast_mode();
    slow_instruction1nop(opcode);
    jtag_restart();
    wait_memory_access();
}

u_long jtag_get_mem_nosave(u_long adr)  {      // Destroys r0 and r1
    u_long value;
    set_register(0, adr);            // Address to R0
    memory_instruction(ARM_LD);      // LD R1,[R0],4
    value = get_register(1);          // Get value from register
    return value;
}

u_long jtag_get_mem(u_long adr) {
    u_long value;
    u_long old_r0, old_r1;
    old_r0 = get_register(0);
    old_r1 = get_register(1);        // Save registers
    value = jtag_get_mem_nosave(adr);
    set_register(1, old_r1);
    set_register(0, old_r0);         // Restore registers
    return value;
}

void jtag_set_mem_nosave(u_long adr, u_long value) { // Destroys r0 and r1
    set_register(0, adr);             // Address to R0
    set_register(1, value);           // Data to R1
    memory_instruction(ARM_ST);       // ST R1,[R0],4
}

void jtag_set_mem(u_long adr, u_long data32) {
    u_long old_r0, old_r1;
    old_r0 = get_register(0);
    old_r1 = get_register(1);        // Save registers
    jtag_set_mem_nosave(adr, data32);
    set_register(1, old_r1);
    set_register(0, old_r0);         // Restore registers
}

#define MAXTRANSFER (14*4)

void jtag_out(u_long *address, u_int numbytes, u_long target_adr) {
    u_int msk;
    u_long ld_instr;
    u_long st_instr;
    u_char thisbytes;
    u_int remaining;
    u_char idx;

    remaining = numbytes;

    set_register(14, target_adr);

    thisbytes = MAXTRANSFER;
    msk = (1 << (thisbytes >> 2)) - 1;
    st_instr = ARM_STMIAUPD | msk;
    ld_instr = ARM_LDMIA    | msk;

    while ( remaining > 0 ) {
        if (remaining < MAXTRANSFER) {
            thisbytes = remaining;
            msk = (1 << (thisbytes >> 2)) - 1;
            st_instr = ARM_STMIAUPD | msk;
            ld_instr = ARM_LDMIA    | msk;
        }

        slow_instruction2nops(ld_instr);  // LDMIA R14,{R0..Rn}
        for (idx = 0; idx <= thisbytes; idx += 4) {
            scan1_out(*address++, 0);
        }

        slow_nop();
        memory_instruction(st_instr);     // STMIA R14!,{R0..Rn}
        remaining -= thisbytes;
    }
}

void jtag_in(u_int idx, u_int numbytes, u_long target_adr) {
    u_int msk;
    u_long ld_instr;
    u_long st_instr;
    u_char thisbytes;
    u_int remaining;
    int i;

    set_register(14, target_adr);

    remaining = numbytes;
    thisbytes = MAXTRANSFER;
    msk = (1 << (thisbytes >> 2)) - 1;
    ld_instr = ARM_LDMIAUPD | msk;
    st_instr = ARM_STMIA    | msk;

    while ( remaining > 0 ) {
        if (remaining < MAXTRANSFER) {
            thisbytes = remaining;
            msk = (1 << (thisbytes >> 2)) - 1;
            ld_instr = ARM_LDMIAUPD | msk;
            st_instr = ARM_STMIA    | msk;
        }

        memory_instruction(ld_instr);      // LDMIA R14!,{R0..Rn}
        slow_instruction2nops(st_instr);   // STMIA R14, {R0..Rn}
        for (i = thisbytes >> 2; i; i--) {
            indata[idx] = get_data();
            idx++;
        }

        remaining -= thisbytes;
    }
}

void jtag_goto(u_long pc) {
    set_register(15, pc);
    // Running these three instructions bumps the PC three
    // instructions past the address we just loaded, and
    // set_register bumps the PC a few times too.
    fast_mode();
    slow_instruction2nops(ARM_BR);   // BR ._6
    jtag_restart();
    state_transition(0x0, 1);   // run_test_idle  // Seems to be necessary; don't know why
}
