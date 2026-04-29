# Abs: From C to LC3 Assembly

A walk through how the compiler turns a small C program into LC3 assembly: the program-entry handshake, the calling convention, encoding negative numbers, and a non-obvious arithmetic trick the compiler uses for `>=`.

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

Two local variables, one if-else branch. Small, but it touches almost every part of the compiler: stack-frame setup, negative literals, comparison operators, conditional branching, and function teardown. We will follow the generated assembly in execution order.

---

## Slide 2: The Bootstrap — Where Execution Begins

LC3 starts every program at address `x3000`. The compiler emits a small bootstrap that prepares the stack, calls `main`, and halts.

```asm
.ORIG x3000
LD R6, USER_STACK   ; R6 = xFDFF (top of user stack)
ADD R5, R6, #-1     ; R5 = xFDFE (initial frame pointer)
JSR main            ; call main; R7 ← return address
HALT                ; program ends here
```

Two ideas to notice:

- **`main` is called like any other function.** `JSR` saves the return address in R7 and jumps. When `main` finishes, it executes `RET` and control returns *to the line after the JSR* — the `HALT`.
- **`HALT` is the single exit point.** No matter how many `return` statements `main` contains, every one of them eventually funnels back through `RET` to this `HALT`. Symmetric with every other function in the program.

```
            ┌──────────────────────────────┐
            │     bootstrap (x3000)        │
            │   set up R6, R5, JSR main    │
            └──────────────┬───────────────┘
                           │ JSR
                           ▼
                       main runs
                           │ RET
                           ▼
                         HALT
```

---

## Slide 3: R5 and R6 — Two Pointers, Two Jobs

The bootstrap initializes two registers. Why two?

- **R6 is the stack pointer (SP).** It marks where free stack memory begins. It moves every time the program reserves or releases a stack slot.
- **R5 is the frame pointer (FP).** Once a function starts, R5 is fixed for the duration of that function. Local variables are always accessed at fixed offsets from R5: `R5+0`, `R5-1`, `R5-2`, ...

```
           higher addresses
        ┌──────────────────┐  xFDFF  ← USER_STACK (initial R6)
        │                  │
        │   stack grows    │
        │      down        │
        │       ↓          │
        ├──────────────────┤  ← R6 (current top of stack)
        │   free memory    │
        └──────────────────┘
           lower addresses
```

If we used only one pointer, every push or pop would shift the offset of every local variable. With the FP/SP split, the *frame pointer* gives stable compile-time offsets while the *stack pointer* tracks live usage for calls, traps, and temporaries.

---

## Slide 4: main's Prologue — Callee Setup

When `main` is entered, it builds its stack frame the same way every function does. This sequence is called the **prologue** or **callee setup**.

```asm
main
; callee setup:
    ADD R6, R6, #-1   ; allocate spot for return value
    ADD R6, R6, #-1
    STR R7, R6, #0    ; push R7 (return address)
    ADD R6, R6, #-1
    STR R5, R6, #0    ; push R5 (caller frame pointer)
    ADD R5, R6, #-1   ; set frame pointer
```

Each push is two instructions: decrement R6 to reserve a slot, then `STR` the value into that slot. The prologue saves three things on the stack:

1. **A return-value slot** — empty space the function will fill before returning.
2. **R7** — the return address that `JSR` placed here. Saved because the function might call other functions, which would overwrite R7.
3. **R5** — the caller's frame pointer. Saved because we are about to overwrite R5 with our own.

```
    ┌───────────────────┐
    │  return-value     │  ← R5 + 3
    ├───────────────────┤
    │  saved R7         │  ← R5 + 2
    ├───────────────────┤
    │  saved R5         │  ← R5 + 1
    ├───────────────────┤
    │  (frame pointer)  │  ← R5 + 0  ← R6
    └───────────────────┘
```

After the prologue, R5 points at the spot just above where the first local will land. Locals are addressed at `R5+0, R5-1, R5-2, ...`; the saved registers and return slot are at the positive offsets above R5.

---

## Slide 5: Local Variables and Negative Literals

