.global _start

count:
arr:	.word 3, 4, 5, 4

_start:
	MOV	R0, #4	//length
	MOV	R1, #0	//mean
	MOV	R2, #1	//1 for left shift
	MOV	R3, #0	//log2_n

CALCLOG:	
	ADD	R3, R3, #1
	LSL	R4, R2, R3
	CMP	R4, #4
	BLT	CALCLOG
	LDR	R5, =arr	//setting pointer
	MOV	R6, #0	//i=0
	
CALCMEAN:
	CMP	R6, R0
	BGE	MID
	LDR	R7, [R5], #4
	ADD	R1, R1, R7
	ADD	R6, R6, #1
	B	CALCMEAN
MID:
	ASR	R1, R1, R3
	LDR	R5, =arr
	MOV	R6, #0
	B	CENTER
CENTER:
	CMP	R6, R0
	BGE	END
	LDR	R8, [R5]
	SUB	R8, R8, R1
	STR	R8, [R5]
	ADD	R5, R5, #4
	B	CENTER
END:	
	_end:
	
	
	