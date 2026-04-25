# Stack Frames and the Frame Pointer in LC3

---

## Slide 1: The C Source Code

We compile two simple functions and a `main` that calls them:

```c
int add_2(int a, int b) {
    int c = a + b;
    return c;
}

int sub_2(int a, int b) {
    int c = a - b;
    return c;
}

void main() {
    int a = 21;
    int b = 33;
    int c = add_2(a, b);
    int d = sub_2(a, b);
    return;
}
```

Each function has **two parameters** and **one local variable** — a compact but complete example of the calling convention.

---

## Slide 2: The Three Key Registers

| Register | Role | Changes when... |
|----------|------|-----------------|
| **R6** | Stack Pointer — always points to the top item on the stack | something is pushed or popped |
| **R5** | Frame Pointer — anchors the current function's stack frame | a new function is entered or returned from |
| **R7** | Return Address — set by `JSR`, holds where to return | every `JSR` call |

The stack **grows downward** (toward lower addresses). Pushing decrements R6; popping increments R6.

> **Why a frame pointer?** R6 moves constantly as temporaries come and go. R5 stays fixed for the entire function, so every variable has a stable address: `R5 + offset`.

---

## Slide 3: Caller's Actions — Pushing Arguments

Before calling `add_2`, `main` pushes arguments **right-to-left** (b first, then a):

```asm
; push b (argument 2 first)
LDR R0, R5, #-1            ; load local variable "b"
ADD R6, R6, #-1
STR R0, R6, #0             ; push b onto stack

; push a (argument 1 second, so it's on top)
LDR R0, R5, #0             ; load local variable "a"
ADD R6, R6, #-1
STR R0, R6, #0             ; push a onto stack

JSR add_2                  ; R7 = return address, jump to add_2
```

Stack after `JSR add_2` (R6 → a, b is one slot below):

```
  ...
  [ b ]   ← pushed first (higher address)
  [ a ]   ← pushed second (lower address, top of stack) ← R6
```

Arguments are always pushed in reverse order so that the first parameter ends up closest to the frame pointer.

---

## Slide 4: Callee Setup — Building the Stack Frame

The first thing `add_2` does is build its own frame:

```asm
add_2
    ADD R6, R6, #-1        ; reserve one slot for the return value
    ADD R6, R6, #-1
    STR R7, R6, #0         ; save return address (R7)
    ADD R6, R6, #-1
    STR R5, R6, #0         ; save caller's frame pointer (R5)
    ADD R5, R6, #-1        ; set new frame pointer (R5 = R6 - 1)
```

Five steps, in order:
1. **Reserve a return-value slot** — the caller will read the answer from here after `RET`.
2. **Save R7** — `JSR` overwrote it; we must preserve it so `RET` works.
3. **Save R5** — the caller's frame pointer must be restored before we return.
4. **Set new R5** — R5 now anchors *this* function's frame. It does not move again until teardown.

---

## Slide 5: The Complete Stack Frame

After callee setup and allocating local `c`, the stack looks like this:

```
Higher addresses
  ┌───────────┐
  │     b     │  ← R5 + 5   (second parameter, pushed first)
  ├───────────┤
  │     a     │  ← R5 + 4   (first parameter, pushed second)
  ├───────────┤
  │ ret value │  ← R5 + 3   (return slot, filled before RET)
  ├───────────┤
  │ saved R7  │  ← R5 + 2   (return address)
  ├───────────┤
  │ saved R5  │  ← R5 + 1   (caller's frame pointer)
  ├───────────┤
  │     c     │  ← R5 + 0   (local variable)  ← R6 (stack top)
  └───────────┘
Lower addresses
```

R5 never moves during the function body. Every variable — parameter or local — is reached with a fixed `R5 + offset`.

---

## Slide 6: Accessing Variables Via the Frame Pointer

Because R5 is fixed, every load and store uses it as a base:

```asm
; int c = a + b;
LDR R0, R5, #4        ; load parameter "a"  (R5 + 4)
LDR R1, R5, #5        ; load parameter "b"  (R5 + 5)
ADD R0, R0, R1
STR R0, R5, #0        ; store result into local "c"  (R5 + 0)

; return c;
LDR R0, R5, #0        ; load local "c"
STR R0, R5, #3        ; write into return-value slot  (R5 + 3)
BR  add_2_teardown
```

**Key insight:** The compiler assigns each variable a compile-time offset from R5. Whether the variable is a parameter or a local, the generated code always uses `LDR Rx, R5, #offset` or `STR Rx, R5, #offset` — no runtime pointer arithmetic needed.

---

## Slide 7: Callee Teardown — Unwinding the Frame

Before returning, `add_2` must restore the caller's world:

```asm
add_2_teardown
    ADD R6, R5, #1        ; discard all locals (R6 → saved R5 slot)
    LDR R5, R6, #0        ; restore caller's frame pointer
    ADD R6, R6, #1        ; advance past saved R5 (R6 → saved R7 slot)
    LDR R7, R6, #0        ; restore return address
    ADD R6, R6, #1        ; advance past saved R7 (R6 → return-value slot)
    RET                   ; jump to R7; R6 now points at return value
```

After `RET`, the stack pointer sits **exactly** on the return-value slot — the value the callee wrote in Slide 6. The caller reads it from there.

Teardown order is the reverse of setup: locals → saved R5 → saved R7 → RET.

---

## Slide 8: Caller Cleanup — Reading the Return Value

Back in `main`, after `JSR add_2` returns:

```asm
LDR R0, R6, #0        ; read return value (R6 points to it)
ADD R6, R6, #1        ; pop the return-value slot
ADD R6, R6, #2        ; pop the two arguments (a and b)
STR R0, R5, #-2       ; store result into local "c" in main
```

**Caller cleans up the arguments** — not the callee. This is the LC3 textbook convention (caller-cleanup). The return value lives for exactly one instruction after `RET`; the caller must read it before adjusting R6.

Summary of responsibilities:

| Who | What |
|-----|------|
| Caller (before call) | push args right-to-left, `JSR` |
| Callee (entry) | reserve return slot, save R7 & R5, set R5 |
| Callee (body) | access everything through R5 offsets |
| Callee (exit) | fill return slot, restore R5 & R7, `RET` |
| Caller (after call) | read return value, pop return slot + args |
