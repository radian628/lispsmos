#lang racket

(require 
    "../lispsmos-racket/lispsmos.rkt" 
    "../lispsmos-racket/obj-parser.rkt" 
    "../lispsmos-racket/lispsmos-3d.rkt"
    "triangle-intersect.rkt")


(define scene-obj (open-input-file "scene3.obj"))
(define scene-obj-contents (read-string 9999999 scene-obj))
(define mirrors-obj (open-input-file "mirrors.obj"))
(define mirrors-obj-contents (read-string 9999999 mirrors-obj))

(define scene-mtl (open-input-file "scene3.mtl"))
(define scene-mtl-contents (read-string 9999999 scene-mtl))

(define 3d-col (get-3d-collection (hash
    "scene" scene-obj-contents
    "mirrors" mirrors-obj-contents
) (list scene-mtl-contents)))





(define lispsmos-code `(
    (= y x)
    (folder ("3D Mesh Data" #t)
        ,@(map-variables-to-values-lispsmos
            (3d-col-positions 3d-col "scene") '(x-vpos y-vpos z-vpos))
        ,@(map-variables-to-values-lispsmos
            (3d-col-face-normals 3d-col "scene") '(x-normals y-normals z-normals))
        (= vertex-indices ,(3d-col-vertex-indices 3d-col "scene"))


        ,@(map-variables-to-values-lispsmos
            (3d-col-positions 3d-col "mirrors") '(x-mvpos y-mvpos z-mvpos))
        ,@(map-variables-to-values-lispsmos
            (3d-col-face-normals 3d-col "mirrors") '(x-mnormals y-mnormals z-mnormals))
        (= m-vertex-indices ,(3d-col-vertex-indices 3d-col "mirrors"))
    )

    (fn (clamp x lo hi) (max lo (min hi x)))

    (= x-campos 4.4)
    (= y-campos 5)
    (= z-campos -6.9)
    (display (= rotation (point -0.315 -0.41)))

    (= a 0.25)

    (= obj-rotation 0)


    ,@(first-person-rotate 'x-vpos 'y-vpos 'z-vpos 'obj-rotation 0 
        'x-vpos-t1 'y-vpos-t1 'z-vpos-t1)

    (= x-vpos-t (- x-vpos-t1 x-campos))
    (= y-vpos-t (- y-vpos-t1 y-campos))
    (= z-vpos-t (- z-vpos-t1 z-campos))


    (= x-mvpos-t (- x-mvpos x-campos))
    (= y-mvpos-t (- y-mvpos y-campos))
    (= z-mvpos-t (- z-mvpos z-campos))

    ,@(first-person-rotate 'x-vpos-t 'y-vpos-t 'z-vpos-t '(.x rotation) '(.y rotation) 
        'x-vpos-r22 'y-vpos-r22 'z-vpos-r22)

    ,@(first-person-rotate 'x-normals 'y-normals 'z-normals '(+ obj-rotation (.x rotation)) '(* 1 (.y rotation)) 
        'x-normals-r2 'y-normals-r2 'z-normals-r2)

    (= x-vpos-r2 (+ x-vpos-r22 3))
    (= y-vpos-r2 (+ y-vpos-r22 1.5))
    (= z-vpos-r2 (+ z-vpos-r22 1))

    ,@(first-person-rotate 'x-mvpos-t 'y-mvpos-t 'z-mvpos-t '(.x rotation) '(.y rotation) 
        'x-mvpos-r2 'y-mvpos-r2 'z-mvpos-r2)

    ,@(first-person-rotate 'x-mnormals 'y-mnormals 'z-mnormals '(* 1 (.x rotation)) '(* 1 (.y rotation)) 
        'x-mnormals-r2 'y-mnormals-r2 'z-mnormals-r2)

    (= mproj-pos (point (/ x-mvpos-r2 z-mvpos-r2) (/ y-mvpos-r2 z-mvpos-r2)))

    (= point-in-triangle-1 (list 1 4 ... (- (length vertex-indices) 1)))
    (= point-in-triangle-2 (list 2 5 ... (- (length vertex-indices) 1)))
    (= point-in-triangle-3 (list 3 6 ... (- (length vertex-indices) 1)))
    (= mpoint-in-triangle-1 (list 1 4 ... (- (length mvertex-indices) 1)))
    (= mpoint-in-triangle-2 (list 2 5 ... (- (length mvertex-indices) 1)))
    (= mpoint-in-triangle-3 (list 3 6 ... (- (length mvertex-indices) 1)))


    (= proj-pos (point (/ x-vpos-r2 z-vpos-r2) (/ y-vpos-r2 z-vpos-r2)))
    ;(display
    (= polygons (polygon
        (get proj-pos (get vertex-indices point-in-triangle-1))
        (get proj-pos (get vertex-indices point-in-triangle-2))
        (get proj-pos (get vertex-indices point-in-triangle-3))
    ))
    (= mpolygons (polygon
        (get mproj-pos (get m-vertex-indices mpoint-in-triangle-1))
        (get mproj-pos (get m-vertex-indices mpoint-in-triangle-2))
        (get mproj-pos (get m-vertex-indices mpoint-in-triangle-3))
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

    (fn (elementwise-mult p1 p2) (point (* (.x p1) (.x p2)) (* (.y p1) (.y p2))))

    (fn (hypot x y z) (^ (+ (* x x) (* y y) (* z z)) 0.5))

    (= polygon-depths 
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





    (= mirror-polygon-depths 
        (/
            (+
                (hypot 
                    (get x-reflected-vpos mpoint-in-triangle-1)
                    (get y-reflected-vpos mpoint-in-triangle-1)
                    (get z-reflected-vpos mpoint-in-triangle-1)
                )
                (hypot 
                    (get x-reflected-vpos mpoint-in-triangle-2)
                    (get y-reflected-vpos mpoint-in-triangle-2)
                    (get z-reflected-vpos mpoint-in-triangle-2)
                )
                (hypot 
                    (get x-reflected-vpos mpoint-in-triangle-3)
                    (get y-reflected-vpos mpoint-in-triangle-3)
                    (get z-reflected-vpos mpoint-in-triangle-3)
                )
            )
        3)
    )




    (fn (reflect-offset x y z x-normal1 y-normal1 z-normal1 x-plane-pos y-plane-pos z-plane-pos)
        (+
            (* (- x x-plane-pos) x-normal1)
            (* (- y y-plane-pos) y-normal1)
            (* (- z z-plane-pos) z-normal1)
        ))

    (fn (reflect axis offset normal) (+ axis (* -2 offset normal)))

    (= brightnesses (min 0.1 (+ (* x-normals light-dir-x) (* y-normals light-dir-y) (* z-normals light-dir-z))))

    (= reflection-offsets (for
        (reflect-offset
            (get x-vpos-r2 (get vertex-indices (+ poly-index tri-index)))
            (get y-vpos-r2 (get vertex-indices (+ poly-index tri-index)))
            (get z-vpos-r2 (get vertex-indices (+ poly-index tri-index)))
            (get x-mnormals-r2 (/ (+ 2 mirror-index) 3))
            (get y-mnormals-r2 (/ (+ 2 mirror-index) 3))
            (get z-mnormals-r2 (/ (+ 2 mirror-index) 3))
            (get x-mvpos-r2 (get mvertex-indices mirror-index))
            (get y-mvpos-r2 (get mvertex-indices mirror-index))
            (get z-mvpos-r2 (get mvertex-indices mirror-index))
        )
        (tri-index (list 0 1 2))
        (poly-index point-in-triangle-1)
        (mirror-index mpoint-in-triangle-1)
    ))

    (= x-reflected-vpos (for
        (reflect
            (get x-vpos-r2 (get vertex-indices (+ poly-index2 tri-index2)))
            (get reflection-offsets 
                (+ 1 tri-index2 (- poly-index2 1) (* (- mirror-index2 1) (length point-in-triangle-1))))
            (get x-mnormals-r2 (/ (+ 2 mirror-index2) 3))
        )
        (tri-index2 (list 0 1 2))
        (poly-index2 point-in-triangle-1)
        (mirror-index2 mpoint-in-triangle-1)
    ))
    (= y-reflected-vpos (for
        (reflect
            (get y-vpos-r2 (get vertex-indices (+ poly-index2 tri-index2)))
            (get reflection-offsets 
                (+ 1 tri-index2 (- poly-index2 1) (* (- mirror-index2 1) (length point-in-triangle-1))))
            (get y-mnormals-r2 (/ (+ 2 mirror-index2) 3))
        )
        (tri-index2 (list 0 1 2))
        (poly-index2 point-in-triangle-1)
        (mirror-index2 mpoint-in-triangle-1)
    ))
    (= z-reflected-vpos (for
        (reflect
            (get z-vpos-r2 (get vertex-indices (+ poly-index2 tri-index2)))
            (get reflection-offsets 
                (+ 1 tri-index2 (- poly-index2 1) (* (- mirror-index2 1) (length point-in-triangle-1))))
            (get z-mnormals-r2 (/ (+ 2 mirror-index2) 3))
        )
        (tri-index2 (list 0 1 2))
        (poly-index2 point-in-triangle-1)
        (mirror-index2 mpoint-in-triangle-1)
    ))

    (= reflected-proj-pos (point
        (/ x-reflected-vpos z-reflected-vpos)
        (/ y-reflected-vpos z-reflected-vpos)
    ))

    (= point-in-reflected-triangle-1 (list 1 4 ... (- (length x-reflected-vpos) 1)))
    (= point-in-reflected-triangle-2 (list 2 5 ... (- (length x-reflected-vpos) 1)))
    (= point-in-reflected-triangle-3 (list 3 6 ... (- (length x-reflected-vpos) 1)))
    (= mirror-triangle-index (ceil (/ (list 1 ... (length x-reflected-vpos)) (length vertex-indices))))

    (= reflected-polygon-depths 
        (+ (get mirror-polygon-depths mirror-triangle-index) -0.01
            (/
                (+
                    (hypot 
                        (get x-reflected-vpos point-in-reflected-triangle-1)
                        (get y-reflected-vpos point-in-reflected-triangle-1)
                        (get z-reflected-vpos point-in-reflected-triangle-1)
                    )
                    (hypot 
                        (get x-reflected-vpos point-in-reflected-triangle-2)
                        (get y-reflected-vpos point-in-reflected-triangle-2)
                        (get z-reflected-vpos point-in-reflected-triangle-2)
                    )
                    (hypot 
                        (get x-reflected-vpos point-in-reflected-triangle-3)
                        (get y-reflected-vpos point-in-reflected-triangle-3)
                        (get z-reflected-vpos point-in-reflected-triangle-3)
                    )
                )
            3 1000000)
        )
    )

    (= reflected-polygons (for
                (polygon
                    (get-triangle-triangle-intersection-polygon
                        (get reflected-proj-pos reflected-polygon-combined-index)
                        (get reflected-proj-pos (+ 1 reflected-polygon-combined-index))
                        (get reflected-proj-pos (+ 2 reflected-polygon-combined-index))
                        (get mproj-pos (get m-vertex-indices mirror-index3))
                        (get mproj-pos (get m-vertex-indices (+ 1 mirror-index3)))
                        (get mproj-pos (get m-vertex-indices (+ 2 mirror-index3)))
                    )
                )
            (reflected-index (list 1 4 ... (- (length vertex-indices) 1)))
            (mirror-index3 (list 1 4 ... (- (length m-vertex-indices) 1)))
        )
    )

    (= all-polygons (join polygons reflected-polygons ))
    (= all-polygon-depths (join polygon-depths reflected-polygon-depths))
    (= all-polygon-colors (join colors reflect-colors))


    (= colors  
        
            (rgb 
            (* -1 (* 256 
                brightnesses
            )) 0 0)

        )

    (display
        (= drawn-polygons (sort all-polygons (* -1 all-polygon-depths)))
        (fill-opacity 1)
        (lines #f)
        (color-latex (sort all-polygon-colors (* -1 all-polygon-depths)))
    )

    (= reflected-polygon-combined-index (+ reflected-index (* (/ (- mirror-index3 1) 3) (length vertex-indices))))

    (= reflect-colors 
            (for
                (get colors i)
                (i (list 1 ... (length colors)))
                (j x-mnormals)
            ))

    (display mpolygons)


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

