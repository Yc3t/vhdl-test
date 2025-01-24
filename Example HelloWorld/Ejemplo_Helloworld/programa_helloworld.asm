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
            
            ADDRESS 00              ; Program starts at address 00

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Program start
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            DISABLE INTERRUPT
start:      CALL recibe            ; Wait for start character

            ; Initialize game
            LOAD secret, 05         ; Initial secret number

            ; Send welcome message
            LOAD txreg, 35          ; '5'
            CALL transmite
            LOAD txreg, 32          ; '2'
            CALL transmite
            LOAD txreg, 0D          ; CR
            CALL transmite
            LOAD txreg, 0A          ; LF
            CALL transmite

            ENABLE INTERRUPT
bucle1:     LOAD s6, 09            ; Main program loop
bucle2:     SUB s6, 01             ; like in programa_helloworld_int.asm
            JUMP NZ, bucle2
            LOAD s6, 09
            JUMP bucle2

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
            SUB rxreg, 48          ; Convert ASCII to number
            
            ; Compare with secret
            LOAD s0, rxreg
            SUB s0, secret
            JUMP Z, win
            JUMP C, low

high:       LOAD txreg, 72         ; 'H'
            CALL transmite
            JUMP end_isr

low:        LOAD txreg, 76         ; 'L'
            CALL transmite
            JUMP end_isr

win:        LOAD txreg, 42         ; '*'
            CALL transmite
            ADD secret, 01         ; Change secret number
            AND secret, 07
            ADD secret, 01

end_isr:    LOAD txreg, 0D         ; CR
            CALL transmite
            LOAD txreg, 0A         ; LF
            CALL transmite
            RETURNI ENABLE
