#lang racket

(require racket/hash)

; register names:
; ip = instruction pointr 

(define (is-register str)
    (equal? (substring str 0 1) "r"))

(define (get-reg-num str)
    (string->number (substring str 1)))

(define (math-binop binop-name line)
    (define oprr (string->symbol (string-append binop-name "rr")))
    (define opri (string->symbol (string-append binop-name "ri")))
    (define op1 (cadr line))
        (define op2 (caddr line))
        (match (is-register op2)
            (#t (list oprr (get-reg-num op1) (get-reg-num op2)))
            (#f (list opri (get-reg-num op1) (string->number op2)))))

(define (compile-asm asm-source)
    ; separate lines
    (define lines (map string-trim (string-split asm-source "\n")))

    ; separate tokens
    (define (split-line line) (string-split line #rx"\\s+"))
    (define split-lines (map split-line lines))

    (define (create-alias-map-entry line map)
        (match (length line)
            (0 map)
            (n 
                (match (car line)
                    ("alias" (hash-union map (hash (cadr map) (caddr map))))
                    (s map)
                )))
        )
    (define alias-map (foldl create-alias-map-entry (hash) split-lines))

    (define (set-alias token)
        (hash-ref alias-map token token))

    (define (decode-assembly-instruction line line-no prev-lines)
        (match (length line)
            (0 prev-lines)
            (n 
                (append prev-lines (list (match (car line)

                    ; math instructions
                    ("add" (math-binop "add" line))
                    ("sub" (math-binop "sub" line))
                    ("mul" (math-binop "mul" line))
                    ("div" (math-binop "div" line))
                    ("mov" (math-binop "mov" line))
                    ("mod" (math-binop "mod" line))
                    (str (string->symbol str))
                )))))
        )
    

    (foldl decode-assembly-instruction '() split-lines (stream->list (in-range (length split-lines)))))

(define test-file (open-input-file "test.desmossembly"))
(compile-asm (read-string 99999999 test-file))
