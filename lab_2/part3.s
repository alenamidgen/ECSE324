.section .vectors, "ax"
B _start
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0 // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector

.text
.global _start

PB_int_flag :	.word 0x0
tim_int_flag :	.word 0x0
.equ	LOAD, 0xFFFEC600
.equ	CONTROL, 0xFFFEC608
.equ	INTERRUPT, 0xFFFEC60C
.equ HEX3_0, 0xFF200020
.equ HEX5_4, 0xFF200030
.equ DATA_REG, 0xFF200050
.equ	EDGECAP_REG, 0xFF20005C
timeout	:	.word 2000000
_start:
    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV        R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR        CPSR_c, R1           // change to IRQ mode
    LDR        SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 onchip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV        R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR        CPSR, R1             // change to supervisor mode
    LDR        SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL     CONFIG_GIC           // configure the ARM GIC
    // To DO: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
    // to enable interrupt for ARM A9 private timer, use ARM_TIM_config_ASM subroutine
   
	LDR        R0, =0xFF200050      // pushbutton KEY base address
    MOV        R1, #0xF             // set interrupt mask bits
    STR        R1, [R0, #0x8]       // interrupt mask register (base + 8)
    LDR	R0, =timeout			//using timeout value to sync timer with tens of ms
	LDR	R0, [R0]
	MOV	R1, #7					//want I=A=E=1
	BL	ARM_TIM_config_ASM		//configure timer
	// enable IRQ interrupts in the processor
    MOV        R0, #0b01010011      // IRQ unmasked, MODE = SVC
    MSR        CPSR_c, R0
IDLE:

	MOV	R2, #1				//count variables for HEX0-5
	MOV	R3, #1			
	MOV	R4, #1			
	MOV	R5, #1
	MOV	R6, #1
	MOV	R7, #1
	
	MOV	R0, #63				//sets up the hex by getting all to display 0
	MOV	R1, #0
	BL	HEX_write_ASM
	
wait_to_start:	
	//if reset is pressed, go to reset_pressed
	LDR	R0, =PB_int_flag
	LDR	R0, [R0]
	AND	R1, R0, #4
	CMP	R1, #4
	BEQ	reset_pressed
	
	//if stop is pressed, must wait to start
	AND	R1, R0, #2
	CMP	R1, #2
	BEQ	wait_to_start
	
	//if stop is not pressed, but start is pressed, go to start_pressed
	AND	R1, R0, #1
	CMP	R1, #1
	BEQ	start_pressed
	
	B	wait_to_start
	//B	wait
start_pressed:	
	LDR	R0, =timeout		//getting the number to count from into R0
	LDR	R0, [R0]
	MOV	R1, #7				//moves 7 into R1, so that when configuring I=A=E=1
	BL	ARM_TIM_config_ASM	
	MOV	R0, #1				//want to set the timer interrupt flag back to 1
	LDR	R1, =tim_int_flag
	STR	R0, [R1]
	MOV	R0, #0				//want to clear the push button interrupt flag
	LDR	R1, =PB_int_flag
	STR	R0, [R1]
	B	wait
	
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
	MOV	R0, #1				//want to set the timer interrupt flag back to 1
	LDR	R1, =tim_int_flag
	STR	R0, [R1]
	MOV	R0, #0				//want to clear the push button interrupt flag
	LDR	R1, =PB_int_flag
	STR	R0, [R1]
	
	B	wait_to_start			//goes back to wait_to_start

wait:
	
	LDR	R0, =PB_int_flag
	LDR	R0, [R0]
	AND	R1, R0, #4
	CMP	R1, #4
	BEQ	reset_pressed
	
	//if stop is pressed, must wait to start
	AND	R1, R0, #2
	CMP	R1, #2
	BEQ	wait_to_start
	
	LDR	R0, =tim_int_flag
	LDR	R0, [R0]
	CMP	R0, #1
	BEQ	increment_HEX0			//when F is 1, increments the count
	B	wait

increment_HEX0:
	BL	ARM_TIM_clear_INT_ASM		//resets F=0
	MOV	R0, #0
	LDR	R1, =tim_int_flag
	STR	R0, [R1]
	MOV	R0, #1						
	ADD	R1, R2, #0	//moves R2 to R1
	
	BL	HEX_write_ASM
	CMP	R2, #0
	BEQ increment_HEX1
	ADD	R2, R2, #1
	CMP	R2, #10
	MOVEQ	R2, #0
	
	B	wait
	
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
	
	B	wait
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
	
	B	wait
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
	
	B	wait
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
	
	B	wait
increment_HEX5:
	ADD	R6, R6, #1
	MOV	R0, #32
	ADD	R1, R7, #0
	BL	HEX_write_ASM
	ADD	R7, R7, #1
	CMP	R7, #16
	BEQ	end
	B	wait
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






/*--- Undefined instructions ---------------------------------------- */
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ------------------------------------------- */
SERVICE_SVC:
    B SERVICE_SVC
/*--- Aborted data reads -------------------------------------------- */
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch ------------------------------------- */
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ----------------------------------------------------------- */
SERVICE_IRQ:
    PUSH {R0-R7, LR}
/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR

/* To Do: Check which interrupt has occurred (check interrupt IDs)
   Then call the corresponding ISR
   If the ID is not recognized, branch to UNEXPECTED
   See the assembly example provided in the De1-SoC Computer_Manual on page 46 */
 
 Private_timer_check:  
   CMP	R5, #29
   BNE	Pushbutton_check
   BL	ARM_TIM_ISR
   B	EXIT_IRQ
 Pushbutton_check:
    CMP R5, #73
UNEXPECTED:
    BNE UNEXPECTED      // if not recognized, stop here
    BL KEY_ISR
EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
SUBS PC, LR, #4
/*--- FIQ ----------------------------------------------------------- */
SERVICE_FIQ:
    B SERVICE_FIQ

CONFIG_GIC:
    PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* To Do: you can configure different interrupts
   by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
	
	MOV R0, #29            // KEY port (Interrupt ID = 29)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT

/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}

/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}
	
KEY_ISR:
	PUSH	{R0-R2}
//setting the flag
	LDR R0, =0xFF200050    // base address of pushbutton KEY port
    LDR R1, [R0, #0xC]     // read edge capture register
    LDR	R2, =PB_int_flag 
	STR	R1, [R2]

//clearing the interrupt
	MOV R2, #0xF			
    STR R2, [R0, #0xC]     // clear the interrupt
    POP	{R0-R2}
	
END_KEY_ISR:
    BX LR

ARM_TIM_ISR:
	PUSH	{R0-R2}
//setting the interrupt	
	LDR	R0, =tim_int_flag
	LDR	R1, =INTERRUPT
	LDR	R1, [R1]			//get last bit of interrupt, store in tim_int_flag
	AND	R1, R1, #1
	STR	R1, [R0]
	PUSH	{LR}
	BL	ARM_TIM_clear_INT_ASM
	POP	{LR}
//removing the interrupt
	MOV	R2, #1
	LDR	R1, =INTERRUPT		//
	STR	R2, [R1]
	POP	{R0-R2}
	BX	LR
	