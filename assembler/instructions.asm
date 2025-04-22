START:
    NOOP

    ; --- Register Initialization (R2, R4, R6, R8, R9) ---
    STR R5 $0x1000
    JMP R5
    DATACALL R5
    SSOP R5
    LDR R2, #0xABCD    ; R2 = 0xABCD
    LDR R4, #0x1357    ; R4 = 0x1357
    LDR R6, #0xAAAA    ; R6 = 0xAAAA
    LDR R8, #0x10F0    ; R8 = 0x10F0
    LDR R9, #0x00FF    ; R9 = 0x00FF

    ; --- AND Instructions ---
    AND R1, R2, #0x1234      ; R1 = R2 AND 0x1234
    AND R1, R1, R2           ; R1 = R1 AND R2

    ; --- OR Instructions ---
    OR R3, R4, #0x5678       ; R3 = R4 OR 0x5678
    OR R3, R3, R4            ; R3 = R3 OR R4

    ; --- ADD Instructions ---
    ADD R5, R6, #0x9ABC      ; R5 = R6 + 0x9ABC
    ADD R5, R5, R6           ; R5 = R5 + R6

    ; --- SUBV and SUB Instructions ---
    SUBV R7, R8, #0x10       ; R7 = R8 - 0x10
    SUB R9, #0x20           ; R9 = R9 - 0x20

    ; --- LDR and STR Instructions ---
    ; Initialization and store/load value to/from memory
    LDR   R10, #0xBEEF       ; R10 = 0xBEEF
    STR   R10, $0x5000       ; Store R10 to memory address 0x5000

    ; Clear register for verification
    LDR   R11, #0x0000       ; R11 = 0x0000
    LDR   R11, $0x5000       ; Load value from memory address 0x5000 into R11

    ; --- LDR with Register Mode ---
    LDR   R12, #0x6000       ; R12 = 0x6000 (as an address)
    STR   R10, $0x6000       ; Store R10 to memory address 0x6000
    LDR   R13, R12           ; Load value from address in R12 into R13

    ; --- STR with Register Mode ---
    LDR   R14, #0xCAFE       ; R14 = 0xCAFE
    LDR   R15, #0x7000       ; R15 = 0x7000 (as an address)
    STR   R14, R15           ; Store R14 to memory address contained in R15

    ; --- STR with Immediate Operand ---
    LDR   R16, #0xDEAD       ; R16 = 0xDEAD
    STR   R16, #0x8000       ; Store R16 to memory address 0x8000

    ; --- Testing Zero Flag and Branching ---
    ; Reinitialize registers for subsequent operations
    LDR   R1, #0x0001       ; R1 = 1
    LDR   R2, #0x0001       ; R2 = 1
    LDR   R3, #0x0000       ; R3 = 0 (for PRESENT usage)
    CLFZ                    ; Clear Zero Flag (Z = 0)

    ; Part 1: Operation affecting Zero Flag
    SUB   R1, #0x0001       ; R1 = R1 - 1 → Now R1 becomes 0, so Zero Flag (Z) is set to 1

    ; Part 2: Using SZ (if Z = 1, jump)
    SZ    #LABEL_IF_Z       ; If Z = 1, then PC <- LABEL_IF_Z; otherwise, continue
    NOOP                    ; NOOP if no jump

    ; Part 3: Unconditional jump
    JMP   #END_PROGRAM      ; Unconditionally jump to END_PROGRAM

LABEL_IF_Z:
    ; Part 4: PRESENT Instruction (conditional jump based on register value)
    ; If R3 equals 0, then jump
    PRESENT R3, #CHECK_PRES
    NOOP                    ; NOOP if not jumped
    JMP   #END_PROGRAM

CHECK_PRES:
    ; Part 5: Clear Zero Flag again
    CLFZ

    ; Part 6: DATACALL (example)
    LDR   R4, #0xAAAA       ; R4 = 0xAAAA
    LDR   R5, #0x00FF       ; R5 = 0x00FF
    DATACALL R4, R5         ; DPCR = R4 & R5 (e.g., DPCR = 0xAAAA & 0x00FF = 0x00AA)

    ; Part 7: JMP with register
    LDR   R6, #END_PROGRAM  ; R6 = address of END_PROGRAM
    JMP   R6

END_PROGRAM:
    NOOP                    ; End of program marker

    ; --- Additional Instructions ---
    STRPC $0x9000           ; STRPC with direct operand

    ; One-operand instructions (register mode)
    LSIP R9               ; LSIP R9: Load SIP value
    SSOP R10              ; SSOP R10: Set SOP

    ; NOOP Inherent
    NOOP                  ; NOOP

END:
