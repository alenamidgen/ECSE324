.global _start

count:
Xi:	.word 1
a:	.word 168
cnt:	.word 100
x:	.space 4

_start:
	LDR	R0, Xi
	LDR	R1, a
	LDR	R2, cnt
	BL sqrtRecur

sqrtRecur:

	CMP	R2, #0
	BEQ	END
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
	STR	LR, [SP, #-4]!
	SUB	R2, R2, #1
	B	sqrtRecur
	LDR	LR, [SP], #4
END: 
	STR	R0, x
	BX	LR