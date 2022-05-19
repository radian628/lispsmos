#lang racket

(require 
    "builtins.rkt"
)

(define (string-join sep)
    (lambda (start . operands)
        (string-append start (foldr 
            (lambda (cur prev) (string-append sep cur prev))
            ""
            operands))))

(define (parenthesize str) 
    (string-append "\u005Cleft(" str "\u005Cright)"))

(define (lispsmos-binop op)
    (lambda (start . operands)
        (parenthesize (string-append (compile-lispsmos-expression start) (foldr 
            (lambda (cur prev) (string-append op (compile-lispsmos-expression cur) prev))
            ""
            operands)))))

(define (lispsmos-binop-noparentheses op)
    (lambda (start . operands)
        (string-append (compile-lispsmos-expression start) (foldr 
            (lambda (cur prev) (string-append op (compile-lispsmos-expression cur) prev))
            ""
            operands))))

(define lispsmos-add (lispsmos-binop "+"))
(define lispsmos-sub (lispsmos-binop "-"))
(define lispsmos-mult (lispsmos-binop "*"))
(define lispsmos-comma (lispsmos-binop ","))

(define (lispsmos-div . operands)
    (match operands
        ((list a) (compile-lispsmos-expression a))
        ((list-rest a ... b) (string-append "\\frac{"
            (compile-lispsmos-expression (car a)) "}{"
            (apply lispsmos-div (cdr operands)) "}"))))

(define lispsmos-comma-noparentheses (lispsmos-binop-noparentheses ","))

(define lispsmos-gt (lispsmos-binop-noparentheses "\\gt "))
(define lispsmos-lt (lispsmos-binop-noparentheses "\\lt "))
(define lispsmos-ge (lispsmos-binop-noparentheses "\\ge "))
(define lispsmos-le (lispsmos-binop-noparentheses "\\le "))
(define lispsmos-eq (lispsmos-binop-noparentheses "="))


(define (lispsmos-pow a b) (parenthesize (string-append 
    (compile-lispsmos-expression a) "^{" (compile-lispsmos-expression b) "}")))

(define (lispsmos-builtin builtin)
    (lambda (start . operands)
        (string-append "\u005Coperatorname{" builtin "}" (apply lispsmos-comma (cons start operands)))))




(define (sigma-like-inner op-name counter-var start end body) 
    (string-append "\u005C" op-name "_{" counter-var "=" start "}^{" end "}" (parenthesize body)))

