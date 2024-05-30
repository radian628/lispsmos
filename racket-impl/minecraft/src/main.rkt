#lang racket

(require 
    "../../lispsmos-racket/lispsmos.rkt" 
    "../../lispsmos-racket/obj-parser.rkt" 
    "../../lispsmos-racket/lispsmos-3d.rkt"
    "./image-helpers.rkt"
    json)

(define pixel-array (get-argb-pixels-from-file "../assets/texture.png"))

(define glowstone (get-number-color-subregion 
    (list-ref pixel-array 0) (list-ref pixel-array 1) (list-ref pixel-array 2)
     0 0 64 64))

; (define glowstone2 (get-number-color-subregion 
;     (list-ref pixel-array 0) (list-ref pixel-array 1) (list-ref pixel-array 2)
;      32 0 20 20))

(define (num-to-rgb-triplet num)
    `(rgb
        ,(modulo num 256)
        ,(modulo (floor (/ num 256)) 256)
        ,(modulo (floor (/ num 65536)) 256)
    ))

(define-values (js-proc js-in js-out js-err) (subprocess #f #f #f (find-executable-path "node") "ts/dist/index.mjs"))

(display (jsexpr->string (hash
    'glowstone (hash
        'type "image-edges"
        'colors glowstone
        'w 64 
        'h 64
    )
    ; 'glowstone2 (hash
    ;     'type "image-edges"
    ;     'colors glowstone2
    ;     'w 20
    ;     'h 20
    ; )
)) js-out)
(close-output-port js-out)
; (subprocess-wait js-proc)

(define js-process-output "")

(define (read-string-loop)
    (set! js-process-output (string-append js-process-output 
        (sync (read-string-evt 32768 js-in))))
    (cond ((eq? (subprocess-status js-proc) 'running) (read-string-loop))))

(read-string-loop)

; (display "got here1\n")
; (define js-process-output (port->string js-in))
(display js-process-output (open-output-file "test.json" #:exists 'replace))
(define glowstone-edges (hash-ref (string->jsexpr js-process-output) 'glowstone))
; (display "got here2\n")
; (display (port->string js-err))
; (display "got here3\n")

; (display (get-image-borders (list-ref pixel-array 0) (list-ref pixel-array 1) (list-ref pixel-array 2)
;     0 0 16 16))

(define (list-repeat elem n)
    (foldl (lambda (i lst) (append lst elem)) (list) (range n)))

(hash-ref glowstone-edges 'vertexPositions)

(define glowstone-colors (map num-to-rgb-triplet (hash-ref glowstone-edges 'uniqueColors)))

(define glowstone-verts (map (lambda (point-list)
            `(polygon ,@(map (lambda (pt) `(point ,@(if (eq? (car pt) -1) '(0 (/ 0 0)) pt))) point-list)))
            (hash-ref glowstone-edges 'vertexPositions)))

(define lispsmos-code `(
    (folder ("data" #t)
        (display (= y (^ x 2)))
        (= glowstone-colors (list ,@glowstone-colors))
        (display
            (= glowstone-verts (list ,@glowstone-verts))
            (color-latex glowstone-colors)
            (lines #f)
            (fill-opacity 1)
        )
    )
))

(define compiled-lispsmos-code (compile-lispsmos lispsmos-code))

(require web-server/http web-server/servlet-env)

(define (hello req)
    (response/output
        (lambda (out)
            (display compiled-lispsmos-code out))
            #:headers (list (header #"Access-Control-Allow-Origin" #"*"))
            ))

(serve/servlet hello
#:listen-ip "localhost"
#:port 8080
)