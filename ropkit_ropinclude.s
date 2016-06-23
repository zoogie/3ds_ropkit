#pragma once

#define ROP_BXR1 POP_R4LR_BXR1+4
#define ROP_BXLR ROP_LDR_R0FROMR0+4 //"bx lr"

#define ROP_EQBXLR_NE_CALLVTABLEFUNCPTR (IFile_Close+0x4) //Offset 0x4 in IFile_Close for ROP conditional execution. For condition-code EQ, bx-lr is executed, otherwise a vtable funcptr call with the r0 object is executed.

@ Size: 0x8
.macro ROP_SETR0 value
#ifdef POP_R0PC
	.word POP_R0PC
	.word \value
#elif defined (ROP_LDRR0SP_POPR3PC)
	.word ROP_LDRR0SP_POPR3PC
	.word \value
#else
	#error "The gadget for setting r0 is not defined."
#endif
.endm

@ Size: 0x8
.macro ROP_SETR1 value
.word POP_R1PC
.word \value @ r1
.endm

@ Size: 0x8 + 0xc (0x14)
.macro ROP_SETLR lr
ROP_SETR1 ROP_POPPC

.word POP_R4LR_BXR1
.word 0 @ r4
.word \lr
.endm

@ Size: 0x34
.macro ROP_SETLR_OTHER lr
.word POP_R2R6PC
.word ROP_POPPC @ r2
.word 0 @ r3
.word 0 @ r4
.word 0 @ r5
.word 0 @ r6

.word POP_R4R8LR_BXR2
.word 0 @ r4
.word 0 @ r5
.word 0 @ r6
.word 0 @ r7
.word 0 @ r8
.word \lr
.endm

@ Size: 0x14 + 0x8 + 0x4 (0x20)
.macro ROP_LOADR0_FROMADDR addr
ROP_SETLR ROP_POPPC

ROP_SETR0 \addr

.word ROP_LDR_R0FROMR0
.endm

.macro CALLFUNC funcadr, r0, r1, r2, r3, sp0, sp4, sp8, sp12
ROP_SETLR POP_R2R6PC

ROP_SETR0 \r0

ROP_SETR1 \r1

.word POP_R2R6PC
.word \r2
.word \r3
.word 0 @ r4
.word 0 @ r5
.word 0 @ r6

.word \funcadr

.word \sp0
.word \sp4
.word \sp8
.word \sp12
.word 0 @ r6
.endm

@ This is basically: CALLFUNC funcadr, *r0, r1, r2, r3, sp0, sp4, sp8, sp12
.macro CALLFUNC_LOADR0 funcadr, r0, r1, r2, r3, sp0, sp4, sp8, sp12
ROP_LOADR0_FROMADDR \r0

ROP_SETLR POP_R2R6PC

ROP_SETR1 \r1

.word POP_R2R6PC
.word \r2
.word \r3
.word 0 @ r4
.word 0 @ r5
.word 0 @ r6

.word \funcadr

.word \sp0
.word \sp4
.word \sp8
.word \sp12
.word 0 @ r6
.endm

@ This is basically: CALLFUNC funcadr, r0, *r1, r2, r3, sp0, sp4, sp8, sp12
.macro CALLFUNC_LDRR1 funcadr, r0, r1, r2, r3, sp0, sp4, sp8, sp12
ROP_SETLR ROP_POPPC

ROPMACRO_COPYWORD (ROPBUF + ((. + 0x40 + 0x14 + 0x8 + 0x4) - _start)), \r1

ROP_SETLR POP_R2R6PC

ROP_SETR0 \r0

ROP_SETR1 0 @ Overwritten by the above rop.

.word POP_R2R6PC
.word \r2
.word \r3
.word 0 @ r4
.word 0 @ r5
.word 0 @ r6

.word \funcadr

.word \sp0
.word \sp4
.word \sp8
.word \sp12
.word 0 @ r6
.endm

.macro CALLFUNC_NOSP funcadr, r0, r1, r2, r3
ROP_SETLR ROP_POPPC

ROP_SETR0 \r0

ROP_SETR1 \r1

.word POP_R2R6PC
.word \r2
.word \r3
.word 0 @ r4
.word 0 @ r5
.word 0 @ r6

.word \funcadr
.endm

@ This is is basically: CALLFUNC_NOSP funcadr, *r0, r1, r2, r3
.macro CALLFUNC_NOSP_LDRR0 funcadr, r0, r1, r2, r3
ROP_LOADR0_FROMADDR \r0

ROP_SETR1 \r1

