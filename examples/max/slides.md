# Max: Arrays on the Stack and Subscript Access in LC3

---

## Slide 1: The C Source Code

```c
int main()
{
    int elements[] = { 3, 7, 2, 9, 4 };
    int max = elements[0];

    for (int i = 1; i <= 4; i++)
    {
        if (elements[i] > max)
            max = elements[i];
    }
    int RESULT = max;
}
```

This example introduces two new ideas: storing an **array on the stack** and computing an **element address at runtime** using pointer arithmetic.

---

## Slide 2: Allocating an Array on the Stack

A 5-element `int` array requires 5 consecutive stack slots. The compiler claims them all at once with a single decrement:

```asm
main
    ADD R6, R6, #-5           ; Allocate 5 slots for "elements"
    AND R0, R0, #0
    ADD R0, R0, #3
    STR R0, R5, #0            ; elements[0] = 3
    AND R0, R0, #0
    ADD R0, R0, #7
    STR R0, R5, #-1           ; elements[1] = 7
    ...
    STR R0, R5, #-4           ; elements[4] = 4
```

Because the stack grows **downward**, element[0] is at the highest address (R5+0) and element[4] is at the lowest (R5−4):

```
  ┌─────────────────┐
  │ elements[0] = 3 │  ← R5 + 0
  ├─────────────────┤
  │ elements[1] = 7 │  ← R5 - 1
  ├─────────────────┤
  │ elements[2] = 2 │  ← R5 - 2
  ├─────────────────┤
  │ elements[3] = 9 │  ← R5 - 3
  ├─────────────────┤
  │ elements[4] = 4 │  ← R5 - 4
  ├─────────────────┤
  │ max             │  ← R5 - 5
  ├─────────────────┤
  │ i               │  ← R5 - 6
  ├─────────────────┤
  │ RESULT          │  ← R5 - 7  ← R6
  └─────────────────┘
```

---

## Slide 3: Subscript Access — Computing an Element's Address

In C, `elements[i]` means: take the address of `elements[0]`, then add `i`. On this stack that addition becomes **subtraction** because array elements grow toward lower addresses.

```asm
    ADD R0, R5, #0            ; R0 = address of elements[0]
    LDR R1, R5, #-6           ; load i
    NOT R1, R1
    ADD R1, R1, #1            ; R1 = -i  (two's complement)
    ADD R0, R0, R1            ; R0 = address of elements[i]
    LDR R0, R0, #0            ; R0 = elements[i]  (dereference)
```

The key step is negating the index before adding it to the base address:

| `i` | Base address | `−i` | Effective address | Element |
|-----|-------------|------|-------------------|---------|
| 0 | R5+0 | 0 | R5+0 | `elements[0]` = 3 |
| 1 | R5+0 | −1 | R5−1 | `elements[1]` = 7 |
| 3 | R5+0 | −3 | R5−3 | `elements[3]` = 9 |

`ADD R0, R5, #0` loads the **address** of elements[0] (not the value) into R0. `LDR R0, R0, #0` then dereferences that address to get the actual element.

---

## Slide 4: Nested Control Flow — For Loop with an Inner If

Inside the loop, `elements[i] > max` is evaluated and conditionally updates `max`:

```asm
main_for_0
    ; --- condition: i <= 4 ---
    AND R0, R0, #0
    ADD R0, R0, #4            ; load constant 4
    LDR R1, R5, #-6           ; load i
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R1, R0
    ADD R1, R1, #1            ; 4 - i + 1  (boundary shift for <=)
    AND R1, R1, R1
    BRnz main_for_0_end       ; exit if i > 4

    ; --- if: elements[i] > max ---
    LDR R0, R5, #-5           ; load max
    ; ... compute elements[i] into R1 ...
    NOT R0, R0
    ADD R0, R0, #1            ; R0 = -max
    ADD R1, R1, R0            ; R1 = elements[i] - max
    AND R1, R1, R1
    BRnz main_if_0_end        ; skip if elements[i] <= max

    ; --- body: max = elements[i] ---
    ; ... compute elements[i] into R0 ...
    STR R0, R5, #-5           ; max = elements[i]

main_if_0_end
    ; --- increment: i++ ---
    LDR R0, R5, #-6
    ADD R0, R0, #1
    STR R0, R5, #-6
    BR main_for_0
main_for_0_end
```

The `>` comparison computes `elements[i] − max` and branches **over** the update when the result is zero or negative — the same boundary pattern seen in `sum`, but without the `+1` shift because `>` (not `>=`) is tested.

---

## Slide 5: Summary — Stack Layout and Key Patterns

```
  ┌──────────────────────────────────────────────────────┐
  │ Concept              │ Assembly Pattern               │
  ├──────────────────────┼────────────────────────────────┤
  │ Allocate scalar      │ ADD R6, R6, #-1                │
  │ Allocate N-elem array│ ADD R6, R6, #-N                │
  │ Read variable        │ LDR Rx, R5, #offset            │
  │ Write variable       │ STR Rx, R5, #offset            │
  │ Array base address   │ ADD Rx, R5, #0                 │
  │ Negate index (i)     │ NOT R1; ADD R1, R1, #1         │
  │ Subscript address    │ ADD R0, base, (-i)             │
  │ Dereference          │ LDR R0, R0, #0                 │
  └──────────────────────┴────────────────────────────────┘
```

**Why does indexing subtract?** In C, arrays are laid out with `[0]` first. In LC3 the stack grows downward, so `[0]` occupies the highest address and each subsequent element is one slot lower. Adding index `i` in C becomes subtracting `i` in LC3 to step toward lower addresses.
