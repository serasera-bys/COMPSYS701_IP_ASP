
; Program: Average ADC over 8 samples via NoC
; --------------------------------------------
; Tujuan: Membaca 8 sampel ADC dari NoC (ADC ASP), menghitung rata-rata,
;         dan menampilkan hasilnya ke alamat HEX ($4000)

ORG $0000

    LDR R6, #0       ; R6 = akumulator = 0
    LDR R7, #0       ; R7 = counter = 0

Loop:
    LSIP R2          ; R2 = data ADC dari NoC (reg_adc)
    ADD R6, R6, R2   ; Tambah ke akumulator
    ADD R7, R7, #1   ; Tambah counter

    LDR R1, #8
    SUB R1, R1, R7   ; R1 = 8 - counter
    SZ              ; Jika R1 = 0, berarti 8 sampel selesai
    JMP Loop        ; Jika belum, ulangi loop

    MOV R0, R6       ; Salin hasil ke R0
    SHRA R0, #3      ; Bagi 8 → average
    STR R0, #$4000   ; Simpan ke HEX_A ($4000)
    JMP $0000        ; Idle loop
