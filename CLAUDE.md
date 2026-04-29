# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build (from project root)
mkdir -p build && cd build && cmake .. && make

# Install to user's local bin
cp build/lc3-compile ~/.local/bin/lc3-compile

# Run compiler
./build/lc3-compile [OPTIONS] file.c

# Run tests
./build/test
```

The build uses CMake with debug flags enabled by default. The compiler executable is named `lc3-compile`.

**After committing changes**, always install the latest build:
```bash
cp build/lc3-compile ~/.local/bin/lc3-compile
```

## Compiler Usage

```
lc3-compile [OPTION...] file...
  -g, --debug      Enable debugging information
  -o, --output     Output path
  --sandbox        Disables type checking (for teaching flexibility)
  -S, --asm        Enable assembly output
  -v, --verbose    Produce verbose output
```

## Architecture Overview

This is a C-to-LC3 compiler following a traditional pipeline:

```
Source → Lexer → Parser → AST → Analysis → Code Generation → LC3 Assembly
```

The main entry point (`entry/main.c`) orchestrates: `build_ast()` → `analysis()` → `emit_ast()` → `write_to_file()`.

### Key Components

**Frontend (`src/frontend/`)**
- `lexer.c` - Character-by-character tokenization with position tracking
- `token.c` - 130+ token types for C syntax
- `parser.c` - Recursive descent parser with 8-token putback stack for lookahead
- `AST.c` - Handle-based AST storage (int32_t indices into static 100-node array), union-based variant types
- `symbol_table.c` - 100-entry table with scope hierarchy via `parent_scope[]` array
- `analysis.c` - Scope management, symbol validation, stack offset assignment
- `types.c` - Type specifiers decoupled from declarators (supports up to 8 declarator parts)
- `error.c` - Location-aware error collection with 8-slot buffers

**Code Generation (`src/codegen/`)**
- `codegen.c` - Tree-walking AST traversal, manages 4-register file (R0-R3 for expressions, R6-R7 for stack)
- `asmprinter.c` - Assembly block representation, emits LC3 instructions/directives
- `multiply.h` - Multiply/divide/modulo subroutine generation

**Calling Convention (caller-cleanup, textbook LC3)**
- Bootstrap is hard-coded in `asmprinter.c` (`write_program_header`): `LD R6, USER_STACK / ADD R5, R6, #-1 / JSR main / HALT`. The `HALT` after `JSR main` is the program's single exit point.
- `main` is treated as a regular function — same prologue, teardown, and `RET` as any other function. There is no `is_main` special-casing in the codegen.
- Frame pointer R5 is stable for the duration of a function; stack pointer R6 tracks live usage. Locals are at `R5+0, R5-1, ...`; saved R5 at `R5+1`, saved R7 at `R5+2`, return value at `R5+3`; parameters at `R5+4, R5+5, ...`.
- Arguments are pushed right-to-left by the caller. The caller pops the return slot and arguments after `RET`.

**Comparison Codegen**
- `emit_condition_branch(cond_node, false_label)` is the single entry point for `if`, `while`, and `for` conditions. It emits `left - right` (NZP set as a side effect of the final `ADD`) and selects the `BR` variant whose flags equal the negation of the comparison: `< → BRzp`, `> → BRnz`, `<= → BRp`, `>= → BRn`, `== → BRnp`, `!= → BRz`. Non-comparison conditions use `BRz` to skip when zero.
- `emit_condition_node` (older, less correct path) is still called when a comparison is used as a *value* (`int x = a < b;`). It returns the difference in a register rather than a 0/1 boolean — known limitation, separate from `emit_condition_branch`.

**Memory (`src/memory/`)**
- `bump_allocator.c` - Linear allocation for compile-time memory (no freeing)
- `linear_pool_allocator.c` - Pool-based alternative

**Utilities (`src/util/`)**
- `vector.h` - Macro-based generic vector template

### Important Patterns

1. **Handle-based AST**: Nodes are int32_t indices into `ast_instances[]` static array, not pointers
2. **Union-based variants**: Single `AST_NODE_STRUCT` with union for all node types
3. **Visitor pattern**: AST traversal supports PREORDER/POSTORDER for print, analysis, codegen
4. **Token putback**: Parser uses stack-based putback (8 tokens) for lookahead without backtracking
5. **Scope hierarchy**: Symbol table uses `parent_scope[]` array for upward scope chain traversal
6. **Static globals**: All compilation state in static globals (single compilation per process)

### LC3 Target Constraints

- 16-bit instruction set from "Introduction to Computing" textbook
- 4 registers for expression evaluation (R0-R3)
- Stack-based calling convention matching textbook conventions
- Direct AST-to-assembly (no intermediate representation)
- Supported types: int, char, void, pointers, functions (arrays/structs in development)

## Current Feature Limitations

Work in progress: string literals, multiplication/division operators, I/O library, arrays, structs/unions, typedefs, function pointers, C preprocessor.
