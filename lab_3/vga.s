.global _start
_start:
        bl      draw_test_screen
end:
        b       end

VGA_draw_point_ASM:
	//shifts the coordinates
	PUSH	{R0-R1}
	LSL	R1, R1, #10
	LSL	R0, R0, #1
	//adds them to the base address
	ADD	R1, R1, #0xc8000000
	ADD	R1, R0
	//stores the colour in the pixel
	STRH R2, [R1]
	POP	{R0-R1}
	BX	LR

VGA_clear_pixelbuff_ASM:
	PUSH	{R0-R2}
	MOV	R0, #0
	MOV	R1, #0
	MOV	R2, #0
	B	INNER_LOOP
	
	OUTER_LOOP:
	MOV	R0, #0
	ADD	R1, #1
	CMP	R1, #240
	POPEQ	{R0-R2}
	BXEQ	LR
	
	INNER_LOOP:
	CMP	R0, #320
	BEQ	OUTER_LOOP
	PUSH	{LR}
	BL	VGA_draw_point_ASM	
	POP	{LR}
	ADD	R0, #1
	B	INNER_LOOP

VGA_write_char_ASM:
	//making comparisons and branching back if coordinates aren't in range
	CMP	R0, #79
	BXGT	LR
	CMP R1, #59
	BXGT	LR
	CMP	R0, #0
	BXLT	LR
	CMP	R1, #0
	BXLT	LR
	
	//shifts the coordinates
	PUSH	{R0-R1}
	LSL	R1, R1, #7
	//adds them to the base address
	ADD	R1, R1, #0xc9000000
	ADD	R1, R0
	//stores the character in the pixel
	STRB R2, [R1]
	POP	{R0-R1}
	BX	LR
	
VGA_clear_charbuff_ASM:
	PUSH	{R0-R2}
	MOV	R0, #0
	MOV	R1, #0
	MOV	R2, #0
	B	INNER_LOOP_C
	
	OUTER_LOOP_C:
	MOV	R0, #0
	ADD	R1, #1
	CMP	R1, #240
	POPEQ	{R0-R2}
	BXEQ	LR
	
	INNER_LOOP_C:
	CMP	R0, #320
	BEQ	OUTER_LOOP_C
	PUSH	{LR}
	BL	VGA_write_char_ASM	
	POP	{LR}
	ADD	R0, #1
	B	INNER_LOOP_C

draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071
