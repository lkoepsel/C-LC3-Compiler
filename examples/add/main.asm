.ORIG x3000
LD R6, USER_STACK
ADD R5, R6, #-1
JSR main

main
    ADD R6, R6, #-1           ; Allocate space for "a"
    LD R0, CONST_0            ; load constant 25
    STR R0, R5, #0            ; Initialize "a"

    ADD R6, R6, #-1           ; Allocate space for "b"
    LD R0, CONST_1            ; load constant 17
    STR R0, R5, #-1           ; Initialize "b"

    ADD R6, R6, #-1           ; Allocate space for "c"
    LDR R0, R5, #0            ; load local variable "a"
    LDR R1, R5, #-1           ; load local variable "b"
    ADD R0, R0, R1
    STR R0, R5, #-2           ; Initialize "c"

    HALT


; ---- Data Section ----
CONST_0                     .FILL x0019
CONST_1                     .FILL x0011

USER_STACK .FILL xFDFF
RETURN_SLOT .FILL xFDFF

.END
