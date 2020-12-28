.global _start
count:
arr:	.word 4, 2, 1, 4, -1

_start:
	LDR	R0, =arr	//R0 is the starting address of arr
	MOV	R2, #0		//R2 is i
	MOV	R3, #5		//put n in R3
	SUB	R4, R3, #1	//R4 is bound of outer loop
OUTERLOOP:
	CMP	R2, R4
	BGE	END
	LDR	R1, [R0, R2, LSL#2]	//R1=tmp
	MOV	R5, R2		//R5 is cur_min_index
	ADD	R6, R2, #1	//R6=j
INNERLOOP:
	CMP	R6, R3
	BGE	SWAP	
	LDR	R7, [R0, R6, LSL#2]
	CMP	R1, R7
	BLE	INNERINCREMENT
	MOV	R1, R7
	MOV	R5, R6
INNERINCREMENT:
	ADD	R6, R6, #1
	B	INNERLOOP
SWAP:	
	LDR	R1, [R0, R2, LSL#2]	//temp
	MOV	R9, #4
	MLA	R8, R5, R9, R0	//address with min index
	LDR	R10, [R8]
	MLA	R9, R2, R9, R0	//R9 is address of ptr+ix4
	LDR	R11, [R9]
	STR	R10, [R9]
	STR	R11, [R8]

OUTERINCREMENT:
	ADD	R2, R2, #1
	B	OUTERLOOP

END:
	
