Is there a reason that the compiler chooses to initialize the array onto the stack and not as an array
in memory?

● Yes, there's a deliberate reason, and it's a valid design tradeoff.

  Why stack: The compiler treats all local variables uniformly — stack allocation is the rule for
  everything declared inside a function. Arrays are local variables, so they follow the same rule. This
  keeps the memory model simple and consistent with the LC-3 textbook calling convention.

  The alternative — placing initializer data as .FILL words in the data section and accessing via LD
  (PC-relative) — would work for arrays whose values are never modified. For the max example that would be
  fine since elements is read-only in practice.

  Why the stack approach is actually more correct here: int elements[] = {3,7,2,9,4} in C declares an
  automatic-duration array — it lives on the stack and is mutable. If the code wrote elements[2] = 99, the
  compiler must handle it. The stack approach supports that naturally. A static data section approach would
   only be safe if the array is const, which the compiler doesn't track yet.

  The real cost of the stack approach is runtime overhead: every time main is entered, it executes the
  initialization sequence (5 load-and-store pairs). For a one-shot program this doesn't matter, but it
  would matter if the array was declared inside a loop or called function.

  A future optimization worth considering: detect arrays with compile-time literal initializers declared at
   global scope (or static local scope) and emit them as .FILL blocks in the data section — which the
  compiler already does for scalar globals and static locals. That path is already in A_VAR_DECL codegen,
  it just doesn't handle arrays yet.

  via Claude 4/23/26