(define (sigma-like . params) (apply sigma-like-inner 
    `(,(symbol->string (car params)) . ,(map compile-lispsmos-expression (cdr params)))))

(define (contains? lst val) (if (member val lst) #t #f))



(define (lispsmos-point a b) (parenthesize (lispsmos-comma 
    (compile-lispsmos-expression a) (compile-lispsmos-expression b))))




(define (lispsmos-list . list-items)
    (string-append "\\left[" (apply lispsmos-comma-noparentheses list-items) "\\right]"))

(define (lispsmos-list-access list index) (string-append
    (compile-lispsmos-expression list) "\\left[" (compile-lispsmos-expression index) "\\right]"
))



(define (lispsmos-equal varname value)
    (string-append (compile-lispsmos-expression varname) "=" (compile-lispsmos-expression value)))
(define (lispsmos-action varname value)
    (string-append (compile-lispsmos-expression varname) "\\to " (compile-lispsmos-expression value)))



(define (lispsmos-piecewise . operands)
    (string-append "\\left\\{" (apply (string-join ",") (map (lambda (op)
            (match (length op)
                (2 (string-append 
                    (compile-lispsmos-expression (car op)) ":"
                    (compile-lispsmos-expression (cadr op))))
                (1 (compile-lispsmos-expression (car op)))
            )
        ) operands)) "\\right\\}")
    )



(define (lispsmos-factorial operand) 
    (string-append (compile-lispsmos-expression operand) "!"))



(define (lispsmos-list-comprehension expr . lists)
    (string-append "\\left[" (compile-lispsmos-expression expr) "\\operatorname{for}"
        (apply (string-join ",") (map (lambda (op) (string-append 
                (compile-lispsmos-expression (car op)) "="
                (compile-lispsmos-expression (cadr op)))) lists)) "\\right]"))




(define (lispsmos-function fn-name-parameters fn-body)
    (string-append (compile-lispsmos-expression (car fn-name-parameters)) 
        (apply lispsmos-comma (cdr fn-name-parameters))
        "=" (compile-lispsmos-expression fn-body)))



(define (lispsmos-function-call fn-name . fn-parameters)
    (string-append (compile-lispsmos-expression fn-name) (apply lispsmos-comma fn-parameters)))




(define (lispsmos-point-x point)
    (string-append (compile-lispsmos-expression point) ".x"))

(define (lispsmos-point-y point)
    (string-append (compile-lispsmos-expression point) ".y"))



(define (subscriptify var-name)
    (cond
        ((eq? (string-length var-name) 1) var-name)
        (else (string-append (substring var-name 0 1) "_{" (substring var-name 1) "}"))))

(define (to-desmos-var-name var-name)
    (subscriptify (regexp-replace* #rx"-" var-name "")))


(define (lispsmos-rand-norm count seed)
    (string-append
        "\\operatorname{normaldist}\\left(\\right)."
        (compile-lispsmos-expression (list 'random count seed))
    ))


(define (compile-lispsmos-expression expr)
    (cond
        ((list? expr)
            (cond

                ; arithmetic operators
                ((eq? (car expr) '+) (apply lispsmos-add (cdr expr)))
                ((eq? (car expr) '-) (apply lispsmos-sub (cdr expr)))
                ((eq? (car expr) '*) (apply lispsmos-mult (cdr expr)))
                ((eq? (car expr) '/) (apply lispsmos-div (cdr expr)))

                ((eq? (car expr) 'group) (apply lispsmos-comma (cdr expr)))

                ; logical operators
                ((eq? (car expr) '>) (apply lispsmos-gt (cdr expr)))
                ((eq? (car expr) '>=) (apply lispsmos-ge (cdr expr)))
                ((eq? (car expr) '<) (apply lispsmos-lt (cdr expr)))
                ((eq? (car expr) '<=) (apply lispsmos-le (cdr expr)))
                ((eq? (car expr) '==) (apply lispsmos-eq (cdr expr)))

                ; exponent 
                ((eq? (car expr) '^) (apply lispsmos-pow (cdr expr)))

                ; points
                ((eq? (car expr) 'point) (apply lispsmos-point (cdr expr)))
                ((eq? (car expr) '.x) (apply lispsmos-point-x (cdr expr)))
                ((eq? (car expr) '.y) (apply lispsmos-point-y (cdr expr)))

                ; sigma/pi notation
                ((eq? (car expr) 'sum) 
                    (apply sigma-like expr))
                ((eq? (car expr) 'prod) 
                    (apply sigma-like expr))

                ; list and list index access
                ((eq? (car expr) 'list) (apply lispsmos-list (cdr expr)))
                ((eq? (car expr) 'get) (apply lispsmos-list-access (cdr expr)))

                ; variable assignment
                ((eq? (car expr) '=) (apply lispsmos-equal (cdr expr)))

                ; action
                ((eq? (car expr) '->) (apply lispsmos-action (cdr expr)))

                ; piecewise
                ((eq? (car expr) 'piecewise) (apply lispsmos-piecewise (cdr expr)))
                
                ; factorial
                ((eq? (car expr) '!) (apply lispsmos-factorial (cdr expr)))
                
                ; list comprehension
                ((eq? (car expr) 'for) (apply lispsmos-list-comprehension (cdr expr)))

                ; function definition
                ((eq? (car expr) 'fn) (apply lispsmos-function (cdr expr)))

                ; raw latex expression
                ((eq? (car expr) 'latex) (cadr expr))

                ; random value from normal distribution
                ((eq? (car expr) 'rand-norm) (apply lispsmos-rand-norm (cdr expr)))

                ; builtin functions
                ((contains? builtins (car expr))
                    (apply (lispsmos-builtin (symbol->string (car expr))) (cdr expr)))

                ; fn call
                (else (apply lispsmos-function-call expr))
            ))
        ((eq? expr '...) "...")
        ((symbol? expr) (to-desmos-var-name (symbol->string expr)))
        ((string? expr) expr)
        ((number? expr) (car (regexp-split (regexp "0+$") (real->decimal-string expr 15))))
        (else "default")
    ))

(provide compile-lispsmos-expression)