#lang racket

(require 
    "../lispsmos-racket/lispsmos.rkt" 
    "../lispsmos-racket/obj-parser.rkt" 
    "../lispsmos-racket/lispsmos-3d.rkt"
    "triangle-intersect.rkt")


(define scene-obj (open-input-file "scene2.obj"))
(define scene-obj-contents (read-string 9999999 scene-obj))

(define scene-mtl (open-input-file "scene2.mtl"))
(define scene-mtl-contents (read-string 9999999 scene-mtl))

(define 3d-col (get-3d-collection (hash
    "scene" scene-obj-contents
) (list scene-mtl-contents)))





(define (shadowcast-pos-dimension dim)
    `(= ,(symbol-append 'shadowcast-positions dim)
        (+
            (*
                shadowcast-barycentric-coord-1
                (get ,(symbol-append dim '-vpos-r2) (get vertex-indices receiver-data))
            )
            (*
                shadowcast-barycentric-coord-2
                (get ,(symbol-append dim '-vpos-r2)  (get vertex-indices (+ 1 receiver-data)))
            )
            (*
                (- 1 
                    shadowcast-barycentric-coord-1 
                    shadowcast-barycentric-coord-2 )
                (get ,(symbol-append dim '-vpos-r2)  (get vertex-indices (+ 2 receiver-data)))
            )
        )
    )
)

(define lispsmos-code `(
    (= y x)
    ,@(map-variables-to-values-lispsmos
        (3d-col-positions 3d-col "scene") '(x-vpos y-vpos z-vpos))
    ,@(map-variables-to-values-lispsmos
        (3d-col-face-normals 3d-col "scene") '(x-normals y-normals z-normals))
    (= vertex-indices ,(3d-col-vertex-indices 3d-col "scene"))

    (fn (clamp x lo hi) (max lo (min hi x)))

    (= x-campos 0)
    (= y-campos 6)
    (= z-campos -12)
    (display (= rotation (point 0 0)))

    (= a 0.25)

    (= x-vpos-t (- x-vpos x-campos))
    (= y-vpos-t (- y-vpos y-campos))
    (= z-vpos-t (- z-vpos z-campos))
    ,@(first-person-rotate 'x-vpos-t 'y-vpos-t 'z-vpos-t '(.x rotation) '(.y rotation) 
        'x-vpos-r2 'y-vpos-r2 'z-vpos-r2)

    ,@(first-person-rotate 'x-normals 'y-normals 'z-normals '(* 1 (.x rotation)) '(* 1 (.y rotation)) 
        'x-normals-r2 'y-normals-r2 'z-normals-r2)
    ; (= x-normals-r1 x-normals)
    ; (= y-normals-r1 (- (* y-normals (cos (.y (* -1 rotation)))) (* z-normals (sin (.y (* -1 rotation))))))
    ; (= z-normals-r1 (+ (* y-normals (sin (.y (* -1 rotation)))) (* z-normals (cos (.y (* -1 rotation))))))
    ; (= x-normals-r2 (- (* x-normals-r1 (cos (.x (* -1 rotation)))) (* z-normals-r1 (sin (.x (* -1 rotation))))))
    ; (= y-normals-r2 y-normals-r1)
    ; (= z-normals-r2 (+ (* x-normals-r1 (sin (.x (* -1 rotation)))) (* z-normals-r1 (cos (.x (* -1 rotation))))))

    (= point-in-triangle-1 (list 1 4 ... (- (length vertex-indices) 1)))
    (= point-in-triangle-2 (list 2 5 ... (- (length vertex-indices) 1)))
    (= point-in-triangle-3 (list 3 6 ... (- (length vertex-indices) 1)))


    (= proj-pos (point (/ x-vpos-r2 z-vpos-r2) (/ y-vpos-r2 z-vpos-r2)))
    ;(display
    (= polygons (polygon
        (get proj-pos (get vertex-indices point-in-triangle-1))
        (get proj-pos (get vertex-indices point-in-triangle-2))
        (get proj-pos (get vertex-indices point-in-triangle-3))
    ))
    ;)

    (fn (sqrt x) (^ x 0.5))

    (= light-dir-x (* (/ (sqrt 3) 3) (cos a)))
    (= light-dir-y (/ (sqrt 3) -3))
    (= light-dir-z (* (/ (sqrt 3) 3) (sin a)))

    (= light-dir-x-r1 (- (* light-dir-x (cos (.x rotation))) (* light-dir-z (sin (.x rotation)))))
    (= light-dir-y-r1 light-dir-y)
    (= light-dir-z-r1 (+ (* light-dir-x (sin (.x rotation))) (* light-dir-z (cos (.x rotation)))))
    (= light-dir-x-r2 light-dir-x-r1)
    (= light-dir-y-r2 (- (* light-dir-y-r1 (cos (.y rotation))) (* light-dir-z-r1 (sin (.y rotation)))))
    (= light-dir-z-r2 (+ (* light-dir-y-r1 (sin (.y rotation))) (* light-dir-z-r1 (cos (.y rotation)))))

    (= ray-triangle-intersections 
        (for
            (muller-trumbore-full-data-with-invalid-barycentrics
                (+ (* light-dir-x 0.005) (get x-vpos caster-vert-index))
                (+ (* light-dir-y 0.005) (get y-vpos caster-vert-index))
                (+ (* light-dir-z 0.005) (get z-vpos caster-vert-index))
                light-dir-x light-dir-y light-dir-z
                (get x-vpos (get vertex-indices receiver-index-3))
                (get y-vpos (get vertex-indices receiver-index-3))
                (get z-vpos (get vertex-indices receiver-index-3))
                (get x-vpos (get vertex-indices (+ receiver-index-3 1)))
                (get y-vpos (get vertex-indices (+ receiver-index-3 1)))
                (get z-vpos (get vertex-indices (+ receiver-index-3 1)))
                (get x-vpos (get vertex-indices (+ receiver-index-3 2)))
                (get y-vpos (get vertex-indices (+ receiver-index-3 2)))
                (get z-vpos (get vertex-indices (+ receiver-index-3 2)))
            )
            (caster-vert-index (list 1 ... (length x-vpos)))
            (receiver-index-3 point-in-triangle-1)
        )
    )

    (= shadowcast-data
        (for 
            (piecewise
                ; eliminate cases where a triangle shadows itself
                ((= caster-index receiver-index) (point -11111 -1))

                ; eliminate cases where the receiver isn't facing the light
                ((> (+ 
                    (* (get x-normals (/ (+ 2 receiver-index) 3)) light-dir-x)
                    (* (get y-normals (/ (+ 2 receiver-index) 3)) light-dir-y)
                    (* (get z-normals (/ (+ 2 receiver-index) 3)) light-dir-z)
                ) 0) (point -11111 -1))

                ; eliminate cases where the caster is facing the light
                ; will not work if the scene has single-sided geometry
                ((> (+ 
                    (* (get x-normals (/ (+ 2 caster-index) 3)) light-dir-x)
                    (* (get y-normals (/ (+ 2 caster-index) 3)) light-dir-y)
                    (* (get z-normals (/ (+ 2 caster-index) 3)) light-dir-z)
                ) 0) (point -11111 -1))

                ; note to self: add another filter utilizing negative t-values
                ((= (+
                    (piecewise ((< (.x (get ray-triangle-intersections (+
                        (get vertex-indices (+ caster-index 0))
                        (* (/ (- receiver-index 1) 3) (length x-vpos))
                    ))) 0) 1) (0))
                    (piecewise ((< (.x (get ray-triangle-intersections (+
                        (get vertex-indices (+ caster-index 1))
                        (* (/ (- receiver-index 1) 3) (length x-vpos))
                    ))) 0) 1) (0))
                    (piecewise ((< (.x (get ray-triangle-intersections (+
                        (get vertex-indices (+ caster-index 2))
                        (* (/ (- receiver-index 1) 3) (length x-vpos))
                    ))) 0) 1) (0))
                ) 3) (point -11111 -1))

                ; ; eliminate cases where the receiver is in front of the caster
                ; ; note that this may be too expensive to be worth putting here due to piecewise stupidity
                ; ((>

                ;     (min
                ;         (+
                ;             (* (get x-vpos (+ receiver-index 0)) light-dir-x)
                ;             (* (get y-vpos (+ receiver-index 0)) light-dir-y)
                ;             (* (get z-vpos (+ receiver-index 0)) light-dir-z)
                ;         )
                ;         (+
                ;             (* (get x-vpos (+ receiver-index 1)) light-dir-x)
                ;             (* (get y-vpos (+ receiver-index 1)) light-dir-y)
                ;             (* (get z-vpos (+ receiver-index 1)) light-dir-z)
                ;         )
                ;         (+
                ;             (* (get x-vpos (+ receiver-index 2)) light-dir-x)
                ;             (* (get y-vpos (+ receiver-index 2)) light-dir-y)
                ;             (* (get z-vpos (+ receiver-index 2)) light-dir-z)
                ;         )
                ;     )

                ;     (max
                ;         (+
                ;             (* (get x-vpos (+ caster-index 0)) light-dir-x)
                ;             (* (get y-vpos (+ caster-index 0)) light-dir-y)
                ;             (* (get z-vpos (+ caster-index 0)) light-dir-z)
                ;         )
                ;         (+
                ;             (* (get x-vpos (+ caster-index 1)) light-dir-x)
                ;             (* (get y-vpos (+ caster-index 1)) light-dir-y)
                ;             (* (get z-vpos (+ caster-index 1)) light-dir-z)
                ;         )
                ;         (+
                ;             (* (get x-vpos (+ caster-index 2)) light-dir-x)
                ;             (* (get y-vpos (+ caster-index 2)) light-dir-y)
                ;             (* (get z-vpos (+ caster-index 2)) light-dir-z)
                ;         )
                ;     )

                ; ) (point -1 -1))

                ((get ray-triangle-intersections (+
                    (get vertex-indices (+ caster-index tri-index))
                    (* (/ (- receiver-index 1) 3) (length x-vpos))
                )))
            )
            (tri-index (list 0 1 2))
            (caster-index point-in-triangle-1)
            (receiver-index point-in-triangle-1)
        )
    )
    (= filtered-shadowcast-data (get shadowcast-data shadowcast-broadphase-filter))

    (= shadowcast-barycentric-coord-1 (/ (- (mod (.y filtered-shadowcast-data) 67108864) 33554432) 4096))
    (= shadowcast-barycentric-coord-2 (/ (- (floor (/ (.y filtered-shadowcast-data) 67108864)) 33554432) 4096))
    (= shadowcast-barycentric-coord-3 (- 1 shadowcast-barycentric-coord-1 shadowcast-barycentric-coord-2))

    (= shadowcast-broadphase-filter (get 
        (list 1 ... (length shadowcast-data)) 
        (> (.x shadowcast-data) -11111)    
    ))

    (= combined-index (
        + 1
        tri-index2 
        (- caster-index2 1)
        (* (- receiver-index2 1) (/ (length vertex-indices) 3))
    ))
    ; (= combined-index1 (
    ;     + 1
    ;     (/ (- caster-index 1) 3)
    ;     (* (/ (- receiver-index 1) 3) (/ (length vertex-indices) 3))
    ; ))

    ,(shadowcast-pos-dimension 'x)
    ,(shadowcast-pos-dimension 'y)
    ,(shadowcast-pos-dimension 'z)

    (= caster-data
        (get vertex-indices (get (for 
            (+ caster-index tri-index)
            (tri-index (list 0 1 2))
            (caster-index point-in-triangle-1)
            (receiver-index point-in-triangle-1)
        ) shadowcast-broadphase-filter))
    )
    (= caster-indices
        (get (for 
            caster-index
            (tri-index (list 0 1 2))
            (caster-index point-in-triangle-1)
            (receiver-index point-in-triangle-1)
        ) shadowcast-broadphase-filter)
    )
    (= receiver-data
        (get (for 
            receiver-index
            (tri-index (list 0 1 2))
            (caster-index point-in-triangle-1)
            (receiver-index point-in-triangle-1)
        ) shadowcast-broadphase-filter)
    )

    (= shadowcast-positions (point
        (/ shadowcast-positions-x shadowcast-positions-z)
        (/ shadowcast-positions-y shadowcast-positions-z)
    ))

    (fn (elementwise-mult p1 p2) (point (* (.x p1) (.x p2)) (* (.y p1) (.y p2))))

    (= shadowcast-polygon-x (
        +
        (* (.x shadowcast-polygon) (get x-vpos-r2 (get vertex-indices (+ (get receiver-data receiver-data-index) 1))))
        (* (.y shadowcast-polygon) (get x-vpos-r2 (get vertex-indices (+ (get receiver-data receiver-data-index) 2))))
        (* (- 1 (.x shadowcast-polygon) (.y shadowcast-polygon)) (get x-vpos-r2 (get vertex-indices (+ (get receiver-data receiver-data-index) 0))))
    ))

    (= shadowcast-polygon-y (
        +
        (* (.x shadowcast-polygon) (get y-vpos-r2 (get vertex-indices (+ (get receiver-data receiver-data-index) 1))))
        (* (.y shadowcast-polygon) (get y-vpos-r2 (get vertex-indices (+ (get receiver-data receiver-data-index) 2))))
        (* (- 1 (.x shadowcast-polygon) (.y shadowcast-polygon)) (get y-vpos-r2 (get vertex-indices (+ (get receiver-data receiver-data-index) 0))))
    ))

    (= shadowcast-polygon-z (
        +
        (* (.x shadowcast-polygon) (get z-vpos-r2 (get vertex-indices (+ (get receiver-data receiver-data-index) 1))))
        (* (.y shadowcast-polygon) (get z-vpos-r2 (get vertex-indices (+ (get receiver-data receiver-data-index) 2))))
        (* (- 1 (.x shadowcast-polygon) (.y shadowcast-polygon)) (get z-vpos-r2 (get vertex-indices (+ (get receiver-data receiver-data-index) 0))))
    ))

    (fn (transform-shadowcast-polygon shadowcast-polygon receiver-data-index)
        (point
            (/ shadowcast-polygon-x shadowcast-polygon-z)
            (/ shadowcast-polygon-y shadowcast-polygon-z)
        )
    )




    (= shadow-caster-normal-index (/ (+ 2 (get caster-indices caster-data-index)) 3))
    (= shadow-caster-normal-x (get x-normals-r2 shadow-caster-normal-index))
    (= shadow-caster-normal-y (get y-normals-r2 shadow-caster-normal-index))
    (= shadow-caster-normal-z (get z-normals-r2 shadow-caster-normal-index))

    (= shadow-caster-vpos-x (get x-vpos-r2 (get vertex-indices (get caster-indices caster-data-index))))
    (= shadow-caster-vpos-y (get y-vpos-r2 (get vertex-indices (get caster-indices caster-data-index))))
    (= shadow-caster-vpos-z (get z-vpos-r2 (get vertex-indices (get caster-indices caster-data-index))))

    (fn (eliminate-invalid-shadows shadowcast-polygon receiver-data-index caster-data-index)
        (piecewise
            ((< (min 
                (+
                    (* (- shadow-caster-vpos-x shadowcast-polygon-x) shadow-caster-normal-x)
                    (* (- shadow-caster-vpos-y shadowcast-polygon-y) shadow-caster-normal-y)
                    (* (- shadow-caster-vpos-z shadowcast-polygon-z) shadow-caster-normal-z)
                )
            ) -0.01) (list (point 999 999)))

            ( shadowcast-polygon)
        )
    )


    (fn (hypot x y z) (^ (+ (* x x) (* y y) (* z z)) 0.5))

    ;(= unsorted-polygons (join polygons shadowcast-polygons))
    (= nonshadow-polygon-depths 
        (/
            (+
                (hypot 
                    (get x-vpos-r2 (get vertex-indices point-in-triangle-1))
                    (get y-vpos-r2 (get vertex-indices point-in-triangle-1))
                    (get z-vpos-r2 (get vertex-indices point-in-triangle-1))
                )
                (hypot 
                    (get x-vpos-r2 (get vertex-indices point-in-triangle-2))
                    (get y-vpos-r2 (get vertex-indices point-in-triangle-2))
                    (get z-vpos-r2 (get vertex-indices point-in-triangle-2))
                )
                (hypot 
                    (get x-vpos-r2 (get vertex-indices point-in-triangle-3))
                    (get y-vpos-r2 (get vertex-indices point-in-triangle-3))
                    (get z-vpos-r2 (get vertex-indices point-in-triangle-3))
                )
            )
        3)
    )


    (= polygon-depths (join
        nonshadow-polygon-depths
        (- (get nonshadow-polygon-depths 
            (/ 
                (+ 2 (get receiver-data (list 1 4 ... (- (length receiver-data) 1))))
            3)) 0.1)
    ))

    (= brightnesses (min 0.1 (+ (* x-normals light-dir-x) (* y-normals light-dir-y) (* z-normals light-dir-z))))

    (display
        (= all-polygons (sort (join polygons shadowcast-polygons) (* -1 polygon-depths)))
        (fill-opacity 1)
        (lines #f)
        (color-latex (sort (join
        
            (rgb 
            (* -1 (* 256 
                brightnesses
            )) 0 0)

            (rgb (* 256 0.5 -1 0
                (get brightnesses (/ (+ 2 receiver-data) 3))
            ) 0 0)

        ) (* -1 polygon-depths)))
    )


    (= shadowcast-polygons
        
        (for
            (polygon 
                (transform-shadowcast-polygon (eliminate-invalid-shadows
                    (get-triangle-triangle-intersection-polygon
                        (point 0 0) (point 1 0) (point 0 1)
                        (point
                            (get shadowcast-barycentric-coord-1 shadowcast-index)
                            (get shadowcast-barycentric-coord-2 shadowcast-index)
                        )
                        (point
                            (get shadowcast-barycentric-coord-1 (+ shadowcast-index 1))
                            (get shadowcast-barycentric-coord-2 (+ shadowcast-index 1))
                        )
                        (point
                            (get shadowcast-barycentric-coord-1 (+ shadowcast-index 2))
                            (get shadowcast-barycentric-coord-2 (+ shadowcast-index 2))
                        )
                    )
                shadowcast-index shadowcast-index) shadowcast-index)
            )
            (shadowcast-index (list 1 4 ... (- (length shadowcast-barycentric-coord-1) 1)))
        )
    )

    (folder ("Ray-triangle Intersection Formula" #t)
        ,@muller-trumbore-ray-triangle-intersection-formula
    )
    (folder ("Triangle-Triangle Intersection Polygon Calculator" #t)
        ,@triangle-intersect-formula
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