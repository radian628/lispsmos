# LISPsmos
LISPsmos is a LISP-like programming language that maps almost directly to Desmos expressions, offering an alternate, text-based workflow and tooling. 

Along with most Desmos features, LISPsmos comes with builtin support for the following:
- Procedural expressions for creating complex conditional logic and branching trees of actions. LISPsmos will automatically convert structured, procedural code (using if, while, procedure calls, etc.) into a piecewise with a program counter positioned at the start of the given entry point. Procedure calls can be recursive.
- Simple "find and replace" macros, along with token concatenation features.
- Macros that evaluate arbitrary JavaScript code to transform an AST (Abstract Syntax Tree).

## Features
```lisp
(= a 1) ;variable assignment
(-> a (+ a 1)) ;actions and arithmetic operators
(= tenDividedByFive (/ 10 5)) ;longer variable names are automatically made subscript
```