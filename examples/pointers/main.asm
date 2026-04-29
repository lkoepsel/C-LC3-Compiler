.ORIG x3000
LD R6, USER_STACK
ADD R5, R6, #-1
JSR main

main
    ADD R6, R6, #-1           ; Allocate space for "x"
    LD R0, CONST_0            ; load constant 1234
    STR R0, R5, #0            ; Initialize "x"

    ADD R6, R6, #-1           ; Allocate space for "y"
    LD R0, CONST_1            ; load constant 5678
    STR R0, R5, #-1           ; Initialize "y"

    ADD R6, R6, #-1           ; Allocate space for "p_x"

    ADD R6, R6, #-1           ; Allocate space for "p_y"

    ADD R6, R6, #-1           ; Allocate space for "p_z"

    LDR R0, R5, #0            ; load local variable "x" for increment
    ADD R1, R0, #0            ; save original value for postfix
    ADD R0, R0, #1
    STR R0, R5, #0            ; store incremented value

    LDR R0, R5, #-1           ; load local variable "y" for decrement
    ADD R1, R0, #0            ; save original value for postfix
    ADD R0, R0, #-1
    STR R0, R5, #-1           ; store decremented value

    ADD R0, R5, #0            ; take address of local variable "x"
    STR R0, R5, #-2           ; assign to variable "p_x"

    ADD R0, R5, #-1           ; take address of local variable "y"
    STR R0, R5, #-3           ; assign to variable "p_y"

    AND R0, R0, #0
    STR R0, R5, #-4           ; assign to variable "p_z"

    HALT


; ---- Data Section ----
CONST_0                     .FILL x04D2
CONST_1                     .FILL x162E

USER_STACK .FILL xFDFF
RETURN_SLOT .FILL xFDFF

.END
