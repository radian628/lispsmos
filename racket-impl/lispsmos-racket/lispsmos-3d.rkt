#lang racket

(require "obj-parser.rkt")



(define (get-material-property-for-desmos property-getter key-number-map materials) 
    (define ambients 
        (map 
            (lambda (index) 
                (property-getter (hash-ref materials (hash-ref key-number-map (+ index 1))))) 
            (sequence->list (in-range (hash-count key-number-map)))))
    (cons `list (flatten ambients)))

(define get-material-ambient-colors 
    ((curry get-material-property-for-desmos) mtl-ka))
(define get-material-diffuse-colors 
    ((curry get-material-property-for-desmos) mtl-kd))
(define get-material-specular-colors 
    ((curry get-material-property-for-desmos) mtl-ks))
(define get-material-emission-colors 
    ((curry get-material-property-for-desmos) mtl-ke))
(define get-material-specular-highlight 
    ((curry get-material-property-for-desmos) mtl-ns))
(define get-material-ior
    ((curry get-material-property-for-desmos) mtl-ni))
(define get-material-dissolve
    ((curry get-material-property-for-desmos) mtl-d))
(define get-material-illumination-model
    ((curry get-material-property-for-desmos) mtl-illum))






(provide
    get-material-ambient-colors
    get-material-diffuse-colors
    get-material-specular-colors
    get-material-emission-colors
    get-material-specular-highlight
    get-material-ior
    get-material-dissolve
    get-material-illumination-model)






(define (get-obj-x-positions obj-file) 
    (cons 'list (map car (obj-vertices obj-file))))

(define (get-obj-y-positions obj-file) 
    (cons 'list (map cadr (obj-vertices obj-file))))

(define (get-obj-z-positions obj-file) 
    (cons 'list (map caddr (obj-vertices obj-file))))

(define (index-with lst indexer)
    (map (lambda (item)
        (list-ref lst (- item 1))
        ) indexer))

(define (cross v1 v2)
    (list
        (- (* (cadr v1) (caddr v2)) (* (caddr v1) (cadr v2)))
        (- (* (caddr v1) (car v2)) (* (car v1) (caddr v2)))
        (- (* (car v1) (cadr v2)) (* (cadr v1) (car v2)))
    ))

(define (normalize v)
    (define len (sqrt (+
        (* (car v) (car v)) 
        (* (cadr v) (cadr v)) 
        (* (caddr v) (caddr v)) 
    )))
    (list
        (/ (car v) len)
        (/ (cadr v) len)
        (/ (caddr v) len)
    )
    )

(define (get-obj-face-normals obj-file)
    (define positions (obj-vertices obj-file))
    (define (get-face-normal face) 
        (normalize (cross 
            (map - (list-ref positions (- (caar face) 1)) (list-ref positions (- (caadr face) 1)))
            (map - (list-ref positions (- (caar face) 1)) (list-ref positions (- (caaddr face) 1)))
        ))
    )
    (map get-face-normal (obj-faces obj-file))
    )


(define (get-obj-x-face-normals obj-face-normals) 
    (cons 'list (map car obj-face-normals)))

(define (get-obj-y-face-normals obj-face-normals) 
    (cons 'list (map cadr obj-face-normals)))

(define (get-obj-z-face-normals obj-face-normals) 
    (cons 'list (map caddr obj-face-normals)))


(define (get-obj-vertex-indices obj-file) 
    (define (get-indices-from-face face) (map car face))
    (cons 'list (flatten (map get-indices-from-face (obj-faces obj-file)))))

(define (get-obj-texcoord-indices obj-file) 
    (define (get-indices-from-face face) (map cadr face))
    (cons 'list (flatten (map get-indices-from-face (obj-faces obj-file)))))


(define (get-obj-normal-indices obj-file) 
    (define (get-indices-from-face face) (map caddr face))
    (cons 'list (flatten (map get-indices-from-face (obj-faces obj-file)))))

(define (get-polygon-material-list obj-materials material-map)
    (append '(list) (map (lambda (material)
        (hash-ref material-map material)) obj-materials)))





(struct mesh
    (obj face-normals materials))

(struct 3d-collection
    (meshes
    materials
    materials=>numbers
    numbers=>materials))

(require racket/hash)

(define (get-3d-collection obj-files mtl-files)
    (define (dehash-and-parse key value)
        (define parsed-obj (parse-obj value))
        (list key (mesh
            parsed-obj
            (get-obj-face-normals parsed-obj)
            (get-obj-materials value)
        )))
    (define meshes (apply hash (flatten (hash-map obj-files dehash-and-parse))))
    (define materials (foldl hash-union (hash) (map parse-mtl mtl-files)))
    (define materials=>numbers (get-key-number-mapping materials))
    (define numbers=>materials (get-key-number-mapping-reverse materials))
    (3d-collection
        meshes
        materials
        materials=>numbers
        numbers=>materials))

(provide 
    3d-collection
    get-3d-collection)

; (define (3d-col-face-normals 3d-col obj-name x-var y-var z-var)
;     (define face-normals (mesh-face-normals (hash-ref (3d-collection-meshes 3d-col) obj-name)))
;     `(
;         (= ,x-var ,(get-obj-x-face-normals face-normals))
;         (= ,y-var ,(get-obj-y-face-normals face-normals))
;         (= ,z-var ,(get-obj-z-face-normals face-normals))))


(define (3d-col-face-normals 3d-col obj-name)
    (define face-normals (mesh-face-normals (hash-ref (3d-collection-meshes 3d-col) obj-name)))
    (list 
        (get-obj-x-face-normals face-normals)
        (get-obj-y-face-normals face-normals)
        (get-obj-z-face-normals face-normals)))

(define (3d-col-positions 3d-col obj-name)
    (define obj (mesh-obj (hash-ref (3d-collection-meshes 3d-col) obj-name)))
    (list 
        (get-obj-x-positions obj)
        (get-obj-y-positions obj)
        (get-obj-z-positions obj)))

(define (3d-col-vertex-indices 3d-col obj-name)
    (define obj (mesh-obj (hash-ref (3d-collection-meshes 3d-col) obj-name)))
    (get-obj-vertex-indices obj))

(define (3d-col-texcoord-indices 3d-col obj-name)
    (define obj (mesh-obj (hash-ref (3d-collection-meshes 3d-col) obj-name)))
    (get-obj-texcoord-indices obj))

(define (3d-col-ambient-colors 3d-col)
    (get-material-ambient-colors 
        (3d-collection-numbers=>materials 3d-col) (3d-collection-materials 3d-col)))
(define (3d-col-diffuse-colors 3d-col)
    (get-material-diffuse-colors 
        (3d-collection-numbers=>materials 3d-col) (3d-collection-materials 3d-col)))
(define (3d-col-specular-colors 3d-col)
    (get-material-specular-colors 
        (3d-collection-numbers=>materials 3d-col) (3d-collection-materials 3d-col)))
(define (3d-col-emission-colors 3d-col)
    (get-material-emission-colors 
        (3d-collection-numbers=>materials 3d-col) (3d-collection-materials 3d-col)))

(define (3d-col-material-indices 3d-col mesh-name)
    (define materials (mesh-materials (hash-ref (3d-collection-meshes 3d-col) mesh-name)))
    (define material-map (3d-collection-materials=>numbers 3d-col))
    (get-polygon-material-list materials material-map))


(define (3d-col-texture-coordinates 3d-col obj-name)
    (define obj (mesh-obj (hash-ref (3d-collection-meshes 3d-col) obj-name)))
    (append '(list) 
        (map (lambda (pos) (list 'point
            (car pos)
            (cadr pos)
            )) (obj-texture-coordinates obj))))


(define (map-variables-to-values-lispsmos values variables)
    (define (map-fn var val) `(= ,var ,val))
    (map map-fn variables values))

(provide
    3d-col-face-normals
    3d-col-positions
    3d-col-vertex-indices
    3d-col-texcoord-indices

    3d-col-ambient-colors
    3d-col-diffuse-colors
    3d-col-specular-colors
    3d-col-emission-colors

    3d-col-material-indices

    3d-col-texture-coordinates

    map-variables-to-values-lispsmos)


(provide
    get-obj-x-positions
    get-obj-y-positions
    get-obj-z-positions
    index-with
    cross
    normalize
    get-obj-face-normals
    get-obj-x-face-normals
    get-obj-y-face-normals
    get-obj-z-face-normals
    get-obj-vertex-indices
    get-obj-normal-indices
    get-polygon-material-list)




; compile time dot product macro
(define (lispsmos-static-dot x1 y1 z1 x2 y2 z2)
    `(+ (* ,x1 ,x2) (* ,y1 ,y2) (* ,z1 ,z2)))


; compile time cross product macro
(define (lispsmos-static-cross x1 y1 z1 x2 y2 z2 x-out y-out z-out)
    `(
        (= ,x-out (- (* ,y1 ,z2) (* ,z1 ,y2)))
        (= ,y-out (- (* ,z1 ,x2) (* ,x1 ,z2)))
        (= ,z-out (- (* ,x1 ,y2) (* ,y1 ,x2)))
    )
)

; muller-trumbore ray-triangle-intersection algorithm
(define muller-trumbore-ray-triangle-intersection-formula
    `(
        (= xe1 (- x-tri2 x-tri1))
        (= ye1 (- y-tri2 y-tri1))
        (= ze1 (- z-tri2 z-tri1))
        (= xe2 (- x-tri3 x-tri1))
        (= ye2 (- y-tri3 y-tri1))
        (= ze2 (- z-tri3 z-tri1))
        ,@(lispsmos-static-cross 'xe1 'ye1 'ze1 'xe2 'ye2 'ze2 'x-normal 'y-normal 'z-normal)
        (= det (* -1 ,(lispsmos-static-dot 'x-dir 'y-dir 'z-dir 'x-normal 'y-normal 'z-normal)))
        (= invdet (/ 1 det))
        (= x-ao (- x-ray x-tri1))
        (= y-ao (- y-ray y-tri1))
        (= z-ao (- z-ray z-tri1))
        ,@(lispsmos-static-cross 'x-ao 'y-ao 'z-ao 'x-dir 'y-dir 'z-dir 'x-dao 'y-dao 'z-dao)
        (= u (* ,(lispsmos-static-dot 'xe2 'ye2 'ze2 'x-dao 'y-dao 'z-dao) invdet))
        (= v (* -1 ,(lispsmos-static-dot 'xe1 'ye1 'ze1 'x-dao 'y-dao 'z-dao) invdet))
        (= t (* ,(lispsmos-static-dot 'x-ao 'y-ao 'z-ao 'x-normal 'y-normal 'z-normal) invdet))
        (fn (muller-trumbore 
            x-ray y-ray z-ray
            x-dir y-dir z-dir
            x-tri1 y-tri1 z-tri1
            x-tri2 y-tri2 z-tri2
            x-tri3 y-tri3 z-tri3
        ) (piecewise
            ((< det 0.00001) -1)
            ((< t 0) -1)
            ((< u 0) -1)
            ((< v 0) -1)
            ((> (+ u v) 1) -1)
            ((> 2 1) t)))
        (fn (muller-trumbore-full-data
            x-ray y-ray z-ray
            x-dir y-dir z-dir
            x-tri1 y-tri1 z-tri1
            x-tri2 y-tri2 z-tri2
            x-tri3 y-tri3 z-tri3
        ) (piecewise
            ((< det 0.00001) (point -1 0))
            ((< t 0) (point -1 0))
            ((< u 0) (point -1 0))
            ((< v 0) (point -1 0))
            ((> (+ u v) 1) (point -1 0))
            ((
                point
                t
                (+
                    (floor (* 67108864 u))
                    (* 67108864 (floor (* 67108864 v)))
                )
            ))))
        (= barycentrics (+
            (+ 33554432 (floor (* 4096 u)))
            (* 67108864 (+ 33554432 (floor (* 4096 v))))
        ))
        (fn (muller-trumbore-full-data-with-invalid-barycentrics
            x-ray y-ray z-ray
            x-dir y-dir z-dir
            x-tri1 y-tri1 z-tri1
            x-tri2 y-tri2 z-tri2
            x-tri3 y-tri3 z-tri3
        ) (
                point
                t
                barycentrics
            ))))

(provide muller-trumbore-ray-triangle-intersection-formula
        lispsmos-static-dot
        lispsmos-static-cross)







(define (get-color-channel channel-offset pixels)
    (define lst (list))
    (map (lambda (index)
        (/ (bytes-ref pixels index) 256)) 
        (sequence->list (in-range channel-offset (bytes-length pixels) 4))))
(define get-alphas (curry get-color-channel 0))
(define get-reds (curry get-color-channel 1))
(define get-greens (curry get-color-channel 2))
(define get-blues (curry get-color-channel 3))

(provide get-alphas get-reds get-greens get-blues)




(define (symbol-append . args)
    (string->symbol (apply string-append (map symbol->string args))))

(define (first-person-rotate x y z h-angle v-angle x-out y-out z-out)
    `(
        (= ,(symbol-append x '-r1) (- (* ,x (cos ,h-angle)) (* ,z (sin ,h-angle))))
        (= ,(symbol-append z '-r1) (+ (* ,x (sin ,h-angle)) (* ,z (cos ,h-angle))))
        (= ,x-out ,(symbol-append x '-r1))
        (= ,y-out (- (* ,y (cos ,v-angle)) (* ,(symbol-append z '-r1) (sin ,v-angle))))
        (= ,z-out (+ (* ,y (sin ,v-angle)) (* ,(symbol-append z '-r1) (cos ,v-angle))))
    ))

(provide symbol-append first-person-rotate)