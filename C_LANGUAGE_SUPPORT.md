# C Language Support

This document describes the C language features that the LC3 compiler correctly compiles to LC3 assembly.

## Data Types

| Type | Supported | Notes |
|------|-----------|-------|
| `int` | Yes | 16-bit signed integer (LC3 native word size) |
| `char` | Yes | 8-bit character type |
| `void` | Yes | Function return type only |
| `int*`, `char*` | Yes | Single-level pointers |
| `int**` | Yes | Multi-level pointers |

**Not Supported:** `float`, `double`, `short`, `long`, `unsigned`, `signed`, arrays, structs, unions, enums

## Variables and Storage

### Local Variables
```c
int main() {
    int a = 1;
    int b = 17;
    int c = a + b;
    return c;
}
```

### Global Variables
```c
int global_var = 100;

int main() {
    return global_var;
}
```

### Static Variables
Static variables retain their value across function calls:
```c
int accumulate() {
    static int x = 4;
    x = x + 1;
    return x;
}

int main() {
    accumulate();  // returns 5
    accumulate();  // returns 6
    return accumulate();  // returns 7
}
```

### Variable Initialization
Variables can be initialized at declaration:
```c
int a = 5;
int *p = &a;
```

## Operators

### Arithmetic Operators

| Operator | Supported | Example |
|----------|-----------|---------|
| `+` (addition) | Yes | `a + b` |
| `-` (subtraction) | Yes | `a - b` |
| `*` (multiplication) | Yes | `a * b` |
| `-` (unary negation) | Yes | `-a` |
| `+` (unary plus) | Yes | `+a` |

**Not Supported:** `/` (division), `%` (modulo)

### Comparison Operators

| Operator | Supported | Example |
|----------|-----------|---------|
| `<` (less than) | Yes | `a < b` |
| `>` (greater than) | Yes | `a > b` |

**Not Supported:** `<=`, `>=`, `==`, `!=`

### Increment and Decrement Operators

Both prefix and postfix forms are fully supported:

| Operator | Supported | Example |
|----------|-----------|---------|
| `++` (prefix increment) | Yes | `++a` |
| `++` (postfix increment) | Yes | `a++` |
| `--` (prefix decrement) | Yes | `--a` |
| `--` (postfix decrement) | Yes | `a--` |

```c
void main() {
    int a = 0;
    int b = 0;
    a++;    // postfix: a becomes 1
    ++a;    // prefix: a becomes 2
    b--;    // postfix: b becomes -1
    --b;    // prefix: b becomes -2
    return;
}
```

Increment/decrement works on:
- Local variables
- Parameters
- Dereferenced pointers (`(*p)++`)

### Assignment Operator

| Operator | Supported | Example |
|----------|-----------|---------|
| `=` (simple assignment) | Yes | `a = b` |

**Not Supported:** Compound assignment operators (`+=`, `-=`, `*=`, `/=`, `%=`, `<<=`, `>>=`, `&=`, `|=`, `^=`)

### Pointer Operators

| Operator | Supported | Example |
|----------|-----------|---------|
| `&` (address-of) | Yes | `&a` |
| `*` (dereference) | Yes | `*p` |

```c
int main() {
    int a = 15;
    int *p = &a;    // p holds address of a
    int b = *p;     // b gets value at address p (15)
    *p = 3;         // write through pointer
    return a;       // returns 3
}
```

### Logical and Bitwise Operators

**Not Supported:** `&&`, `||`, `!`, `&` (bitwise), `|`, `^`, `~`, `<<`, `>>`

### Other Operators

**Not Supported:** `?:` (ternary), `sizeof`, `,` (comma)

## Control Flow

### If Statements
```c
int main() {
    if (2 > 1) {
        return 3;
    }
    return 6;
}
```

### If-Else Statements
```c
int max(int a, int b) {
    if (a > b) {
        return a;
    } else {
        return b;
    }
}
```

Single-statement bodies (without braces) are also supported:
```c
if (a > b)
    return a;
else
    return b;
```

### While Loops
```c
int sum(int n) {
    int total = 0;
    int i = 1;
    while (i < n) {
        total = total + i;
        i++;
    }
    return total;
}
```

