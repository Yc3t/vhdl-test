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
            NAMEREG s7, temp        ; Temporary storage
            
            ADDRESS 00              ; Program starts at address 00

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Program start
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            DISABLE INTERRUPT
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

            ENABLE INTERRUPT        ; Enable interrupts for game input

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Main program loop
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main_loop:  LOAD temp, 09          ; Delay loop
delay:      SUB temp, 01
            JUMP NZ, delay
            JUMP main_loop         ; Loop forever

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Character reception routine
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
recibe:     INPUT rxreg, rs232
            AND rxreg, 80
            JUMP NZ, recibe
            CALL wait_05bit
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
transmite:  LOAD s0, 00
            OUTPUT s0, rs232
            CALL wait_1bit
            LOAD contbit, 08
next_tx_bit:
            OUTPUT txreg, rs232
            CALL wait_1bit
            SR0 txreg
            SUB contbit, 01
            JUMP NZ, next_tx_bit
            LOAD s0, FF
            OUTPUT s0, rs232
            CALL wait_1bit
            RETURN

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Timing routines
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wait_1bit:  LOAD cont1, 03  
espera2:    LOAD cont2, 22
espera1:    SUB cont2, 01
            JUMP NZ, espera1
            SUB cont1, 01
            JUMP NZ, espera2
            RETURN

wait_05bit: LOAD cont1, 03 
espera4:    LOAD cont2, 10
espera3:    SUB cont2, 01
            JUMP NZ, espera3
            SUB cont1, 01
            JUMP NZ, espera4
            RETURN

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Interrupt Service Routine
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ADDRESS FF
isr:        DISABLE INTERRUPT
            CALL recibe            ; Get character
            
            ; Echo received character
            LOAD txreg, rxreg
            CALL transmite
            
            ; Process game logic
            LOAD temp, rxreg       ; Save input
            SUB temp, 48          ; Convert from ASCII
            
            ; Compare with secret
            LOAD s0, temp         ; Load guess
            SUB s0, secret        ; Compare with secret
            JUMP Z, win           ; If zero, correct guess
            JUMP C, low           ; If carry, too low
            
high:       LOAD txreg, 72        ; 'H'
            CALL transmite
            JUMP end_isr
            
low:        LOAD txreg, 76        ; 'L'
            CALL transmite
            JUMP end_isr
            
win:        LOAD txreg, 42        ; '*'
            CALL transmite
            ADD secret, 01        ; New secret number
            AND secret, 07
            ADD secret, 01
            
end_isr:    LOAD txreg, 0D        ; CR
            CALL transmite
            LOAD txreg, 0A        ; LF
            CALL transmite
            RETURNI ENABLE
