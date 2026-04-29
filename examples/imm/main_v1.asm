; ------------------------------------------
; C-LC3 Compiler, By HKN for UIUC Students
; ------------------------------------------

.ORIG x3000
LD R6, USER_STACK
ADD R5, R6, #-1
JSR main

main
    ADD R6, R6, #-1           ; Allocate space for "a"
    AND R0, R0, #0
    ADD R0, R0, #1
    STR R0, R5, #0            ; Initialize "a"

    ADD R6, R6, #-1           ; Allocate space for "b"
    AND R0, R0, #0
    STR R0, R5, #-1           ; Initialize "b"

    AND R0, R0, #0
    ADD R0, R0, #17
    STR R0, R5, #-1           ; assign to variable "b"

    ADD R6, R6, #-1           ; Allocate space for "c"
    LDR R0, R5, #0            ; load local variable "a"
    LDR R1, R5, #-1           ; load local variable "b"
    ADD R0, R0, R1
    STR R0, R5, #-2           ; Initialize "c"

    HALT


; ---- Data Section ----

USER_STACK .FILL xFDFF
RETURN_SLOT .FILL xFDFF

.END
