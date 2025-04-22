start:
NOOP ;starting the program
LDR R0 #0
count:
STR R0 $0x4000 ;store value to hex display
ADD R0 R0 #1
LDR R2 #65535 ;max register size, 16 bits
time:
LDR R3 $0x4200 ;load switch value
STR R3 $0x4100 ;store value to leds
SUBV R2 R2 #1
PRESENT R2 count ;if R2=0 go to count
JMP time
ENDPROG:
END:
