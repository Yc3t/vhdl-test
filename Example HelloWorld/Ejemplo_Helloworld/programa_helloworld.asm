            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ;                 
            ; Simon Says Game
            ; Shows a sequence that player must repeat
            ; 115200bps, 8 data bits, no parity, 1 stop bit, no flow control
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Constants and variables declaration
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                  
            CONSTANT rs232, FF       ; UART port
            
            NAMEREG s0, temp        ; Temporary register
            NAMEREG s1, txreg       ; Transmission buffer
            NAMEREG s2, rxreg       ; Reception buffer
            NAMEREG s3, contbit     ; Bit counter
            NAMEREG s4, cont1       ; Delay counter 1
            NAMEREG s5, cont2       ; Delay counter 2
            NAMEREG s6, sequence    ; Current position in sequence
            NAMEREG s7, pattern     ; Pattern to show/level
            
            ADDRESS 00              ; Program starts at address 00

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Program start
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            DISABLE INTERRUPT
            
start:      LOAD pattern, 41       ; Start with 'A'
            LOAD sequence, 01       ; Start with sequence length 1

show_seq:   LOAD temp, sequence    ; Initialize sequence counter
            
next_char:  LOAD txreg, pattern    ; Show current pattern
            CALL transmite
            LOAD txreg, 20         ; Space
            CALL transmite
            
            ; Delay between characters
            LOAD cont1, FF
wait1:      LOAD cont2, FF
wait2:      SUB cont2, 01
            JUMP NZ, wait2
            SUB cont1, 01
            JUMP NZ, wait1
            
            SUB temp, 01
            JUMP NZ, next_char
            
            ; End sequence with newline
            LOAD txreg, 0D         ; CR
            CALL transmite
            LOAD txreg, 0A         ; LF
            CALL transmite
            
            LOAD temp, sequence    ; Reset for input phase
            ENABLE INTERRUPT       ; Wait for player input

main_loop:  LOAD cont1, FF        ; Main program delay loop
loop1:      LOAD cont2, FF
loop2:      SUB cont2, 01
            JUMP NZ, loop2
            SUB cont1, 01
            JUMP NZ, loop1
            JUMP main_loop

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
            INPUT temp, rs232
            AND temp, 80
            OR rxreg, temp
            SUB contbit, 01
            JUMP NZ, next_rx_bit
            RETURN

            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Character transmission routine
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
transmite:  LOAD temp, 00
            OUTPUT temp, rs232
            CALL wait_1bit
            LOAD contbit, 08
next_tx_bit:
            OUTPUT txreg, rs232
            CALL wait_1bit
            SR0 txreg
            SUB contbit, 01
            JUMP NZ, next_tx_bit
            LOAD temp, FF
            OUTPUT temp, rs232
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
            
            ; Check if input matches pattern
            LOAD temp, rxreg
            SUB temp, pattern
            JUMP NZ, game_over
            
            SUB sequence, 01       ; One character matched
            JUMP Z, level_complete ; If sequence complete
            RETURNI ENABLE         ; Otherwise continue sequence
            
game_over:  LOAD txreg, 58        ; ':('
            CALL transmite
            LOAD txreg, 40
            CALL transmite
            LOAD txreg, 0D
            CALL transmite
            LOAD txreg, 0A
            CALL transmite
            JUMP start            ; Restart game
            
level_complete:
            LOAD txreg, 3A        ; ':)'
            CALL transmite
            LOAD txreg, 29
            CALL transmite
            LOAD txreg, 0D
            CALL transmite
            LOAD txreg, 0A
            CALL transmite
            
            ADD sequence, 01      ; Increase sequence length
            ADD pattern, 01       ; Change pattern
            JUMP show_seq        ; Show new sequence