The body declares two ints and initializes them. Each declaration follows the same pattern: decrement R6 to reserve a slot, compute the initializer, store it through R5 at the slot's known offset.

```asm
; function body:
    ADD R6, R6, #-1      ; reserve slot for "number"
    AND R0, R0, #0       ; R0 = 0
    ADD R0, R0, #7       ; R0 = 7
    NOT R0, R0           ; R0 = ~7 = 0xFFF8
    ADD R0, R0, #1       ; R0 = -7 = 0xFFF9
    STR R0, R5, #0       ; number = -7

    ADD R6, R6, #-1      ; reserve slot for "abs"
    AND R0, R0, #0       ; R0 = 0
    STR R0, R5, #-1      ; abs = 0
```

LC3's `ADD` can only load small positive immediates (range −16 to +15), and there is no `NEG` or `SUB` instruction. To produce `−7`, the compiler builds it: load `+7`, then **two's-complement negate** by `NOT` followed by `ADD …, #1`.

```
  ┌──────────────┐
  │ number = -7  │  ← R5 + 0
  ├──────────────┤
  │   abs = 0    │  ← R5 - 1   ← R6
  └──────────────┘
```

This `NOT / ADD #1` idiom appears anywhere the compiler needs a unary minus or a subtraction. Watch for it.

---

## Slide 6: Evaluating `number >= 0` — Branch-Flag Selection

The C condition is `number >= 0`. LC3's `BR` instruction encodes three independent flag bits — N, Z, P — for any combination of "branch when result is negative, zero, or positive." Six of those eight combinations are useful, and there is exactly one whose meaning is the *negation* of every C comparison operator:

| Operator | True when result is | Branch on FALSE |
|----------|---------------------|-----------------|
| `<`      | negative            | `BRzp` (zero or positive)     |
| `>`      | positive            | `BRnz` (negative or zero)     |
| `<=`     | negative or zero    | `BRp`  (positive)             |
| `>=`     | zero or positive    | `BRn`  (negative)             |
| `==`     | zero                | `BRnp` (negative or positive) |
| `!=`     | negative or positive| `BRz`  (zero)                 |

The compiler emits a single subtraction `left − right` — and because every LC3 ADD/AND-style instruction sets the NZP flags as a *side effect* of producing its result, no separate compare instruction is needed. After the subtraction, it picks the branch variant from the table for "skip the if-body when the comparison is false." For `>=`, that is `BRn` — fire only when `number − 0` is negative, which is exactly when `number < 0`.

```asm
    AND R0, R0, #0       ; R0 = 0     (the literal 0 on the right of >=)
    LDR R1, R5, #0       ; R1 = number
    NOT R0, R0           ; \  two's-complement negate the right operand
    ADD R0, R0, #1       ; /  R0 = -(0) = 0
    ADD R1, R1, R0       ; R1 = number - 0;  ADD sets NZP as a side effect
    BRn  main_if_0       ; if number < 0 (>= is false), jump to else
```

Five instructions instead of the eight an earlier version of this compiler emitted. No extra `AND R, R, R` to reload NZP — the subtraction already did that. No boundary-shift arithmetic — the right `BR` flag combination *is* the negation of the operator.

> **Sidebar — how an earlier version did it.** A prior release of this compiler used a "universal branch" pattern: always emit `BRnz` to skip the if-body, and rewrite the *expression* to fit. For `>=`, that meant computing `(number + 1) > 0` (algebraically equivalent to `number ≥ 0`). It worked, but cost an extra `ADD …, #1` per `>=`/`<=` comparison and had a subtle bug: on 16-bit LC3, when `a − b == +32767`, the boundary `+1` wrapped to `−32768` and silently flipped the result. The current direct-flag approach removes both costs.

The "compare against literal zero" inefficiency is still here, by the way: lines 1, 3, 4 build the constant `−0` to subtract, and line 5 subtracts zero from `number`. The compiler does not recognize "the right operand is `0`" as a special case, so it always materializes the full subtraction. Worth pointing out to students as an example of un-optimized but correct codegen.

