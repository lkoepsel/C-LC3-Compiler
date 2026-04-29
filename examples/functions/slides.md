# Functions: The Calling Convention in LC3

A walk through how multiple functions interact at the assembly level: passing arguments, returning values, and the contract between caller and callee. This deck builds on the `abs` deck — the program-entry handshake, R5/R6 split, prologue, teardown, and two's-complement negation are introduced there and are reused unchanged here.

---

## Slide 1: The C Source — Three Functions, Two Calls

```c
int add_2(int a, int b)
{
    int c = a + b;
    return c;
}

int sub_2(int a, int b)
{
    int c = a - b;
    return c;
}

void main()
{
    int a = 21;
    int b = 33;
    int c = add_2(a, b);
    int d = sub_2(a, b);
    return;
}
```

Three functions, four locals in `main`, two function calls. Each callee has the **same shape** as `main` had in the `abs` example: prologue, body, teardown, `RET`. What's new in this example is the *handshake* between functions — how arguments arrive, how a return value gets back, and who is responsible for cleaning up which part of the stack.

---

## Slide 2: The Caller–Callee Contract

A function call is a four-step handshake. Each step is the responsibility of exactly one party.

| Step | Who | What |
|------|-----|------|
| 1. Push arguments | **Caller** | Push args right-to-left, then `JSR` |
| 2. Build frame | **Callee** | Reserve return slot, save R7 & R5, set new R5 (covered in `abs` Slide 4) |
| 3. Execute body | **Callee** | Use parameters and locals via `R5 ± offset` |
| 4. Write return value | **Callee** | Store result into the return slot at `R5 + 3` |
| 5. Tear down | **Callee** | Pop locals, restore R5 & R7, `RET` (covered in `abs` Slide 8) |
| 6. Read result, pop args | **Caller** | Read return value at `R6 + 0`, then pop |

Notice the asymmetry: the *callee* allocates the return slot (during its prologue), but the *caller* removes it (during cleanup). The slot is also the only piece of the stack that survives `RET` for the caller to read.

The rest of these slides expand each row of this table that is unique to multi-function programs — rows 1, 4, and 6.

---

## Slide 3: Pushing Arguments — Right-to-Left

Before each `JSR`, the caller pushes the function's arguments onto the stack. The convention is **right-to-left**: the *last* parameter is pushed *first*, so the *first* parameter ends up *on top* of the stack.

```asm
; in main, calling add_2(a, b):

    LDR R0, R5, #-1   ; load b (main's local)
    ADD R6, R6, #-1
    STR R0, R6, #0    ; push b first

    LDR R0, R5, #0    ; load a (main's local)
    ADD R6, R6, #-1
    STR R0, R6, #0    ; push a second (now on top)

    JSR add_2         ; R7 ← return address, jump
```

After the two pushes and the `JSR`, the stack from `add_2`'s perspective looks like:

```
  ...
  [   b   ]   ← pushed first  (further from new R5)
  [   a   ]   ← pushed second (closer to new R5)   ← R6
```

Why right-to-left? It makes parameter offsets predictable from the callee's side. After `add_2`'s prologue saves R7 and R5 *below* the arguments, the layout becomes deterministic: parameter *N* always lands at `R5 + (3 + N)`. The first parameter is at `R5 + 4`, the second at `R5 + 5`, regardless of how many arguments there are.

---

## Slide 4: The Stack Frame from the Callee's View

After `add_2` runs its prologue, the full frame looks like this — parameters above R5, saved bookkeeping in the middle, locals below:

```
Higher addresses
  ┌──────────────┐
  │      b       │  ← R5 + 5    (param, pushed first by caller)
  ├──────────────┤
  │      a       │  ← R5 + 4    (param, pushed second by caller)
  ├──────────────┤
  │ return value │  ← R5 + 3    (callee writes; caller reads)
  ├──────────────┤
  │   saved R7   │  ← R5 + 2
  ├──────────────┤
  │   saved R5   │  ← R5 + 1
  ├──────────────┤
  │      c       │  ← R5 + 0    (local) ← R6
  └──────────────┘
Lower addresses
```

Two halves divided by R5:
- **Above R5** (positive offsets): things provided *by* or *for* the caller — parameters and the return slot. These are part of the **call interface**.
- **Below R5** (zero or negative offsets): things owned entirely by the callee — its local variables.

The compiler uses this split when it generates code:

```asm
; int c = a + b;
LDR R0, R5, #4     ; load parameter "a" (R5 + 4)
LDR R1, R5, #5     ; load parameter "b" (R5 + 5)
ADD R0, R0, R1
STR R0, R5, #0     ; store local "c"   (R5 + 0)
```

Notice the assembly has no idea whether `a` and `b` were pushed by `main`, by `sub_2`, or by some other caller. The contract guarantees the layout, and that's all the codegen needs to know.

---

## Slide 5: Returning a Value — Writing to `R5 + 3`

