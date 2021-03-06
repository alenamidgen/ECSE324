.global _start
.equ	LOAD, 0xFFFEC600
.equ	CONTROL, 0xFFFEC608
.equ	INTERRUPT, 0xFFFEC60C
.equ HEX3_0, 0xFF200020
.equ HEX5_4, 0xFF200030
.equ DATA_REG, 0xFF200050
.equ	EDGECAP_REG, 0xFF20005C
timeout:	.word 2000000

_start:
	BL	PB_clear_edgecp_ASM
	MOV	R2, #1			//count variables for HEX0-5
	MOV	R3, #1			
	MOV	R4, #1			
	MOV	R5, #1
	MOV	R6, #1
	MOV	R7, #1
	
	MOV	R0, #63				//sets up the hex by getting all to display 0
	MOV	R1, #0
	BL	HEX_write_ASM
	
//waiting for start to be pressed
wait_to_start:	
	//if reset is pressed, go to reset_pressed
	MOV	R0, #4
	BL	PB_data_is_pressed_ASM
	CMP	R0, #1
	BEQ	reset_pressed
	
	//if stop is pressed, must wait to start
	MOV	R0, #2
	BL	PB_data_is_pressed_ASM
	CMP	R0, #1
	BEQ	wait_to_start
	
	//if stop is not pressed, but start is pressed, go to start_pressed
	MOV	R0, #1
	BL	PB_data_is_pressed_ASM
	CMP	R0, #0
	BNE	start_pressed
	
	B	wait_to_start	//otherwise, still waiting for start to be pressed
	
	
start_pressed:	
	LDR	R0, =timeout		//getting the number to count from into R0
	LDR	R0, [R0]
	MOV	R1, #3				//moves 3 into R1, so that when configuring A=E=1
	BL	ARM_TIM_config_ASM
	B	loop
	
	
reset_pressed:
	LDR	R0, =timeout		//getting the number to count from into R0
	LDR	R0, [R0]
	MOV	R1, #2				//moves 2 into R1, so that E=0
	BL	ARM_TIM_config_ASM
	MOV	R2, #1			//count variables for HEX0-5
	MOV	R3, #1			
	MOV	R4, #1			
	MOV	R5, #1
	MOV	R6, #1
	MOV	R7, #1
	MOV	R0, #63				//resets the hex by getting all to display 0
	MOV	R1, #0
	BL	HEX_write_ASM
	BL	PB_clear_edgecp_ASM
	//checking if reset is pressed
	MOV	R0, #4
	BL	PB_data_is_pressed_ASM
	CMP	R0, #1					//if reset is still pressed, stay in loop
	BEQ	reset_pressed
	B	wait_to_start			//if reset isn't pressed, go to wait_to_start

loop:
	MOV	R0, #2
	BL	PB_data_is_pressed_ASM
	CMP	R0, #1
	BEQ	wait_to_start				//if stop is pressed, go to wait_to_start
	
	MOV	R0, #4
	BL	PB_data_is_pressed_ASM		//if reset is pressed, go to reset_pressed
	CMP	R0, #1
	BEQ	reset_pressed
	
	BL	ARM_TIM_read_INT_ASM		//checks the value of F in interrupt
	CMP	R0, #1
	BEQ increment_HEX0				//when F is 1, increments the count
	B	loop					//if not it keeps polling the loop
	

//the following labels indicate the incrementing of each hex, this is 
//done when the hex before reaches its max value
//it checks to see if it is at its max, and if so it resets to 0 so on 
//its next iteration it can go to the next hex increment label
//returns to the loop every time
increment_HEX0:
	BL	ARM_TIM_clear_INT_ASM		//resets F=0
	MOV	R0, #1						
	ADD	R1, R2, #0	//moves R2 to R1
	
	BL	HEX_write_ASM
	CMP	R2, #0
	BEQ increment_HEX1
	ADD	R2, R2, #1
	CMP	R2, #10
	MOVEQ	R2, #0
	
	B	loop
	
increment_HEX1:
	ADD	R2, R2, #1
	MOV	R0, #2
	ADD	R1, R3, #0
	BL	HEX_write_ASM
	
	CMP	R3, #0
	BEQ	increment_HEX2
	ADD	R3, R3, #1
	CMP	R3, #10
	MOVEQ	R3, #0
	
	B	loop
increment_HEX2:
	ADD	R3, R3, #1
	MOV	R0, #4
	ADD	R1, R4, #0
	BL	HEX_write_ASM
	CMP	R4, #0
	BEQ	increment_HEX3
	ADD	R4, R4, #1
	CMP	R4, #10
	MOVEQ	R4, #0
	
	B	loop
increment_HEX3:
	ADD	R4, R4, #1
	MOV	R0, #8
	ADD	R1, R5, #0
	BL	HEX_write_ASM
	CMP	R5, #0
	BEQ	increment_HEX4
	ADD	R5, R5, #1
	CMP	R5, #6
	MOVEQ	R5, #0
	
	B	loop
increment_HEX4:
	ADD	R5, R5, #1
	MOV	R0, #16
	ADD	R1, R6, #0
	BL	HEX_write_ASM
	CMP	R6, #0
	BEQ	increment_HEX5
	ADD	R6, R6, #1
	CMP	R6, #10
	MOVEQ	R6, #0
	
	B	loop
increment_HEX5:
	ADD	R6, R6, #1
	MOV	R0, #32
	ADD	R1, R7, #0
	BL	HEX_write_ASM
	ADD	R7, R7, #1
	CMP	R7, #16
	BEQ	end
	B	loop
end:
	B	end

PB_data_is_pressed_ASM:	
	PUSH {R1}
	LDR R1, =DATA_REG	
	LDR R1, [R1]				// gets value of data register and puts it in R1
	ANDS	R0, R1				//does the and with the argument and value of data register
	MOVEQ	R0, #0				//if it's zero, puts 0 in R0 and returns
	MOVNE	R0, #1				//if it's not zero, puts 1 in R0 and returns
	POP {R1}	
	BX LR 		

PB_edgecp_is_pressed_ASM:	
	PUSH {R1}
	LDR R1, =EDGECAP_REG	
	LDR R1, [R1]				// gets value of edge register and puts it in R1
	ANDS	R0, R1				//does the and with the argument and value of edgecap register
	MOVEQ	R0, #0				//if it's zero, puts 0 in R0 and returns
	MOVNE	R0, #1				//if it's not zero, puts 1 in R0 and returns
	POP {R1}	
	BX LR 
	
PB_clear_edgecp_ASM:
	PUSH	{R0, R1}
	LDR	R1, =EDGECAP_REG
	LDR	R0, [R1]				//stores value in edgecap register in R0
	STR	R0, [R1]				//writes this value back into edgecap register
	POP	{R0, R1}
	BX	LR	

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
	BX	LR
	
ARM_TIM_clear_INT_ASM:
	PUSH	{R0, R1}
	LDR	R0, =INTERRUPT		//get the interrupt memory
	MOV	R1, #1				//put one in the interrupt memory
	STR	R1, [R0]
	POP	{R0, R1}			//pop the saved registers
	BX	LR
	
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
	