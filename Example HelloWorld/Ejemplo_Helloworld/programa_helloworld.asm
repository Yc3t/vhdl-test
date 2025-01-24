            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ;                 
            ; Number Guessing Game
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
            NAMEREG s6, secret      ; Secret number to guess
            NAMEREG s7, counter     ; Simple counter for pseudo-random number
            
            ADDRESS 00              ; Program starts at address 00

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Program start
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            DISABLE INTERRUPT
            
            ; Initialize game
start:      LOAD counter, 00        ; Initialize counter
            LOAD secret, 05         ; Initial secret number

            ; Send welcome message
            LOAD txreg, 35          ; '5' (ASCII 53)
            CALL transmite
            LOAD txreg, 32          ; '2' (ASCII 50)
            CALL transmite
            LOAD txreg, 13          ; CR
            CALL transmite
            LOAD txreg, 10          ; LF
            CALL transmite

game_loop:  CALL recibe            ; Get player's guess
            SUB rxreg, 48          ; Convert ASCII to number (ASCII '0' = 48)
            
            ; Compare with secret
            LOAD s0, rxreg
            COMPARE: SUB s0, secret
            JUMP Z, correct
            JUMP C, too_low
            
too_high:   LOAD txreg, 72         ; 'H'
            CALL transmite
            LOAD txreg, 13          ; CR
            CALL transmite
            LOAD txreg, 10          ; LF
            CALL transmite
            JUMP game_loop
            
too_low:    LOAD txreg, 76         ; 'L'
            CALL transmite
            LOAD txreg, 13          ; CR
            CALL transmite
            LOAD txreg, 10          ; LF
            CALL transmite
            JUMP game_loop
            
correct:    LOAD txreg, 42         ; '*' (ASCII 42)
            CALL transmite
            LOAD txreg, 13          ; CR
            CALL transmite
            LOAD txreg, 10          ; LF
            CALL transmite
            
            ; Generate new secret number for next game
            ADD counter, 01
            AND counter, 07         ; Keep in range 0-7
            LOAD secret, counter
            ADD secret, 01         ; Make sure it's not 0
            
            JUMP start             ; Start new game

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
