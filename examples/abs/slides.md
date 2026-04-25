# Abs: Negative Literals and If-Else in LC3

---

## Slide 1: The C Source Code

```c
int main()
{
    int number = -7;
    int abs = 0;
    if (number >= 0)
    {
        abs = number;
    }
    else
    {
        abs = -number;
    }
}
```

Two local variables, one if-else branch. The interesting compilation challenges are: encoding the negative literal `-7`, and translating `>= 0` into LC3 branch instructions.

---

## Slide 2: Encoding a Negative Literal

LC3's `ADD` can only load small positive immediates. The compiler produces `-7` using **two's complement negation**: start with `+7`, invert all bits (`NOT`), then add 1.

```asm
main
    ADD R6, R6, #-1           ; Allocate space for "number"
    AND R0, R0, #0            ; R0 = 0
    ADD R0, R0, #7            ; R0 = 7
    NOT R0, R0                ; R0 = ~7  = 0xFFF8
    ADD R0, R0, #1            ; R0 = -7  = 0xFFF9
    STR R0, R5, #0            ; Initialize "number" = -7

    ADD R6, R6, #-1           ; Allocate space for "abs"
    AND R0, R0, #0
    STR R0, R5, #-1           ; Initialize "abs" = 0
```

Stack layout:

```
  ┌──────────────┐
  │ number = -7  │  ← R5 + 0
  ├──────────────┤
  │   abs = 0    │  ← R5 - 1  ← R6
  └──────────────┘
```

The same `AND / ADD / NOT / ADD` sequence appears whenever the compiler must negate a value at runtime.

---

## Slide 3: If-Else — Branch Labels and Condition Testing

The condition `number >= 0` is tested by examining the value of `number` directly: if it is negative or zero, branch to the else path; otherwise fall through to the if-body.

```asm
    LDR R1, R5, #0            ; load "number" into R1
    AND R1, R1, R1            ; set NZP condition codes from R1
    BRnz main_if_0            ; if number < 0 (or == 0), jump to else

    ; --- if-body: abs = number ---
    LDR R0, R5, #0            ; load "number"
    STR R0, R5, #-1           ; abs = number
    BRnz main_if_0_end        ; skip else (branch always taken here)

main_if_0
    ; --- else-body: abs = -number ---
    LDR R0, R5, #0            ; load "number"
    NOT R0, R0
    ADD R0, R0, #1            ; negate: R0 = -number
    STR R0, R5, #-1           ; abs = -number

main_if_0_end
    HALT
```

Control flow diagram:

```
    load number, set NZP
          │
     BRnz ──────────────────► main_if_0  (else body)
          │                        │
          ▼                        │
    abs = number                   │
    BRnz main_if_0_end ────────────┤
                                   ▼
                           abs = -number
                                   │
                           main_if_0_end ◄──────────┘
```

Every if-else in this compiler uses the same two-label pattern: `main_if_N` for the else entry and `main_if_N_end` for the merge point.