### For Loops
```c
int factorial(int n) {
    int result = 1;
    for (int i = 1; i < n; i++) {
        result = result * i;
    }
    return result;
}
```

For loop components:
- Initialization (including variable declarations)
- Condition
- Update expression

### Return Statement
```c
int add(int a, int b) {
    return a + b;
}

void do_nothing() {
    return;  // void return
}
```

**Not Supported:** `do-while`, `switch`/`case`/`default`, `break`, `continue`, `goto`

## Functions

### Function Definitions
```c
int add_2(int a, int b) {
    int c = a + b;
    return c;
}
```

### Function Calls
```c
int main() {
    int result = add_2(5, 9);
    return result;
}
```

### Multiple Functions
Multiple functions can be defined in a single file:
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
    int a = 5;
    int b = 9;
    int c = add_2(a, b);
    int d = sub_2(a, b);
    return;
}
```

### Recursion
Recursive function calls are fully supported:
```c
int fib(int n) {
    if (2 > n) {
        return n;
    }
    int a = fib(n-1);
    int b = fib(n-2);
    return a + b;
}

int main() {
    return fib(11);  // returns 89
}
```

### Pass by Reference
Use pointers to modify variables in the caller's scope:
```c
void change_to_five(int* a) {
    *a = 5;
    return;
}

int main() {
    int b = 10;
    change_to_five(&b);
    return b;  // returns 5
}
```

### Calling Convention
The compiler follows the LC3 textbook calling convention:
- Parameters passed on the stack (right-to-left)
- R5 as frame pointer
- R6 as stack pointer
- R7 as return address
- Return value stored at R5+3

## Pointers

### Pointer Declaration and Assignment
```c
int x = 1234;
int *p_x;
p_x = &x;
```

### Pointer Initialization
```c
int a = 15;
int *c = &a;
```

### Dereferencing (Reading)
```c
int a = 15;
int b = *(&a);    // b = 15
int *c = &a;
int d = *c;       // d = 15
```

### Dereferencing (Writing)
```c
int a = 15;
int* b = &a;
*b = 3;           // a is now 3
```

### Null Pointers
```c
int *p_z = 0;
```

## Inline Assembly

Embed raw LC3 assembly instructions using the `__asm` construct:
```c
int main() {
    __asm("ADD R0, R0, #5");
    return 0;
}
```

## Storage Classes and Qualifiers

| Keyword | Support |
|---------|---------|
| `static` | Supported for local variables |
| `const` | Parsed but not enforced |
| `extern` | Not supported |
| `auto` | Not supported |
| `register` | Not supported |
| `volatile` | Parsed but not enforced |
| `typedef` | Not supported |

## Expression Evaluation

### Operator Precedence
The compiler implements standard C operator precedence via Pratt parsing:
1. Postfix operators (function calls, `++`, `--`)
2. Unary operators (`&`, `*`, `-`, `+`, `++`, `--`)
3. Multiplicative (`*`)
4. Additive (`+`, `-`)
5. Relational (`<`, `>`)
6. Assignment (`=`)

### Parenthesized Expressions
Parentheses override default precedence:
```c
int x = (a + b) * c;
```

## Scoping

### Function Scope
Each function has its own local scope for variables.

### Block Scope
Compound statements (`{ }`) create new scopes:
```c
int main() {
    int x = 1;
    {
        int x = 2;  // different variable
    }
    return x;  // returns 1
}
```

## Limitations Summary

The following C features are **not supported**:
- Division (`/`) and modulo (`%`) operators
- Comparison operators `<=`, `>=`, `==`, `!=`
- Logical operators (`&&`, `||`, `!`)
- Bitwise operators (`&`, `|`, `^`, `~`, `<<`, `>>`)
- Compound assignment operators (`+=`, `-=`, etc.)
- Ternary operator (`?:`)
- Arrays
- Structures and unions
- Enums
- String literals (lexer recognizes them but code generation is incomplete)
- `do-while` loops
- `switch`/`case`/`default` statements
- `break` and `continue`
- `goto` statements
- Function pointers
- `typedef`
- C preprocessor directives (`#include`, `#define`, etc.)
