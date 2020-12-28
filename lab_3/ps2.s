.global _start
.equ	PS_2,	0xff200100
_start:
        bl      input_loop
end:
        b       end

@ TODO: copy VGA driver here.
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
@ TODO: insert PS/2 driver here.
read_PS2_data_ASM:
	//checks RVALID
	PUSH	{R1-R2}
	LDR	R1, =PS_2
	LDR	R1, [R1]
	LSR	R2, R1, #15
	AND	R2, R2, #1
	CMP	R2, #1
	//if not one, returns 0
	MOVNE	R0, #0
	POPNE	{R1-R2}
	BXNE	LR
	
	//otherwise gets the last 8 bits and stores it in the address in R0
	AND	R1, R1, #255
	STRB	R1, [R0]
	//returns a 1
	MOV	R0, #1
	POP	{R1-R2}
	BX	LR
	
write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}
