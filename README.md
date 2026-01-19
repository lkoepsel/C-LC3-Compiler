# C-LC3-Compiler

C-LC3-Compiler is a modern, student built, C compiler targeting the LC3 Assembly language as described in *Introduction to Computing* by Dr. Yale Patt and Dr. Sanjay Patel. This tool is mainly for educational purposes, and is specifically meant to help students taking ECE 220 - Computer Systems & Programming at UIUC, however it should be relevant and useful to any student learning LC3 Assembly. The calling conventions implemented by the compiler mirror the conventions described in *Introduction to Computing*, any discrepencies are bugs.

This repository contains the source code for the compiler, as well as various tests. Currently, only a subset of the C language is supported. Some important features we are working on include:

- String literals
- C operator subroutines (multiplication, division, etc.)
- I/O library functions
- Arrays
- Structs and Unions
- Typedefs
- Function Pointers
- C Preprocessor

Some compiler explorer integration features we are working on include:

- Assembly documentation
- Instruction highlighting in source
- Code execution

## Build Instructions

### Raspberry Pi Install

This is a two step install program which will update a freshly minted Raspberry Pi, install this repo, then build and test the C compiler.

1. Update the Raspberry Pi to the latest:
```bash
sudo apt update && sudo apt full-upgrade -y
```

2. Clone, build and test the C Compiler
```bash
curl -fsSL https://raw.githubusercontent.com/lkoepsel/C-LC3-Compiler/main/scripts/quick-install.sh | bash
```
### Original Instructions to build locally

To build the compiler locally,
1. Ensure you have CMake, and clang installed. 
  `sudo apt install cmake`
2. `git clone https://github.com/xavierrouth/C-LC3-Compiler.git`
3. `cd C-LC3-Compiler`
4. `mkdir build`
5. `cd build`
6. `cmake ..`
7. `make`
8. ./lc3-compile ../../lc3/main.c -S -v -o ../../lc3/main.asm

### Usage Guide
To run the compiler, use `lc3-compile`:

```
Usage: lc3-compile [OPTION...] file...

  -g, --debug                Enable debugging information
  -o, --output=FILE          Output path
      --sandbox              Disables most semantic analysis errors (type
                             checking)
  -S, --asm                  Enable assembly output
  -v, --verbose              Produce verbose output
  -?, --help                 Give this help list
      --usage                Give a short usage message
  -V, --version              Print program version

Mandatory or optional arguments to long options are also mandatory or optional
for any corresponding short options.

Report bugs to <xrouth2@illinois.edu>.
```

To run the tests, run the `test` executable from the build directory.

### LC3Tools
This project uses the [LC3Tools](https://github.com/gt-cs2110/lc3tools) repository in order to assemble and verify the assembly generated from the compiler. Students working with LC3 may find tools from there helpful as well.

### Credits
The C-LC3-Compiler is developed and maintained by students from [HKN-Alpha](https://hkn-alpha.netlify.app/) at UIUC.

This version (*lkoepsel*) has been extensively update with the help of Claude AI to fix some bugs and add functionality.

