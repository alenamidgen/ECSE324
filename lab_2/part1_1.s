.global _start
.equ SW_MEMORY, 0xFF200040
.equ LED_MEMORY, 0xFF200000

_start:

loop:
	BL	read_slider_switches_ASM		//links to read the switches
	BL	write_LEDs_ASM					//links to write to the LEDs
	B	loop							//loops to the beginning of the loop again

//subroutines given in the lab
read_slider_switches_ASM:
    LDR R1, =SW_MEMORY
    LDR R0, [R1]
    BX  LR
	
write_LEDs_ASM:
    LDR R1, =LED_MEMORY
    STR R0, [R1]
    BX  LR
