.global _start

count:
arr:	.word 5, 6, 7, 8
_start:
	
	MOV	R0, #1		//norm aka xi
	MOV	R1, #0		//temp aka a
	MOV	R2, #100	//cnt in both
	MOV	R3, #0		//log2_n
	MOV	R8, #1		//1 for left shift
	
WLOOP:	
	ADD	R3, R3, #1
	LSL	R4, R8, R3
	CMP	R4, #4
	BLT	WLOOP
	LDR	R5, =arr
	MOV	R6, #0		//i
FLOOP:
	CMP	R6, #4
	BGE	MID
	LDR	R7, [R5], #4
	MLA	R1, R7, R7, R1
	ADD	R6, R6, #1
	B	FLOOP
MID:
	ASR	R1, R1, R3
	STR	LR, [SP, #-4]!
	BL	sqrtIter
	LDR	LR, [SP]
	B	Finish
sqrtIter:
	//pushing register values
	STR	R3, [SP, #-4]!
	STR	R4, [SP, #-4]!
	STR	R5, [SP, #-4]!
	STR	R6, [SP, #-4]!
	STR	R7, [SP, #-4]!
	STR	R8, [SP, #-4]!
	MOV	R6, #0	//setting i=0
LOOP:
	//comparing i and cnt(R2)
	CMP	R6, R2
	BGE	END
	MUL	R4, R0, R0			//do the multiplication 
	SUB	R4, R4, R1			//do subtraction
	MUL	R4, R4, R0			//do the second mulitplication 
	ASR	R5, R4, #10			//shift right by K, store in R5
	CMP	R5, #2
	BLE	ELSE
	MOV R5, #2
	B	UPDATE
ELSE:
	CMP R5, #-2
	BGE UPDATE
	MOV R5, #-2
UPDATE:
	SUB R0, R0, R5	
	//increment i
	ADD	R6, R6, #1
	B	LOOP	
END: 
	LDR	R8, [SP], #4
	LDR	R7, [SP], #4
	LDR	R6, [SP], #4
	LDR	R5, [SP], #4
	LDR	R4, [SP], #4
	LDR	R3, [SP], #4
	BX	LR
Finish:
	.end