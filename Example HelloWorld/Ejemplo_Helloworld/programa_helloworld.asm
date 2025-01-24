            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ;                 
            ; Simple Echo Program
            ; 115200bps, 8 data bits, no parity, 1 stop bit, no flow control
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Constants and variables declaration
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                  
            CONSTANT rs232, FF       ; UART port
            
            NAMEREG s1, txreg       ; Transmission buffer
            NAMEREG s2, rxreg       ; Reception buffer
            NAMEREG s3, contbit     ; Bit counter
            NAMEREG s4, cont1       ; Delay counter 1
            NAMEREG s5, cont2       ; Delay counter 2
            
            ADDRESS 00              ; Program starts at address 00

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Program start
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            DISABLE INTERRUPT
start:      CALL recibe            ; Wait for character
            LOAD txreg, rxreg      ; Copy received character to transmit
            CALL transmite         ; Echo it back
            JUMP start             ; Loop forever

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
            ; 1-bit wait routine (115200 bps)
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wait_1bit:  LOAD cont1, 03  
espera2:    LOAD cont2, 22
espera1:    SUB cont2, 01
            JUMP NZ, espera1
            SUB cont1, 01
            JUMP NZ, espera2
            RETURN

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; 0.5-bit wait routine (115200 bps)
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wait_05bit: LOAD cont1, 03 
espera4:    LOAD cont2, 10
espera3:    SUB cont2, 01
            JUMP NZ, espera3
            SUB cont1, 01
            JUMP NZ, espera4
            RETURN

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Interrupt Service Routine
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ADDRESS FF
interrup:   DISABLE INTERRUPT
            CALL recibe
            LOAD txreg, rxreg
            CALL transmite
            RETURNI ENABLE
