#lang racket

; struct for obj file
(struct obj (vertices texture-coordinates vertex-normals faces))

; parse obj file
(define (parse-obj obj-str)
    ; split by newlines and spaces
    (define split-spaces (lambda (str) (string-split str " ")))
    (define split-obj-str (map split-spaces (string-split obj-str "\n")))

    ; extract lines starting with tokens signfiying different attributes
    ; (e.g. 'f' for face, 'vn' for vertex normal, etc.)
    (define (extract-lines-starting-with begin-token)
        (map (lambda (vertex) (map string->number (cdr vertex))) (filter
        (lambda (line) (equal? (car line) begin-token)) split-obj-str))
    )

    ; split the faces
    (define (split-face face)
        (map string->number (string-split face "/")))

    ; get numerical data from the faces
    (define (extract-faces) 
        (map (lambda (vertex) (map split-face (cdr vertex))) (filter
        (lambda (line) (equal? (car line) "f")) split-obj-str)))

    ; extract data and assemble obj struct
    (define vertices (extract-lines-starting-with "v"))
    (define texture-coordinates (extract-lines-starting-with "vt"))
    (define vertex-normals (extract-lines-starting-with "vn"))
    (define faces (extract-faces))
    (obj vertices texture-coordinates vertex-normals faces)
)

; struct for mtl file
(struct mtl (
    ns
    ka
    kd
    ks
    ke
    ni
    d
    illum
))

; parse mtl file
(define (parse-mtl mtl-str)
    ; split mtl by spaces and newlines 
    (define material-strings (regexp-match* #px"newmtl[\\w\\W]+?(?=newmtl)" 
        (string-append mtl-str "newmtl")))
    (define material-lists (map (lambda (str) 
       (map (lambda (str2) (string-split str2 " ")) (string-split str "\n"))) material-strings))

    ; get lines starting with a given token
    (define (extract-lines-starting-with lines begin-token)
        (map (lambda (material-property) (map string->number (cdr material-property))) (filter
        (lambda (line) (and (not (empty? line)) (equal? (car line) begin-token))) lines))
    )

    ; get lines starting with a given token, but don't cast to number
    (define (extract-lines-starting-with-str lines begin-token)
        (map (lambda (material-property) (cdr material-property)) 
            (filter (lambda (line) (and (not (empty? line)) (equal? (car line) begin-token))) lines))
    )

    ; get a given material property
    (define (get-material-property material-list material-property)
        (define lines (extract-lines-starting-with material-list material-property))
        (if (eq? (length lines) 0) (list) lines)
    )

    ; create a lookup table for all materials
    (define (get-material-hash-pair material-list prev) 
        (define material-name-line 
            (extract-lines-starting-with-str material-list "newmtl"))
        (append prev (list
        (caar material-name-line)
        (mtl
            (get-material-property material-list "Ns")
            (get-material-property material-list "Ka")
            (get-material-property material-list "Kd")
            (get-material-property material-list "Ks")
            (get-material-property material-list "Ke")
            (get-material-property material-list "Ni")
            (get-material-property material-list "d")
            (get-material-property material-list "illum")
        )
    )))
    (apply hash (foldl get-material-hash-pair (list) material-lists))
)

; maps material names to numerical keys
(define (get-key-number-mapping hash-table)
    (apply hash (foldl (lambda (kv i prev) (append prev (list (car kv) (+ i 1)))) 
        (list) (hash->list hash-table) 
        (sequence->list (in-range (hash-count hash-table))))))

; maps numerical keys to material names
(define (get-key-number-mapping-reverse hash-table)
    (apply hash (foldl (lambda (kv i prev) (append prev (list (+ i 1) (car kv)))) 
        (list) (hash->list hash-table) 
        (sequence->list (in-range (hash-count hash-table))))))


; gets all the materials used in an obj file
(define (get-obj-materials obj-str)
    (define split-spaces (lambda (str) (string-split str " ")))
    (define split-obj-str (map split-spaces (string-split obj-str "\n")))
    (define current-material "")
    (define material-list (list))
    (for ((line (filter (lambda (item) (> (length item) 0)) split-obj-str)))
        (if (equal? (car line) "usemtl") 
            (set! current-material (cadr line)) void)
        (if (equal? (car line) "f") 
            (set! material-list (append material-list (list current-material))) void)
    )
    material-list
)








(provide obj obj-vertices obj-texture-coordinates obj-vertex-normals obj-faces)
(provide parse-obj)

(provide mtl parse-mtl
    mtl-ns
    mtl-ka
    mtl-kd
    mtl-ks
    mtl-ke
    mtl-ni
    mtl-d
    mtl-illum
)

(provide get-key-number-mapping get-key-number-mapping-reverse)

(provide get-obj-materials)