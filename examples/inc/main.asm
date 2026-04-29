.ORIG x3000
LD R6, USER_STACK
ADD R5, R6, #-1
JSR main

main
    ADD R6, R6, #-1           ; Allocate space for "a"
    AND R0, R0, #0
    ADD R0, R0, #3
    STR R0, R5, #0            ; Initialize "a"

    ADD R6, R6, #-1           ; Allocate space for "b"
    LD R0, CONST_0            ; load constant 18
    STR R0, R5, #-1           ; Initialize "b"

    LDR R0, R5, #0            ; load local variable "a" for increment
    ADD R1, R0, #0            ; save original value for postfix
    ADD R0, R0, #1
    STR R0, R5, #0            ; store incremented value

    LDR R0, R5, #-1           ; load local variable "b" for decrement
    ADD R1, R0, #0            ; save original value for postfix
    ADD R0, R0, #-1
    STR R0, R5, #-1           ; store decremented value

    HALT


; ---- Data Section ----
CONST_0                     .FILL x0012

USER_STACK .FILL xFDFF
RETURN_SLOT .FILL xFDFF

.END
