///////////////////////////////////////////////////////////////////////////////
// Reset, interrupt, and exception handlers.  This is the first code
// the program executes after startup.  It's also entered by exceptions
// and interrupts.  In any case, the action is to save (for debugging
// purposes) information about how we got here, then set up a stack and
// call main().
// 
// Author: Mitch Bradley
///////////////////////////////////////////////////////////////////////////////

// #define RAMBASE 0x106000
// #define RAMSIZE (128 * 1024)
// #define RAMTOP 0x1100000
// RAMTOP is defined externally by targets.mk

// #include "regs.h"
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
    mov r2, #0          // Code indicating how we got to main:	0 is default (normal)
dorestart:      
    ldr r1, .L1         // Get address of reset_reason storage area
    str r2, [r1, #0]    // Save a copy of the reset reason
    str r14, [r1, #4]   // Save a copy of the old PC

    mrs r5, cpsr
    str r5, [r1, #8]    // Save a copy of the mode that got us here
    orr r5, r5, #0xdf   // System mode (0x1f), Disable interrupts (0xc0)
    msr cpsr, r5        // Now we should be back to a clean mode

    ldr sp, =RAMTOP

#if STALLER1
stall:
    mov r2, #2
    str r2, [r3, #0x30]
    str r2, [r3, #0x34]
    b stall
#endif

clear_bss:	
    ldr     r0,.LBSS
    ldr	    r1,.LBSSEND
    mov     r2,#0
clear_bss_loop:
    str     r2,[r0],#4
    cmp	    r0,r1
    blo     clear_bss_loop

    bl      main
dead:
    b       dead
    

doirq:
    ldr     sp, irqstacktop
    subs    lr, lr, #4  // Adjust the return address and
    stmfd   sp!, {lr}   // save it on the stack.
    mrs     r14, SPSR   // Save SPSR
    stmfd   sp!, {r0-r3,r12,r14}  // on the stack.
    bl      irq_handler // Call the high level handler.
    ldmfd   sp!, {r0-r3,r12,r14}  // Unstack and
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
    ldr   sp, .L1
    add   sp, sp, #12         // Point to old_r0
    stmia sp!, {r0-r12}
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
    swi 0
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
    b   _start

#This is a bit subtle.  It assumes that the interrupt handling code
#will ultimately run from Tightly Coupled Memory instead of from SRAM.
#We allocate the IRQ stack inside the text segment so it will land in
#TCM when we copy the code into TCM.
#TCM starts at address 0, so we have to relocate the IRQ stack address
#down to be 0-based, by subtracting the base address of the image (_start)
irqstack:
    .space IRQSTACKSIZE
irqstacktop:
    .word  irqstacktop - _start

.L1:
    .word   reset_reason
.LBSS:
    .word   __bss_start__
.LBSSEND:
    .word   __bss_end__

	// Some variables to help debug unexpected exceptions and resets
    .data
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
old_r0:
    .space 4
    .space 4
    .space 4
    .space 4
    .space 4
    .space 4
    .space 4
    .space 4
    .space 4
    .space 4
    .space 4
    .space 4
    .space 4
	
    .global first_to_clear
    .type   first_to_clear,object
    .size   first_to_clear,0

first_to_clear: 

    .ident  "GCC: (GNU) 3.2"
