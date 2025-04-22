; === Average 8 ADC Samples ===
ORG $0

MOV R1, #0xA000     ; Base address of ADC
MOV R2, #0          ; Accumulator (total)
MOV R3, #8          ; Number of samples
MOV R4, #0          ; Loop counter

LOOP:
LDR R5, (R1)        ; Read ADC sample
ADD R2, R2, R5      ; Add to total
ADD R1, R1, #16     ; Move to next ADC channel (offset 0x10)
ADD R4, R4, #1
CMP R4, R3
JNZ LOOP

DIV R2, R2, R3      ; Compute average
STR R2, #0x4100     ; Output to LED
HLT