The C statement `return c;` becomes two instructions: store the result into the return-value slot, then branch to teardown.

```asm
LDR R0, R5, #0          ; load local "c"
STR R0, R5, #3          ; write return value, always R5 + 3
BR  add_2_teardown      ; single-exit funneling
```

Why `R5 + 3`? Look back at the frame diagram. The prologue (in `abs` Slide 4) reserves *one slot above the saved R7 and R5* — and `R5 + 3` is exactly that slot. It is the same offset for every function, regardless of how many parameters there are or how big the local block is.

This keeps the rule simple for students: **return values always go to R5 + 3.** The compiler hard-codes that offset; the caller hard-codes that offset too (read further on).

`BR add_2_teardown` is the single-exit funnel from `abs` Slide 8 — every `return` statement in the function routes through one teardown sequence rather than emitting cleanup inline at each return point.

---

## Slide 6: Caller Cleanup — Read First, Then Pop

After `RET` brings control back to the caller, the stack still holds three caller-visible slots: the return value, then the two arguments below it.

```
  ...
  [   b   ]
  [   a   ]
  [ retval ]   ← R6
```

The caller's cleanup code reads the return value first, then pops everything in one shot:

```asm
JSR add_2
LDR R0, R6, #0       ; read return value (R6 still points to it)
ADD R6, R6, #1       ; pop the return slot
ADD R6, R6, #2       ; pop the two arguments
STR R0, R5, #-2      ; store result into main's local "c"
```

Order matters. The return value's lifetime ends the moment R6 advances past its slot — once popped, that memory is fair game for the next call or trap. Two cardinal rules:

- **Read before popping.** `LDR R0, R6, #0` must come before `ADD R6, R6, #1`.
- **The caller pops the arguments, not the callee.** This is "caller cleanup," the LC3 textbook convention. It lets each caller decide what to do with the args (most just discard them).

---

## Slide 7: Subtraction in `sub_2` — Reusing the Negation Idiom

`sub_2` does `a - b`. LC3 has no `SUB` instruction, so the compiler builds it from the parts it has:

```asm
; int c = a - b;
LDR R0, R5, #4     ; R0 = a
LDR R1, R5, #5     ; R1 = b
NOT R1, R1         ; \ two's-complement negate b:
ADD R1, R1, #1     ; /  R1 = -b
ADD R0, R0, R1     ; R0 = a + (-b) = a - b
STR R0, R5, #0     ; store local "c"
```

This is the same `NOT / ADD #1` idiom from `abs` Slide 5, now serving as the back half of subtraction: `a - b ≡ a + (-b)`. The same two instructions also appear inside the `>=` evaluation in `abs` Slide 6, and inside the unary minus `-number` in `abs` Slide 7. One pattern, three contexts — once recognized, it becomes invisible scaffolding around the actual logic.

---

## Slide 8: A Full Call Trace — `int c = add_2(a, b)`

Tie everything together by watching the stack across the entire call. Initial state is partway through `main`, with `a = 21` and `b = 33` already on the stack and a slot reserved for `c`.

```
Step                           R6 →  Stack contents (top to bottom)
─────────────────────────────  ────  ────────────────────────────────
in main (before pushes)         [c] | (c, b=33, a=21, ...)
push b                          [b] | b=33, c, b=33, a=21, ...
push a                          [a] | a=21, b=33, c, b=33, a=21, ...
JSR add_2 (R7=ret addr)         [a] | a=21, b=33, c, b=33, a=21, ...
prologue: reserve return slot   [?] | ?, a, b, c, b, a, ...
prologue: push R7               [R7]| R7, ?, a, b, c, b, a, ...
prologue: push R5               [R5]| R5, R7, ?, a, b, c, b, a, ...
prologue: set R5 = R6 - 1        ─  | (R5 now points one below)
allocate local c                [c=0]| c, R5, R7, ?, a, b, c, b, a, ...
body: c = a + b                  ─  | (c slot now holds 54)
return: store 54 at R5+3         ─  | (? slot now holds 54)
BR teardown                      ─  | ─
teardown: ADD R6, R5, #1        [R5]| R5, R7, 54, a, b, c, b, a, ...
pop saved R5                    [R7]| R7, 54, a, b, c, b, a, ...
pop saved R7                    [54]| 54, a, b, c, b, a, ...
RET (jumps to R7)               [54]| 54, a=21, b=33, c, b=33, a=21, ...
LDR R0, R6, #0  →  R0 = 54      [54]| 54, a, b, c, ...
ADD R6, #1   (pop retval)       [a] | a, b, c, ...
ADD R6, #2   (pop args)         [c] | c, ...
STR R0 into c                    ─  | (c slot now holds 54)
```

Every region of the stack is the responsibility of *exactly one* party at any moment. The arguments are written by the caller and read by the callee. The return slot is written by the callee and read by the caller. The locals are private to whichever function R5 is currently pointing into. The contract is what makes all of this work — and what lets the compiler generate caller code and callee code completely independently.
