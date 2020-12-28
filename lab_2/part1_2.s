.global _start
.equ SW_MEMORY, 0xFF200040
.equ LED_MEMORY, 0xFF200000
.equ HEX3_0, 0xFF200020
.equ HEX5_4, 0xFF200030
.equ DATA_REG, 0xFF200050
.equ	EDGECAP_REG, 0xFF20005C
.equ	INTERM_REG, 0xFF200058

_start:
	MOV	R0, #15
	BL	HEX_clear_ASM
	MOV	R0, #48
	BL	HEX_flood_ASM
loop:
	BL	read_slider_switches_ASM		//links to read the switches
	BL	write_LEDs_ASM					//links to write to the LEDs
								//R0 holds the value in the switches memory
	AND	R1, R0, #15				//and it with 15 to get the value of the last 4 switches, store it in R1 to input to next subroutine
	BL	read_PB_data_ASM		//gets the push buttons in R0

	BL	HEX_write_ASM			//writes to the hex segments with the given R0 and R1
	B	loop					//loops back

read_slider_switches_ASM:
   	PUSH	{R1}
	LDR R1, =SW_MEMORY
    LDR R0, [R1]
	POP	{R1}
    BX  LR
	
write_LEDs_ASM:
    PUSH	{R1}
	LDR R1, =LED_MEMORY
    STR R0, [R1]
	POP	{R1}
    BX  LR
	
HEX_clear_ASM:
	PUSH {R0-R8}
	MOV	R2, #0	//counter
	MOV	R7, #8
	LDR	R4, =HEX3_0
	
loop_clear:
	LDR	R1, [R4]				//r1 is current value in the memory
	MOV	R5, #127
	AND	R3, R0, #1				//and with 1 to see if next bit is needed
	CMP	R3, #1					//if not increment
	BNE increment_clear
	
	CMP	R2, #4					//following to be done with hex 0-3
	MULLT	R6, R2, R7			//multiply iteration by 8 for shift
	LSRLT	R8, R1, R6			//right shift the value in memory
	ANDLT	R8, R8, #127		//and with 127 to only get the least significant 7 bits
	LSLLT	R8, R8, R6			//left shift back
	SUBLT	R1, R1, R8			//subtract this from the value that was in the memory
	STRLT	R1, [R4]			//put the new r1 in memory
	
	ANDEQ	R8, R1, #127		//to be done on 4th iteration: 
	SUBEQ	R1, R1, R8			//get last 7 bits of value in memory, subtract so they're all 0
	STREQ	R1, [R4]			//store in memory
	
	LSRGT	R8, R1, #8			//to be done on 5th iteration:
	ANDGT	R8, R8, #127		//right shift by 8, and with 127 to get the 7 bits needed 
	LSLGT	R8, R8, #8			//left shift back
	SUBGT	R1, R1, R8			//subtract from r1 
	STRGE	R1, [R4]			//store new value in memory

increment_clear:
	ADD	R2, R2, #1
	LSR	R0, R0, #1
	
	CMP	R2, #4
	LDREQ	R4, =HEX5_4
	
	CMP	R2, #6
	BNE	loop_clear
	POP	{R0-R8}
	BX	LR
	
HEX_flood_ASM:
	PUSH {R0-R7}				//callee save convention
	MOV	R2, #0	//counter
	MOV	R7, #8					
	LDR	R4, =HEX3_0				//r4 = address in memory
loop_flood:
	LDR	R1, [R4]				//r1 is current value in the memory
	MOV	R5, #127
	AND	R3, R0, #1				//and with 1 to see if next bit is needed
	CMP	R3, #1					//if not increment
	BNE increment_flood
	
	CMP	R2, #4					//following to be done with hex 0-3
	MULLT	R6, R2, R7			//multiply iteration by 8 for shift
	LSLLT	R5, R5, R6			//left shift 127 
	ORRLT	R1, R1, R5			//or with value in memory, this will get all 1's where we need to flood
	STRLT	R1, [R4]			//put the new r1 in memory
	
	ORREQ	R1, R1, #127		//to be done on 4th iteration: 
	STREQ	R1, [R4]			//or with 127 and store in memory
	
	LSLGT	R5, R5, R7			//to be done on 5th iteration:
	ORRGT	R1, R1, R5			//left shift 127 by 8, or with value in memory 
	STRGE	R1, [R4]			//store new value in memory

increment_flood:
	ADD	R2, R2, #1				//increment counter
	LSR	R0, R0, #1				//right shift the parameter
	
	CMP	R2, #4					//if fourth iteration is starting nex:
	LDREQ	R4, =HEX5_4			//set new memory to be that of HEX5_4
	
	CMP	R2, #6					//if not 6th iteration, start loop again
	BNE	loop_flood		
	POP	{R0-R7}					//if 6th iteration, pop values and go back to LR
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
	
read_PB_data_ASM:		
	PUSH {R1}				//pushes the registers it uses
	LDR R1, =DATA_REG			//loads memory from the data register of the push buttons into R0
	LDR R0, [R1]
	POP {R1}
	BX LR 						//pops R1 and returns

PB_data_is_pressed_ASM:	
	PUSH {R1}
	LDR R1, =DATA_REG	
	LDR R1, [R1]				// gets value of data register and puts it in R1
	ANDS	R0, R1				//does the and with the argument and value of data register
	MOVEQ	R0, #0				//if it's zero, puts 0 in R0 and returns
	MOVNE	R0, #1				//if it's not zero, puts 1 in R0 and returns
	POP {R1}	
	BX LR 				

read_PB_edgecp_ASM:
	PUSH {R0-R1}				//pushes registers it uses
	LDR R1, =EDGECAP_REG	
	LDR R0, [R1]				// loades memory from the edgecapture register into R0 and returns
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
	
enable_PB_INT_ASM:
	PUSH	{R1}
	LDR	R1, =INTERM_REG			//puts the inputted value in the memory
	STR	R0, [R1]
	POP	{R1}
	BX	LR
	
disable_PB_INT_ASM:
	PUSH	{R1, R2}
	LDR	R1, =INTERM_REG
	EOR	R2, R0, #15 			//does exclusive or with 15 to get the inverted number from R0
	STR	R2, [R1]				//stores this in the memory
	POP	{R1, R2}
	BX	LR
