            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Program: Hamming Code Test with UART           
            ; Tests the Hamming encoder/decoder functionality
            ; 9600bps, 8 data bits, no parity, 1 stop bit, no flow control
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Constants and variables declaration
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            CONSTANT rs232, FF           ; UART port
            CONSTANT hamming_port, FE    ; Hamming module port
            
            NAMEREG s1, txreg           ; Transmission buffer
            NAMEREG s2, rxreg           ; Reception buffer
            NAMEREG s3, contbit         ; Bit counter
            NAMEREG s4, cont1           ; Delay counter 1
            NAMEREG s5, cont2           ; Delay counter 2
            NAMEREG s6, data_reg        ; Data for Hamming encoding
            NAMEREG s7, test_data       ; Test pattern counter
            
            ADDRESS 00                  ; Program starts at address 00

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Program start
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start:      LOAD test_data, 00         ; Initialize test pattern
            
test_loop:  ; Send test pattern marker
            LOAD txreg, 54              ; Send 'T' character (ASCII 54h = 'T')
            CALL transmite
            LOAD txreg, 3A              ; Send ':' character (ASCII 3Ah = ':')
            CALL transmite
            
            ; Test Hamming encoding
            LOAD data_reg, test_data    ; Load test pattern
            LOAD s0, 80                 ; Set encode bit
            OR data_reg, s0             ; Combine encode bit with data
            OUTPUT data_reg, hamming_port ; Send to Hamming encoder
            INPUT txreg, hamming_port   ; Read encoded result
            CALL transmite              ; Transmit encoded data
            
            ; Send newline
            LOAD txreg, 0D             ; Carriage return
            CALL transmite
            LOAD txreg, 0A             ; Line feed
            CALL transmite
            
            ; Increment test pattern
            ADD test_data, 01
            AND test_data, 0F          ; Keep in 4-bit range
            
            ; Delay between tests
            LOAD cont1, FF
delay1:     LOAD cont2, FF
delay2:     SUB cont2, 01
            JUMP NZ, delay2
            SUB cont1, 01
            JUMP NZ, delay1
            
            JUMP test_loop             ; Continue with next pattern

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Character reception routine
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
recibe:     ; Wait for start bit
            INPUT rxreg, rs232
            AND rxreg, 80
            JUMP NZ, recibe
            CALL wait_05bit
            ; Store 8 data bits
            LOAD contbit, 09
next_rx_bit:
            CALL wait_1bit
            SR0 rxreg
            INPUT s0, rs232
            AND s0, 80
            OR rxreg, s0
            SUB contbit, 01
            JUMP NZ, next_rx_bit
            RETURN

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Character transmission routine
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
transmite:  ; Send start bit
            LOAD s0, 00
            OUTPUT s0, rs232
            CALL wait_1bit
            ; Send 8 data bits
            LOAD contbit, 08
next_tx_bit:
            OUTPUT txreg, rs232
            CALL wait_1bit
            SR0 txreg
            SUB contbit, 01
            JUMP NZ, next_tx_bit
            ; Send stop bit
            LOAD s0, FF
            OUTPUT s0, rs232
            CALL wait_1bit
            RETURN

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; 1-bit wait routine (9600 bps)
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wait_1bit:  LOAD cont1, 0A             ; Adjusted for 9600 baud
espera2:    LOAD cont2, 80
espera1:    SUB cont2, 01
            JUMP NZ, espera1
            SUB cont1, 01
            JUMP NZ, espera2
            RETURN

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; 0.5-bit wait routine (9600 bps)
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wait_05bit: LOAD cont1, 05             ; Adjusted for 9600 baud
espera4:    LOAD cont2, 80
espera3:    SUB cont2, 01
            JUMP NZ, espera3
            SUB cont1, 01
            JUMP NZ, espera4
            RETURN
