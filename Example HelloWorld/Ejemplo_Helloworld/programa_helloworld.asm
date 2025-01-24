            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Program: Hamming Code Test           
            ; Tests the Hamming encoder/decoder functionality
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            
            CONSTANT hamming_port, FE    ; Port for Hamming module
            CONSTANT uart_port, FF       ; UART port
            
start:      ; Test Hamming encoding
            LOAD s0, 05                  ; Load test data (0101)
            LOAD s1, 80                  ; Set encode bit
            OR s0, s1                    ; Combine encode bit with data
            OUTPUT s0, hamming_port      ; Send to Hamming encoder
            INPUT s2, hamming_port       ; Read encoded result
            
            ; Send result over UART
            CALL transmit_byte
            
            JUMP start                   ; Loop forever

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Transmit byte routine
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
transmit_byte:
            OUTPUT s2, uart_port         ; Send byte
            RETURN

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; End of program
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