.word POP_R2R6PC
.word \r2
.word \r3
.word 0 @ r4
.word 0 @ r5
.word 0 @ r6

.word \funcadr
.endm

@ This is is basically: CALLFUNC_NOSP funcadr, r0, r1, *r2, r3
.macro CALLFUNC_NOSP_LOADR2 funcadr, r0, r1, r2, r3
ROP_SETLR ROP_POPPC

ROPMACRO_COPYWORD (ROPBUF + ((. + 0x40 + 0x8 + 0x8 + 0x4) - _start)), \r2

ROP_SETR0 \r0

ROP_SETR1 \r1

.word POP_R2R6PC
.word \r2
.word \r3
.word 0 @ r4
.word 0 @ r5
.word 0 @ r6

.word \funcadr
.endm

.macro CALLFUNC_NOARGS funcadr
ROP_SETLR ROP_POPPC
.word \funcadr
.endm

.macro CALLFUNC_R0R1 funcadr, r0, r1
ROP_SETLR ROP_POPPC

ROP_SETR0 \r0

ROP_SETR1 \r1

.word \funcadr
.endm

.macro CALL_GXCMD4 srcadr, dstadr, cpysize
CALLFUNC GXLOW_CMD4, \srcadr, \dstadr, \cpysize, 0, 0, 0, 0, 0x8
.endm

@ This is basically: CALL_GXCMD4 *srcadr, dstadr, cpysize
.macro CALL_GXCMD4_LDRSRC srcadr, dstadr, cpysize
CALLFUNC_LOADR0 GXLOW_CMD4, \srcadr, \dstadr, \cpysize, 0, 0, 0, 0, 0x8
.endm

.macro ROPMACRO_STACKPIVOT_PREPARE sp, pc
@ Write to the word which will be popped into sp.
ROPMACRO_WRITEWORD (ROPBUF + (stackpivot_sploadword - _start)), \sp

@ Write to the word which will be popped into pc.
ROPMACRO_WRITEWORD (ROPBUF + (stackpivot_pcloadword - _start)), \pc
.endm

.macro ROPMACRO_STACKPIVOT sp, pc
ROPMACRO_STACKPIVOT_PREPARE \sp, \pc

ROPMACRO_STACKPIVOT_PREPAREREGS_BEFOREJUMP

ROPMACRO_STACKPIVOT_JUMP
.endm

.macro COND_THROWFATALERR
.word ROP_COND_THROWFATALERR

.word 0 @ r3
.word 0 @ r4
.word 0 @ r5
.endm

.macro ROPMACRO_CMPDATA cmpaddr, cmpword, stackaddr_cmpmismatch
ROP_SETLR ROP_POPPC

ROP_LOADR0_FROMADDR \cmpaddr

ROP_SETR1 \cmpword

.word ROP_CMPR0R1

ROPMACRO_STACKPIVOT_PREPARE \stackaddr_cmpmismatch, ROP_POPPC

ROPMACRO_STACKPIVOT_PREPAREREGS_BEFOREJUMP

ROP_SETR0 (ROPBUF + ((ropkit_cmpobject) - _start))

.word ROP_EQBXLR_NE_CALLVTABLEFUNCPTR @ When the value at cmpaddr matches cmpword, continue the ROP, otherwise call the vtable funcptr which then does the stack-pivot.
.endm

@ Size: 0x14 + 0x8 + 0x8 + 0x4 (0x28)
.macro ROPMACRO_WRITEWORD addr, value
ROP_SETLR ROP_POPPC

ROP_SETR0 \addr

ROP_SETR1 \value

.word ROP_STR_R1TOR0
.endm

@ Size: 0x14 + 0x20 + 0x8 + 0x4 (0x40)
.macro ROPMACRO_COPYWORD dstaddr, srcaddr
ROP_SETLR ROP_POPPC

ROP_LOADR0_FROMADDR \srcaddr

ROP_SETR1 \dstaddr

.word ROP_STR_R0TOR1
.endm

.macro ROPMACRO_LDDRR0_ADDR1_STRADDR dstaddr, srcaddr, value
ROP_LOADR0_FROMADDR \srcaddr

ROP_SETR1 \value

.word ROP_ADDR0_TO_R1 @ r0 = *srcaddr + value

ROP_SETR1 \dstaddr

.word ROP_STR_R0TOR1 @ Write the above r0 value to *dstaddr.
.endm

.macro ROPMACRO_IFile_Close IFile_ctx
ROP_LOADR0_FROMADDR \IFile_ctx

.word IFile_Close
.endm
