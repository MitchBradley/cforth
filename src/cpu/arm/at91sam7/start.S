///////////////////////////////////////////////////////////////////////////////
// Reset, interrupt, and exception handlers.  This is the first code
// the program executes after startup.  It's also entered by exceptions
// and interrupts.  In any case, the action is to save (for debugging
// purposes) information about how we got here, then set up a stack and
// call main().
// 
// Author: Mitch Bradley
///////////////////////////////////////////////////////////////////////////////

#include "regs.h"
    .file   "start.c"
    .text
    .align  2
    .global _start
    .type   _start,function
_start:
    @ args = 0, pretend = 0, frame = 4
    @ frame_needed = 1, uses_anonymous_args = 0
        // Save room for exception vectors
    b   doreset // 00 Reset
    b   doundef // 04 Undefined instruction
    b   doswi   // 08 Software interrupt
    b   dopabt  // 0c Prefetch Abort
    b   dodabt  // 10 Data Abort
    .int  (0x10000/512) // 14 number of 512-byte blocks to load from ROM
    b   doirq   // 18 IRQ
    b   dofiq   // 1c FIQ

doreset:
    // Get the main clock running as soon as possible.  kick it off here.
    // load r1 up with 0xfffffc00, base register for Important controls	(PMC register)
    mvn r1, #0xFF
    bic r1, r1, #0x300    // form base addr fffffc00
    	
    mov r2, #0x0400       // main clock osc countdown should last at least 1.4ms
    orr r2, r2, #1        // MOSCEN bit
    str r2, [r1, #0x20]   // write directly to CKGR_MOR the start bit and OSCCOUNT


    mvn r3, #0xFF         // load r3 up with 0xfffff400, base register (for PIO)
    bic r3, r1, #0xb00
    mov r2, #0xA	  // set up TP1 & TP2 as outputs
    str r2, [r3, #0x34]   // PIO_CODR:	 set outputs low
    str r2, [r3, #0x10]   // PIO_OER:	 enable outputs

    mov r2, #0
    str r2, [r1, #0x2C]   // disable PLL, just in case
	
	
   // wait for main osc to be ready
spinmain:		
    mov r2, #2	
    str r2, [r3, #0x30]		// set TP1 high
    str r2, [r3, #0x34]         // set TP1 low

    ldr r2, [r1, #0x68]	        // spin on MOSCS bit...
    tst r2, #0x01               // it gets set when main osc is valid
    beq spinmain	

//	mvn r4, #0xff   // 0xffffff00 - memory controller base
//    mov r5, #0x300  // Lots of wait states for flash
//    str r5, [r4, #0x60]    // FLASH data accesses are now slower

#if 1   // was if 0
    // switch master clock to user main osc now	
    ldr r2, [r1, #0x30]    // get current contents of fffffc30 (PMC_MCKR)
    orr r2, r2, #1         // set bit CSS_MAIN, (switch over to main clock)
    str r2, [r1, #0x30]    // save it
#else
    // wait for the pll, don't bother with intermediate step
    // it appears only to take 1 ms for the PLL to get ready at this point
#endif
	
    // start PLL going
    // PLLR_VAL  DIV 8, MUL 64, PLLCOUNT 0x1f
    mov r2, #0x3f0000  // MUL 64
    add r2, r2, #0x1f00
    add r2, r2, #0x08
    str r2, [r1, #0x2C]	   // CKGR_PLLR
	
    // wait for PLL to lock.  this takes about 1ms
spinpll:	
//    mov r2, #8
            mov r2, #2
    str r2, [r3, #0x30]		// set TP1 high
    str r2, [r3, #0x34]         // set TP1 low

    ldr r2, [r1, #0x68]	        // spin on LOCK bit...
    tst r2, #0x04
    beq spinpll
	
	
    // select PLL as our master clock in two stages
    // see errata 6099A-ATARM-15-Apr-05
    mov r2, #0x08               // PRES(2)
    str r2, [r1, #0x30]		// PMC_MCKR
spinprescalesel:	
    ldr r2, [r1, #0x68]	        
    tst r2, #0x08		// spin on MCKRDY bit...
    beq spinprescalesel

    mov r2, #0x0b               // CSS_PLL selects the PLL, (w/ PRES(2))
    str r2, [r1, #0x30]		// PMC_MCKR
	

   // wait for master clock to be running on PLL
spinmstrck:		
    mov r2, #2	
    str r2, [r3, #0x30]		// set TP1 high
    str r2, [r3, #0x34]         // set TP1 low

    ldr r2, [r1, #0x68]	        // spin on MCKRDY bit...
    tst r2, #0x08
	beq spinmstrck
		
    mov r2, #0          // Code indicating how we got to main:	0 is default (normal)
dorestart:      
    ldr r1, .L1         // Get address of reset_reason storage area
    str r2, [r1, #0]    // Save a copy of the reset reason
    str r14, [r1, #4]   // Save a copy of the old PC

    mrs r5, cpsr
    str r5, [r1, #8]    // Save a copy of the mode that got us here
    orr r5, r5, #0xdf   // System mode (0x1f), Disable interrupts (0xc0)
    msr cpsr, r5        // Now we should be back to a clean mode

    mov sp, #RAMBASE
    add sp, sp, #RAMSIZE    // Set SP at top of RAM
//  mov r0,r14          // Old PC in case of trap

#if STALLER1
stall:
        mov r2, #2
        str r2, [r3, #0x30]
        str r2, [r3, #0x34]
        b stall
#endif
    bl      main

doirq:
    subs    lr, lr, #4  // Adjust the return address and
    stmfd   sp!, {lr}   // save it on the stack.
    mrs     r14, SPSR   // Save SPSR
    stmfd   sp!, {r14}  // on the stack.
    bl      irq_handler // Call the high level handler.
    ldmfd   sp!, {r14}  // Unstack and
    msr     spsr, r14   // restore SPSR.
    ldmfd   sp!, {pc}^  // Return.
        
doswi:
    stmfd   sp!, {lr}   // Save return address on the stack
    mrs     r14, SPSR   // Save SPSR
    stmfd   sp!, {r14}  // on the stack
    bl      swi_handler // Call the high level handler
    ldmfd   sp!, {r14}  // Unstack and
    msr     spsr, r14   // restore SPSR
    ldmfd   sp!, {pc}^  // Return
    
doundef:
    mov r2, #1          // Code indicating how we got to main
    b   dorestart

dopabt:
    mov r2, #2          // Code indicating how we got to main
    b   dorestart

dodabt:
    mov r2, #3          // Code indicating how we got to main
    b   dorestart

dofiq:
    mov r2, #4          // Code indicating how we got to main
    b   dorestart

    .global restart
    .type   restart,function
restart:
    mov r2, #5          // Code indicating how we got to main
    b   dorestart

    .global swi
    .type   swi,function
swi:    
    swi
    mov pc, lr

    .global ei
    .type   ei,function
ei: 
    mrs r1, cpsr
    bic r1, r1, #0x80
    msr cpsr, r1
    mov pc, lr

    .global di
    .type   di,function
di: 
    mrs r1, cpsr
    orr r1, r1, #0x80
    msr cpsr, r1
    mov pc, lr

    .global bye
    .type   bye,function
bye:    
    mrs r1, cpsr
    orr r1, r1, #0xc0   // Disable interrupts
    msr cpsr, r1

    mvn r2, #255        // 0xffffff00 - MCR_RCR
    mov r3, #1          // REMAP bit
    str r3, [r2, #0]    // Map the ROM back to 0
    b   0

.L1:
    .word   reset_reason

	// Some variables to help debug unexpected exceptions and resets
    .bss
    .align 2
    .global reset_reason
    .type   reset_reason,object
    .size   reset_reason,12
    .global old_pc
    .type   old_pc,object
    .size   old_pc,12
    .global old_cpsr
    .type   old_cpsr,object
    .size   old_cpsr,12
reset_reason:
    .space 4
old_pc:
    .space 4
old_cpsr:       
    .space 4
	
    .global first_to_clear
    .type   first_to_clear,object
    .size   first_to_clear,0

first_to_clear: 

    .ident  "GCC: (GNU) 3.2"
