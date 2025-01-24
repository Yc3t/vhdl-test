        ; Register definitions
        NAMEREG     s0, display     ; Display output register
        NAMEREG     s1, position    ; Current position
        NAMEREG     s2, input       ; Input buffer
        NAMEREG     s3, temp        ; Temporary storage
        NAMEREG     s4, score       ; Score counter
        NAMEREG     s5, temp2       ; Second temporary storage
        
        ; Constants
        CONSTANT    rs232, FF       ; Serial port
        CONSTANT    left_key, 41    ; 'A' key
        CONSTANT    right_key, 44   ; 'D' key
        CONSTANT    quit_key, 51    ; 'Q' key
        
start:  
        ; Initialize game
        LOAD        score, 00
        LOAD        position, 04    ; Start in middle
        
        ; Display welcome message
        LOAD        display, 57     ; 'W'
        OUTPUT      display, rs232
        LOAD        display, 45     ; 'E'
        OUTPUT      display, rs232
        LOAD        display, 4C     ; 'L'
        OUTPUT      display, rs232
        LOAD        display, 0D     ; CR
        OUTPUT      display, rs232
        LOAD        display, 0A     ; LF
        OUTPUT      display, rs232

game_loop:
        ; Draw current position
        CALL        draw_line
        
        ; Get input
        INPUT       input, rs232
        
        ; Check input
        LOAD        temp, input
        SUB         temp, quit_key
        JUMP        Z, game_over
        
        LOAD        temp, input
        SUB         temp, left_key
        JUMP        Z, move_left
        
        LOAD        temp, input
        SUB         temp, right_key
        JUMP        Z, move_right
        
        JUMP        game_loop

move_left:
        LOAD        temp, position
        SUB         temp, 01
        JUMP        C, game_loop    ; Don't move if at left edge
        LOAD        position, temp
        JUMP        game_loop

move_right:
        LOAD        temp, position
        ADD         temp, 01
        SUB         temp, 09        ; Check if beyond right edge
        JUMP        NC, game_loop   ; Don't move if at right edge
        ADD         position, 01
        JUMP        game_loop

draw_line:
        LOAD        temp, 00        ; Counter
draw_loop:
        LOAD        display, 2D     ; '-'
        LOAD        temp2, temp
        SUB         temp2, position
        JUMP        NZ, draw_dash
        LOAD        display, 4F     ; 'O'
draw_dash:
        OUTPUT      display, rs232
        ADD         temp, 01
        SUB         temp, 09
        JUMP        NZ, draw_loop
        
        LOAD        display, 0D     ; CR
        OUTPUT      display, rs232
        LOAD        display, 0A     ; LF
        OUTPUT      display, rs232
        RETURN

game_over:
        ; Display game over message
        LOAD        display, 58     ; 'X'
        OUTPUT      display, rs232
        LOAD        display, 0D     ; CR
        OUTPUT      display, rs232
        LOAD        display, 0A     ; LF
        OUTPUT      display, rs232
        
        ; Display score
        LOAD        display, score
        ADD         display, 30     ; Convert to ASCII
        OUTPUT      display, rs232
        
end_program:
        JUMP        end_program