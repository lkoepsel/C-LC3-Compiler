# Sum: Local Variables and a For Loop in LC3

---

## Slide 1: The C Source Code

```c
int main()
{
    int N = 5;
    int SUM = 0;

    for (int i = 1; i <= N; i++)
    {
        SUM = SUM + i;
    }
}
```

`main` has no parameters and calls no functions, so there is **no callee setup** — no return-value slot, no saved R7 or R5. The frame pointer R5 is set once at startup and stays fixed. All three local variables are accessed directly through R5 offsets.

---

## Slide 2: Allocating Local Variables on the Stack

Each `int` declaration claims one stack slot by decrementing R6:

```asm
main
    ADD R6, R6, #-1           ; Allocate space for "N"
    AND R0, R0, #0
    ADD R0, R0, #5
    STR R0, R5, #0            ; Initialize "N" = 5

    ADD R6, R6, #-1           ; Allocate space for "SUM"
    AND R0, R0, #0
    STR R0, R5, #-1           ; Initialize "SUM" = 0

    ADD R6, R6, #-1           ; Allocate space for "i"
    AND R0, R0, #0
    ADD R0, R0, #1
    STR R0, R5, #-2           ; Initialize "i" = 1
```

Stack layout after initialization:

```
  ┌───────────┐
  │   N = 5   │  ← R5 + 0
  ├───────────┤
  │  SUM = 0  │  ← R5 - 1
  ├───────────┤
  │   i = 1   │  ← R5 - 2  ← R6
  └───────────┘
```

Variables declared first sit at higher addresses (smaller negative offsets from R5).

---

## Slide 3: The For Loop — Condition Test

The loop condition `i <= N` cannot be tested with a single LC3 instruction. The compiler computes `N − i + 1` and branches if the result is zero or negative:

```asm
main_for_0
    LDR R0, R5, #0            ; load N
    LDR R1, R5, #-2           ; load i
    NOT R1, R1                ; ~i  (step toward two's complement)
    ADD R1, R1, #1            ;  -i
    ADD R1, R1, R0            ; N - i
    ADD R1, R1, #1            ; N - i + 1  (boundary shift for <=)

    AND R1, R1, R1            ; set NZP condition codes
    BRnz main_for_0_end       ; if N - i + 1 <= 0, i.e. i > N, exit loop
```

| Value of `N − i + 1` | NZP | Branch taken? | Meaning |
|----------------------|-----|---------------|---------|
| Positive | P | No | `i <= N` — stay in loop |
| Zero or Negative | N or Z | Yes | `i > N` — exit loop |

The `+1` shifts the boundary so that `<=` (rather than `<`) is tested correctly.

---

## Slide 4: Loop Body, Increment, and Back-Branch

After the condition passes, the body executes, then `i` is incremented, and the loop restarts:

```asm
    ; body: SUM = SUM + i
    LDR R0, R5, #-1           ; load SUM
    LDR R1, R5, #-2           ; load i
    ADD R0, R0, R1
    STR R0, R5, #-1           ; SUM = SUM + i

    ; increment: i++
    LDR R0, R5, #-2           ; load i
    ADD R1, R0, #0            ; save original (postfix semantics)
    ADD R0, R0, #1
    STR R0, R5, #-2           ; store i + 1

    BR main_for_0             ; back to condition test
main_for_0_end

    HALT
```

The full loop structure as labels:

```
main_for_0:        ← top of loop (condition test)
    ...
    BRnz main_for_0_end
    ...            ← body
    ...            ← increment
    BR main_for_0
main_for_0_end:    ← after loop
```

Every `for` loop in this compiler follows this exact label pattern.
