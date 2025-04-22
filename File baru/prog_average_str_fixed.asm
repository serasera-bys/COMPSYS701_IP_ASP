; Program: Average ADC over 8 samples via NoC
; --------------------------------------------
; Tujuan: Membaca 8 sampel ADC yang dikirim melalui NoC (ADC_DATA)
;         melalui reg_adc (via LSIP), menghitung rata-rata,
;         dan menampilkan hasil ke HEX display

ORG $0000

        ; Inisialisasi akumulator dan counter
        LDR R6, #0       ; R6 = akumulator = 0
        LDR R7, #0       ; R7 = counter = 0

Loop:
        ; ===== KOMUNIKASI DENGAN NOC =====
        ; Ambil data dari NoC (reg_adc) → diterima dari ADC ASP via NoC
        LSIP R2          ; R2 = data ADC dari NoC (reg_adc)

        ; ===== AKUMULASI =====
        ADD R6, R6, R2   ; Tambah ke akumulator
        ADD R7, R7, #1   ; Tambah counter

        ; ===== CEK AKHIR SAMPEL =====
        LDR R1, #8
        SUB R1, R1, R7   ; R1 = 8 - counter
        SZ              ; Jika hasil = 0, berarti sudah 8 sampel
        JMP Loop        ; Jika belum 8, lanjut loop

        ; ===== PERHITUNGAN RATA-RATA =====
        ; R6 = total, kita ingin R6 / 8 → shift right 3 bit
        MOV R0, R6       ; Salin hasil total ke R0
        SHRA R0, #3      ; R0 = R6 >> 3 (bagi 8)

        ; ===== OUTPUT KE HEX A =====
        STR R0, #$4000   ; Simpan hasil ke hex_a_addr (alamat langsung)

        ; Program selesai → loop idle
        JMP $0000
