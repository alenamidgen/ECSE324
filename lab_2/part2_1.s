.global _start
.equ	LOAD, 0xFFFEC600
.equ	CONTROL, 0xFFFEC608
.equ	INTERRUPT, 0xFFFEC60C
.equ HEX3_0, 0xFF200020
.equ HEX5_4, 0xFF200030

_start:
	MOV	R2, #0	//count variable
	MOV	R0, #49664		//have to move in 2 parts since 200M is more than 16 bits
	MOVT	R0, #3051
	MOV	R1, #7				//moves 7 into R1, so that when configuring I=A=E=1
	BL	ARM_TIM_config_ASM	//configures timer
loop:
	BL	ARM_TIM_read_INT_ASM		//checks the value of F in interrupt
	CMP	R0, #1
	BEQ increment					//when F is 1, increments the count
	B	loop					//if not it keeps polling the loop
increment:
	BL	ARM_TIM_clear_INT_ASM	
	MOV	R0, #1
	ADD	R1, R2, #0			//moves R2 to R1
	BL	HEX_write_ASM
	ADD	R2, R2, #1
	CMP	R2, #16
	MOVEQ	R2, #0
	B	loop
	
ARM_TIM_config_ASM:
	PUSH	{R0-R4}			//push registers to use
	LDR	R2, =LOAD			//store what was put in R0 into the load register
	STR	R0, [R2]
	LDR	R2, =CONTROL		//get the value in the control register
	LDR	R3, [R2]
	AND	R4, R3, #15			//and with 15 and subtract to remove the last 3 bits
	SUB	R3, R3, R4
	ADD	R3, R3, R1			//add on the last 3 bits that were inputted in R1
	STR	R3, [R2]			//store back in the control register
	POP	{R0-R4}				//pop values and return
	BX	LR

ARM_TIM_read_INT_ASM:
	LDR	R0, =INTERRUPT		//get the interrupt
	LDR	R0, [R0]
	AND	R0, R0, #1			//and with 1 to get whether the last bit is 0 
	
ARM_TIM_clear_INT_ASM:
	PUSH	{R0, R1}
	LDR	R0, =INTERRUPT		//get the interrupt memory
	MOV	R1, #1				//put one in the interrupt memory
	STR	R1, [R0]
	POP	{R0, R1}			//pop the saved registers
	
HEX_write_ASM:
	PUSH	{R0-R10}
	//PUSH	{LR}
	//BL	HEX_clear_ASM			//clear the hexs that will be used
	//POP	{LR}
	MOV	R2, #0	//counter
	LDR	R4, =HEX3_0				//r4 = address in memory
	MOV	R7, #8			
	MOV	R10, #120
	MLA	R9, R1, R7, R10
	ADD	R9, R9, PC
	BX	R9		//branch to the address which moves the correct number into R9, depending on value entered in R1

loop_write:
	LDR	R6, [R4]				//r6 is current value in the memory
	AND	R3, R0, #1				//and with 1 to see if next bit is needed
	CMP	R3, #1					//if not increment
	BNE increment_write
	
implement:
	CMP	R2, #4					//if less than 4th iteration
	MULLT	R8, R2, R7			//multiply the counter by 8 for shift
	LSLLT	R10, R5, R8			//left shift the value needed to put into display so it aligns with empty space
	//R6 = value in memory
	
	LSRLT	R9, R6, R8			//right shift the value in memory
	ANDLT	R9, R9, #127		//and with 127 to only get the least significant 7 bits
	LSLLT	R9, R9, R8			//left shift back
	SUBLT	R6, R6, R9			//subtract this from the value that was in the memory
	ADDLT	R6, R6, R10			//add in the new value
	
	ANDEQ	R9, R6, #127		//AND with 127 to get last 8 bits
	SUBEQ	R6, R6, R9			//subtract from value in memory
	ADDEQ	R6, R6, R5			//add R5 to the empty space in the 4th display
	
	LSLGT	R10, R5, #8			//Similar steps for when it is the 5th iteration
	LSRGT	R9, R6, #8
	ANDGT	R9, R9, #127
	LSLGT	R9, R9, #8
	SUBGT	R6, R6, R9
	ADDGT	R6, R6, R10
	
	STR	R6, [R4]				//store it back 
	
increment_write:
	ADD	R2, R2, #1				//increment counter
	LSR	R0, R0, #1				//right shift the parameter
	
	CMP	R2, #4					//if fourth iteration is starting nex:
	LDREQ	R4, =HEX5_4			//set new memory to be that of HEX5_4
	
	CMP	R2, #6					//if not 6th iteration, start loop again
	BNE	loop_write		
	POP	{R0-R10}					//if 6th iteration, pop values and go back to LR
	BX	LR
//the following move the number corresponding to what must appear on the segment display for each to appear
zero:
	MOV	R5, #63
	B	loop_write
one:
	MOV	R5, #6
	B	loop_write
two:
	MOV	R5, #91
	B	loop_write
three:
	MOV	R5, #79
	B	loop_write
four:
	MOV	R5, #102
	B	loop_write
five:
	MOV	R5, #109
	B	loop_write
six:
	MOV	R5, #125
	B	loop_write
seven:
	MOV	R5, #7
	B	loop_write
eight:
	MOV	R5, #127
	B	loop_write
nine:
	MOV	R5, #103
	B	loop_write
ten:
	MOV	R5, #119
	B	loop_write
eleven:
	MOV	R5, #127
	B	loop_write
twelve:
	MOV	R5, #57
	B	loop_write
thirteen:
	MOV	R5, #63
	B	loop_write
fourteen:
	MOV	R5, #121
	B	loop_write
fifteen:
	MOV	R5, #113
	B	loop_write