---

## Slide 7: If-Else Control Flow

With the comparison done, the if-else uses the standard two-label pattern: one label for the else-entry, one for the merge point.

```asm
    BRn  main_if_0           ; if false (number < 0), jump to else

    ; --- if-body: abs = number ---
    LDR R0, R5, #0
    STR R0, R5, #-1
    BR   main_if_0_end       ; unconditional skip past else

main_if_0
    ; --- else-body: abs = -number ---
    LDR R0, R5, #0
    NOT R0, R0
    ADD R0, R0, #1           ; the same NOT / ADD #1 negation pattern
    STR R0, R5, #-1

main_if_0_end
```

```
       test number - 0
            │
       BRn  ─────────────────► main_if_0   (else body)
            │                       │
            ▼                       │
      abs = number                  ▼
      BR main_if_0_end ────► abs = -number
                                    │
                          main_if_0_end ◄──┘
```

Every if-else in this compiler uses the same `main_if_N` / `main_if_N_end` label pair, with `N` increasing per occurrence. Predictable shape, easy for students to read.

The "skip past else" branch at the end of the if-body is **unconditional** (`BR`, which assembles to `BRnzp`). This matters: after the if-body runs, NZP holds whatever the *body's* last flag-setting instruction left, not the comparison result. Using a flag-restricted variant like `BRnz` here would fail unpredictably depending on what the body did. (An earlier version of this compiler had exactly that bug.)

---

## Slide 8: main's Teardown — Returning to the Bootstrap

After the if-else merges, `main` falls through to its **teardown**, which reverses the prologue.

```asm
main_teardown
    ADD R6, R5, #1     ; pop local variables (R6 ← above the locals)
    LDR R5, R6, #0     ; pop frame pointer (restore caller's R5)
    ADD R6, R6, #1
    LDR R7, R6, #0     ; pop return address
    ADD R6, R6, #1
    RET                ; jump to R7  →  back to the bootstrap's HALT
```

`ADD R6, R5, #1` is the magic line: it discards every local variable in one instruction by snapping R6 back to where R5 sits (just above the locals). From there, the prologue's three pushes are undone in reverse order: pop R5, pop R7, then `RET`.

`RET` is `JMP R7`, so control returns to the instruction right after `JSR main` in the bootstrap — which is `HALT`. That is the **single exit point** of the program. Whether `main` had zero, one, or many `return` statements, all of them route through `BR main_teardown → RET → HALT`.

```
   ┌──────────┐
   │ if-body  │──┐
   └──────────┘  │
                 ▼
            main_teardown
                 │
                RET
                 │
                 ▼
             HALT  (in the bootstrap)
```

---

## Slide 9: Putting It All Together

The full lifecycle of the program, end to end:

```
1. Bootstrap          .ORIG x3000
                      LD R6, USER_STACK         ┐  set up SP and FP
                      ADD R5, R6, #-1           ┘
                      JSR main                  ── call main
                      HALT                      ── single program exit

2. main prologue      push return slot, R7, R5, set new R5
                      (so locals can be addressed via R5)

3. main body          declare and initialize "number" and "abs"
                      evaluate "number >= 0" via subtraction + BRn
                      branch into if-body or else-body
                      assign "abs"

4. main teardown      pop locals, restore R5, restore R7
                      RET back to the bootstrap's HALT
```

Three techniques recur throughout the compiler's output and are worth memorizing:

- **`NOT R, R` followed by `ADD R, R, #1`** — two's-complement negation. Used for negative literals, unary minus, and as the back half of every subtraction.
- **`ADD R6, R6, #-1` followed by `STR …, R6, #0`** — the "push" idiom. The reverse (`LDR …, R6, #0` then `ADD R6, R6, #1`) is "pop."
- **Branch-flag selection per operator** — every C comparison maps to exactly one LC3 `BR` variant whose flags are the operator's negation (see Slide 6's table). The subtraction sets NZP as a side effect, so no separate compare is needed.

Once these patterns are familiar, most LC3 output from this compiler reads almost as easily as the C it came from.
