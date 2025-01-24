        ; Register definitions
        NAMEREG     s0, display     ; Display output register
        NAMEREG     s1, counter     ; Counter for string position
        NAMEREG     s2, temp        ; Temporary storage
        
        ; Constants
        CONSTANT    rs232, FF       ; Serial port
        
start:  
        ; Initialize
        LOAD        counter, 00
        
print_loop:
        ; Get character from RAM
        INPUT       display, counter    ; Remove parentheses
        
        ; Check for end of string (null terminator)
        LOAD        temp, display
        SUB         temp, 00        ; Will set Z flag if display is 00
        JUMP        Z, end_program
        
        ; Output character to serial port
        OUTPUT      display, rs232
        
        ; Move to next character
        ADD         counter, 01
        JUMP        print_loop
        
end_program:
        JUMP        end_program