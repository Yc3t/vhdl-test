;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                 
; Higher/Lower Guessing Game
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
NAMEREG s6, current     ; Current number
NAMEREG s7, next        ; Next number

ADDRESS 00              ; Program starts at address 00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Program start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DISABLE INTERRUPT

start:  LOAD current, 01   ; Initial number

new_round:
        ; Send current number
        LOAD txreg, current
        ADD txreg, 30      ; Convert to ASCII
        CALL transmite
        LOAD txreg, 0D     ; CR
        CALL transmite
        LOAD txreg, 0A     ; LF
        CALL transmite

        ; Generate next number
        LOAD temp, current
        ADD temp, 43       ; Some "random" operation
        AND temp, 07       ; Keep it within 0-7
        ADD temp, 01       ; Make it 1-8
        LOAD next, temp

        ENABLE INTERRUPT   ; Wait for player input

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main program loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main_loop:
        LOAD cont1, FF     ; Some delay
loop1:  LOAD cont2, FF
loop2:  SUB cont2, 01
        JUMP NZ, loop2
        SUB cont1, 01
        JUMP NZ, loop1
        JUMP main_loop     ; Loop forever

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Character reception routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
recibe: INPUT rxreg, rs232
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
transmite:
        LOAD temp, 00
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
wait_1bit:
        LOAD cont1, 03  
espera2:
        LOAD cont2, 22
espera1:
        SUB cont2, 01
        JUMP NZ, espera1
        SUB cont1, 01
        JUMP NZ, espera2
        RETURN

wait_05bit:
        LOAD cont1, 03 
espera4:
        LOAD cont2, 10
espera3:
        SUB cont2, 01
        JUMP NZ, espera3
        SUB cont1, 01
        JUMP NZ, espera4
        RETURN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Interrupt Service Routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ADDRESS FF
isr:    DISABLE INTERRUPT
        CALL recibe       ; Get player's guess

        ; Echo received character
        LOAD txreg, rxreg
        CALL transmite

        ; Check if guess is correct
        LOAD temp, rxreg
        SUB temp, 48      ; Convert from ASCII '0'
        
        LOAD s0, current
        SUB s0, next
        JUMP Z, tie

        JUMP NC, high_guess
        ; Low guess
        SUB temp, 02      ; Check if guess was '2' (lower)
        JUMP NZ, wrong
        JUMP win

high_guess:
        ; High guess
        SUB temp, 01      ; Check if guess was '1' (higher)
        JUMP NZ, wrong
        JUMP win

wrong:  LOAD txreg, 45   ; 'X'
        CALL transmite
        JUMP end_isr

win:    LOAD txreg, 43   ; 'O'
        CALL transmite
        JUMP end_isr

tie:    LOAD txreg, 3D   ; '='
        CALL transmite
        JUMP end_isr

end_isr:
        LOAD txreg, 0D    ; CR
        CALL transmite
        LOAD txreg, 0A    ; LF
        CALL transmite
        LOAD current, next ; Update current number
        JUMP new_round