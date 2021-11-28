# LISPsmos
LISPsmos is a LISP-like programming language that maps almost directly to Desmos expressions, offering an alternate, text-based workflow and tooling. 

Along with most Desmos features, LISPsmos comes with builtin support for the following:
- Procedural expressions for creating complex conditional logic and branching trees of actions. LISPsmos will automatically convert structured, procedural code (using if, while, procedure calls, etc.) into a piecewise with a program counter positioned at the start of the given entry point. Procedure calls can be recursive.
- Simple "find and replace" macros, along with token concatenation features.
- Macros that evaluate arbitrary JavaScript code to transform an AST (Abstract Syntax Tree).

## Features
### Basic Usage
```lisp
(= a 1) ;variable assignment
(-> a (+ a 1)) ;actions and arithmetic operators
(= tenDividedByFive (/ 10 5)) ;longer variable names are automatically made subscript
```

### Functions
```lisp
;The positive solution to the quadratic formula.
(fn quadraticFormulaPositiveSoln a b c (
    / 
    (+ (* -1 b) (sqrt (- (* b b) (* 4 a c)))) 
    (* 2 a)
))
```

### Piecewises
```lisp
;Print x if x>=0, and -x if x<0. Effectively mimics the absolute value function.
;You'll need to manually turn on the display for this (disabled by default)
(fn absoluteValue x (piecewise
    ((>= x 0) x)
    ((< x 0) (* -1 x))
))
```

### Display
```lisp
(displayMe ;indicates that the expression should be displayed
    (= y x) ;expression to display
    (color red) ;all subsequent arguments to displayMe are optional display settings
    (lineWidth 30) 
    (lineOpacity 0.2) 
    (lineStyle DOTTED)
)
```

### Find-and-replace Macros
```lisp
;macro that increments a variable
(defineFindAndReplace inc v (-> v (+ v 1)))
(= i 0)
;expands to (-> i (+ i 1))
(inc i)
```

### JavaScript Evaluation Macros
```lisp
;macro that calls the following function on its arguments
(evalMacro inc "return [['->', args[1], ['+', args[1], '1']]]")
(= a 0)
(inc a) ;application of the macro. All macros of this type are variadic.
```