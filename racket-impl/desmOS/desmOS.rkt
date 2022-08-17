#lang racket

(require 
    "../lispsmos-racket/lispsmos.rkt")

(define instr-index 0)

(define (get-instr) 
    (set! instr-index (+ instr-index 1))
    instr-index)

(define data-segment-pointer 2)
(define cache-start 3)

(define (generic-binop operator)
`(list-replace data (+ ,cache-start (getreg1 iptr))
        (,operator
            (get data (+ ,cache-start (getreg1 iptr)))
            (get data (+ ,cache-start (getreg2 iptr)))
        )    
    )
    )

(define (nest-exec n)
    (match n
        (0 'cache)
        (x `(exec ,(nest-exec (- n 1))))
    ))

(define code (compile-lispsmos `(

    (group
        (-> cache 
            ,(nest-exec 50))
        (-> mem (do-mem-op cache mem))
    )
        ;(exec (exec (exec (exec (exec cache))))))

    (folder ("instructions" #t)

        ; contents of data:
        ;   1 instruction pointer
        ;   2 op1
        ;   3 op2
        ;   4 op3
        ;   5+ cache
        (= iptr (get mem (+ 1 (get data 1))))
        (= instr-index (mod iptr 1024))
        (fn (do-mem-op data memory) 
            (piecewise
                ((== instr-index memwrite1)
                    (list-splice 
                        memory 
                        (get data (list (get-register (getreg2 iptr)) ... (+ (get-register (getreg2 iptr)) (get-register (getreg3 iptr)))))
                        (get-register (getreg1 iptr))
            ))
                            (memory)
            ))
        (fn (exec data)
            (piecewise
                ((== instr-index add1) ,(generic-binop '+))
                ((== instr-index sub1) ,(generic-binop '-))
                ((== instr-index mul1) ,(generic-binop '*))
                ((== instr-index div1) ,(generic-binop '/))

                ((== instr-index mov1)
                    (list-replace data (+ ,cache-start (getreg1 iptr))
                    (get data (+ ,cache-start (getreg2 iptr)))
                ))

                ((== instr-index todyn-mov1)
                    (list-replace data 
                    (+ ,cache-start (get data (+ ,cache-start (getreg1 iptr))))
                    (get data (+ ,cache-start (getreg2 iptr)))
                ))
                
                ((== instr-index set1)
                    (list-replace data (+ ,cache-start (getreg1 iptr))
                    (get mem (+ 1 (get data ,data-segment-pointer) (getreg2 iptr)))
                ))

                ((== instr-index jmp1)
                    (join 
                    (+ (get data 1) (get mem (+ 1 (get data ,data-segment-pointer) (getreg1 iptr))))
                    (get data (list 2 ... (length data)))))

                ((== instr-index jz1)
                    (join 
                    (piecewise
                        ((== (get-register (getreg2 iptr)) 0)
                            (+ (get data 1) (get mem (+ 1 (get data ,data-segment-pointer) (getreg1 iptr)))))
                        ((+ (get data 1) 1))
                    )
                    
                    (get data (list 2 ... (length data)))))

                ((== instr-index jnz1)
                    (join 
                    (piecewise
                        ((> (get-register (getreg2 iptr)) 0)
                            (+ (get data 1) (get mem (+ 1 (get data ,data-segment-pointer) (getreg1 iptr)))))
                        ((< (get-register (getreg2 iptr)) 0)
                            (+ (get data 1) (get mem (+ 1 (get data ,data-segment-pointer) (getreg1 iptr)))))
                        ((+ (get data 1) 1))
                    )
                    
                    (get data (list 2 ... (length data)))))
                
                ((== instr-index memwrite1) data)
            )
        )
        
        (fn (get-register index) (get data (+ ,cache-start index)))
        (fn (binop r1 r2) (+ (* 1024 r1) (* 1048576 r2)))
        (fn (ternop r1 r2 r3) (+ (* 1024 r1) (* 1048576 r2) (* 1073741824 r3)))
        (fn (getreg1 op) (mod (floor (/ op 1024)) 1024))
        (fn (getreg2 op) (mod (floor (/ op 1048576)) 1024))
        (fn (getreg3 op) (floor (/ op 1073741824)))

        ; simple arithmetic (src reg1, reg2; dst reg1)
        (= add1 ,(get-instr))
        (fn (add r1 r2) 
            (+ add1 (binop r1 r2)))
        (= sub1 ,(get-instr))
        (fn (sub r1 r2) 
            (+ sub1 (binop r1 r2)))
        (= mul1 ,(get-instr))
        (fn (mul r1 r2) 
            (+ mul1 (binop r1 r2)))
        (= div1 ,(get-instr))
        (fn (div r1 r2) 
            (+ div1 (binop r1 r2)))

        ; move instructions
        (= mov1 ,(get-instr))
        (fn (mov r1 r2) 
            (+ mov1 (binop r1 r2)))

        (= todyn-mov1 ,(get-instr))
        (fn (todyn-mov r1 r2) 
            (+ todyn-mov1 (binop r1 r2)))

        ; set instructions
        (= set1 ,(get-instr))
        (fn (set reg val)
            (+ set1 (* reg 1024) (* val 1048576)))

        (= jmp1 ,(get-instr))
        (fn (jmp offset)
            (+ jmp1 (* offset 1024)))

        (= jz1 ,(get-instr))
        (fn (jz offset reg)
            (+ jz (binop offset reg)))

        (= jnz1 ,(get-instr))
        (fn (jnz offset reg)
            (+ jnz1 (binop offset reg)))

        (= memwrite1 ,(get-instr))
        (fn (memwrite dst src size)
            (+ memwrite1 (ternop dst src size)))
    )

    (folder ("memory" #t)

        ; program to print out 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20
        (= mem (list
            (set 0 0) ; set register 0 (cache pointer) to 3
            (set 1 1) ; set register 1 (pseudo-immediate operand) to 1
            (set 3 3) ; set register 3 (loop counter) to 10 (loop 10 times)

            ; increase register 2 by 2
            (add 2 1)
            (add 2 1)

            ; increase register 0 by 1
            (add 0 1)

            ; move register 2 to the cache index specified by register 0
            ; i.e. "print" register 2
            (todyn-mov 0 2)

            ; subtract counter for loop
            (sub 3 1)

            ; if the loop is over, end it
            (jnz 2 3)


            (set 4 3) ; register 3 is now 10
            (memwrite 1 1 4) ; write 10 numbers--- starting at cache index 1--- to memory
            3
            1
            -5
            10 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
        ))


        (= cache (list
            ; instructon pointer
            0
            ; data segment register (start of data segment)
            11
            ; cache
            0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
        ))
    )
    (folder ("utils" #t)
        (fn (list-replace lst index new)
            (join (+ (get lst 1) 1) (for (piecewise
                
                ((== i index) new)
                ((get lst i))
            ) (i (list 2 ... (length lst))))))
        (fn (list-swap lst index1 index2)
            (join (+ (get lst 1) 1) (for (piecewise
                
                ((== i index1) (get lst index2))
                ((== i index2) (get lst index1))
                ((get lst i))
            ) (i (list 2 ... (length lst))))))
        (fn (list-splice lst1 lst2 start)
            (for (piecewise
                
                ((<= i start) (get lst1 i))
                ((> i (+ start (length lst2))) (get lst1 i))
                ((get lst2 (- i start)))
            ) 
            (i (list 1 ... (max (length lst1) (+ start (length lst2)))))))
    )
)))

(require web-server/http web-server/servlet-env)

(define (hello req)
    (response/output
        (lambda (out)
            (display code out))
            #:headers (list (header #"Access-Control-Allow-Origin" #"*"))
            ))

(serve/servlet hello
#:listen-ip "localhost"
#:port 8080
)