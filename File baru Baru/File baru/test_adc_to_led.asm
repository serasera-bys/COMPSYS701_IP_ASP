; === TEST ADC to LED ===
; Read value from ADC (mapped at 0xA000) and display to LED (0x4100)

        ORG $0
        LDR R1, #0xA000     ; Load from ADC address
        STR R1, #0x4100     ; Store to LED address
        HLT