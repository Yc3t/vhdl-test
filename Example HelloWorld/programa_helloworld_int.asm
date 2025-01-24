;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; Constants and Variables
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        CONSTANT    rs232, FF        ; Serial port
        CONSTANT    max_attempts, 0A  ; Maximum attempts allowed
        
        NAMEREG     s0, target       ; Target number to guess
        NAMEREG     s1, guess        ; User's guess
        NAMEREG     s2, temp         ; Temporary storage
        NAMEREG     s3, seed         ; Random number seed
        NAMEREG     s4, counter      ; Counter for attempts
        
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; Main Program
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start:  
        ; Initialize random seed
        LOAD        seed, 42         ; Initial seed
        
        ; Generate random number between 1-9
generate:
        LOAD        temp, seed
        AND         temp, 0F         ; Get lower 4 bits
        SR0         seed             ; Shift right
        JUMP        NZ, no_feedback
        XOR         seed, A3         ; XOR with feedback polynomial
no_feedback:
        ADD         seed, 00
        JUMP        Z, generate      ; Ensure not zero
        LOAD        temp, seed       ; Compare seed with 0A using subtraction
        SUB         temp, 0A
        JUMP        NC, generate     ; If seed >= 0A, generate new number
        
        ; Store generated number as target
        LOAD        target, seed
        LOAD        counter, 00      ; Reset attempt counter
        
        ; Welcome message
        LOAD        s0, 57           ; 'W'
        OUTPUT      s0, rs232
        LOAD        s0, 45           ; 'E'
        OUTPUT      s0, rs232
        LOAD        s0, 4C           ; 'L'
        OUTPUT      s0, rs232
        LOAD        s0, 43           ; 'C'
        OUTPUT      s0, rs232
        LOAD        s0, 4F           ; 'O'
        OUTPUT      s0, rs232
        LOAD        s0, 4D           ; 'M'
        OUTPUT      s0, rs232
        LOAD        s0, 45           ; 'E'
        OUTPUT      s0, rs232
        LOAD        s0, 21           ; '!'
        OUTPUT      s0, rs232
        LOAD        s0, 0D           ; CR
        OUTPUT      s0, rs232
        LOAD        s0, 0A           ; LF
        OUTPUT      s0, rs232

game_loop:
        ; Check if max attempts reached
        LOAD        temp, counter
        SUB         temp, max_attempts
        JUMP        Z, game_over
        
        ; Get user input and convert from ASCII
        INPUT       guess, rs232     ; Get character
        SUB         guess, 30        ; Convert from ASCII
        ADD         counter, 01      ; Increment attempt counter
        
        ; Compare guess with target using subtraction
        LOAD        temp, guess
        SUB         temp, target
        JUMP        Z, correct       ; If guess == target
        JUMP        C, too_low       ; If guess < target
        JUMP        too_high         ; If guess > target
        
too_high:
        LOAD        s0, 48           ; 'H'
        OUTPUT      s0, rs232
        JUMP        game_loop
        
too_low:
        LOAD        s0, 4C           ; 'L'
        OUTPUT      s0, rs232
        JUMP        game_loop
        
correct:
        LOAD        s0, 57           ; 'W'
        OUTPUT      s0, rs232
        JUMP        play_again
        
game_over:
        LOAD        s0, 58           ; 'X'
        OUTPUT      s0, rs232
        
play_again:
        ; Ask to play again
        INPUT       s0, rs232
        LOAD        temp, s0
        SUB         temp, 59         ; Compare with hex 59 ('Y')
        JUMP        Z, start
        JUMP        end_program
        
end_program:
        JUMP        end_program      ; Infinite loop at end

; Subroutines for sending messages
send_welcome:
        LOAD        s0, 57           ; 'W'
        CALL        send_char
        LOAD        s0, 45           ; 'E'
        CALL        send_char
        LOAD        s0, 4C           ; 'L'
        CALL        send_char
        LOAD        s0, 43           ; 'C'
        CALL        send_char
        LOAD        s0, 4F           ; 'O'
        CALL        send_char
        LOAD        s0, 4D           ; 'M'
        CALL        send_char
        LOAD        s0, 45           ; 'E'
        CALL        send_char
        LOAD        s0, 21           ; '!'
        CALL        send_char
        LOAD        s0, 0D           ; CR
        CALL        send_char
        LOAD        s0, 0A           ; LF
        CALL        send_char
        RETURN

; Add other message subroutines here...

; Basic I/O subroutines
send_char:
        OUTPUT      s0, rs232
        RETURN
        
get_input:
        INPUT       s0, rs232
        RETURN