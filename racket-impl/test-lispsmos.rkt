#lang racket

(require 
    "lispsmos-racket/lispsmos.rkt" 
    "lispsmos-racket/obj-parser.rkt" 
    "lispsmos-racket/lispsmos-3d.rkt")


; materials
(define cube-complex-mtl (open-input-file "assets/red_green_cube_complex_optimized.mtl"))
(define cube-complex-mtl-contents (read-string 99999999 cube-complex-mtl))
(define parsed-cube-complex-mtl (parse-mtl cube-complex-mtl-contents))

(define material-number->str-map 
    (get-key-number-mapping-reverse parsed-cube-complex-mtl))
(define material-str->number-map 
    (get-key-number-mapping parsed-cube-complex-mtl))



; complex cube mesh
(define cube-complex-obj (open-input-file "assets/red_green_cube_complex_optimized.obj"))
(define cube-complex-obj-contents (read-string 99999999 cube-complex-obj))
(define parsed-cube-complex-obj (parse-obj cube-complex-obj-contents))
(define face-normals-cube-complex (get-obj-face-normals parsed-cube-complex-obj))




; simple (for global illumination)
(define cube-simple-obj (open-input-file "assets/red_green_cube_simple.obj"))
(define cube-simple-obj-contents (read-string 99999999 cube-simple-obj))
(define parsed-cube-simple-obj (parse-obj cube-simple-obj-contents))
(define face-normals-cube-simple (get-obj-face-normals parsed-cube-simple-obj))





(define code (compile-lispsmos `(
    (= accum-sample accumulate-sample)
    (display min-rti-face-index)
    (display (= rotation-display (point 0 0)))
    (= rotation (* 6 rotation-display))
    (= x-pos 0)
    (= y-pos 0)
    (= z-pos 0)







    (folder ("simple mesh for global illumination" #t)
        (= simple-x-positions ,(get-obj-x-positions parsed-cube-simple-obj))
        (= simple-y-positions ,(get-obj-y-positions parsed-cube-simple-obj))
        (= simple-z-positions ,(get-obj-z-positions parsed-cube-simple-obj))

        (= simple-index-buffer ,(get-obj-vertex-indices parsed-cube-simple-obj))

        (= simple-x-normals ,(get-obj-x-face-normals face-normals-cube-simple))
        (= simple-y-normals ,(get-obj-y-face-normals face-normals-cube-simple))
        (= simple-z-normals ,(get-obj-z-face-normals face-normals-cube-simple))

        (= simple-polygon-material-indices ,(get-polygon-material-list
            (get-obj-materials cube-simple-obj-contents) material-str->number-map))
    )







    (folder ("complex mesh for display" #t)
    
        (= polygon-material-indices ,(get-polygon-material-list
            (get-obj-materials cube-complex-obj-contents) material-str->number-map))  
        (= filtered-polygon-material-indices (get polygon-material-indices
            polygon-filter))     


        (= x-positions ,(get-obj-x-positions parsed-cube-complex-obj))
        (= y-positions ,(get-obj-y-positions parsed-cube-complex-obj))
        (= z-positions (+ 0 ,(get-obj-z-positions parsed-cube-complex-obj)))
        (= x-normals ,(get-obj-x-face-normals face-normals-cube-complex))
        (= y-normals ,(get-obj-y-face-normals face-normals-cube-complex))
        (= z-normals (+ 0 ,(get-obj-z-face-normals face-normals-cube-complex)))
    )







    (folder ("internal stuff" #t)
        (fn (length3 x y z) (^ (+ (* x x) (* y y) (* z z)) 0.5))
        (= ambient-colors ,(get-material-ambient-colors 
            material-number->str-map parsed-cube-complex-mtl))
        (= diffuse-colors ,(get-material-diffuse-colors 
            material-number->str-map parsed-cube-complex-mtl))
        (= specular-colors ,(get-material-specular-colors 
            material-number->str-map parsed-cube-complex-mtl)) 
        (= emission-colors ,(get-material-emission-colors 
            material-number->str-map parsed-cube-complex-mtl)) 

        (= x-positions-t (- x-positions x-pos))
        (= y-positions-t (- y-positions y-pos))
        (= z-positions-t (- z-positions z-pos))

        (= rotation-x (.x rotation))

        (= x-positions-r1 (+
            (* (cos (.x rotation)) x-positions-t)
            (* -1 (sin (.x rotation)) z-positions-t)
        ))

        (= z-positions-r1 (+
            (* (sin (.x rotation)) x-positions-t)
            (* (cos (.x rotation)) z-positions-t)
        ))

        (= y-positions-r2 (+
            (* (cos (.y rotation)) y-positions-t)
            (* -1 (sin (.y rotation)) z-positions-r1)
        ))

        (= z-positions-r2 (+
            (* (sin (.y rotation)) y-positions-t)
            (* (cos (.y rotation)) z-positions-r1)
        ))

        (= index-buffer ,(get-obj-vertex-indices parsed-cube-complex-obj))

        (= screen-space-points (point 
            (/ x-positions-r1 z-positions-r2) (/ y-positions-r2 z-positions-r2)))
                


                   
        (= polygon-centers-x-original (for
            (mean
                (get x-positions (get index-buffer (+ i2 -2)))
                (get x-positions (get index-buffer (+ i2 -1)))
                (get x-positions (get index-buffer (+ i2 0)))
            )
        (i2 (* 3 (list 1 ... (/ (length index-buffer) 3))))))
        (= polygon-centers-y-original (for
            (mean
                (get y-positions (get index-buffer (+ i2 -2)))
                (get y-positions (get index-buffer (+ i2 -1)))
                (get y-positions (get index-buffer (+ i2 0)))
            )
        (i2 (* 3 (list 1 ... (/ (length index-buffer) 3))))))
        (= polygon-centers-z-original (for
            (mean
                (get z-positions (get index-buffer (+ i2 -2)))
                (get z-positions (get index-buffer (+ i2 -1)))
                (get z-positions (get index-buffer (+ i2 0)))
            )
        (i2 (* 3 (list 1 ... (/ (length index-buffer) 3))))))




        (= polygon-centers-x (for
            (mean
                (get x-positions-r1 (get index-buffer (+ i2 1)))
                (get x-positions-r1 (get index-buffer (+ i2 2)))
                (get x-positions-r1 (get index-buffer (+ i2 3)))
            )
        (i2 (* 3 (list 0 ... (/ (length index-buffer) 3))))))
        (= polygon-centers-y (for
            (mean
                (get y-positions-r2 (get index-buffer (+ i2 1)))
                (get y-positions-r2 (get index-buffer (+ i2 2)))
                (get y-positions-r2 (get index-buffer (+ i2 3)))
            )
        (i2 (* 3 (list 0 ... (/ (length index-buffer) 3))))))
        (= polygon-centers-z (for
            (mean
                (get z-positions-r2 (get index-buffer (+ i2 1)))
                (get z-positions-r2 (get index-buffer (+ i2 2)))
                (get z-positions-r2 (get index-buffer (+ i2 3)))
            )
        (i2 (* 3 (list 0 ... (/ (length index-buffer) 3))))))

        (= polygon-depths (length3 polygon-centers-x polygon-centers-y polygon-centers-z))

        (= polygon-ordering (sort (list 1 ... (length polygon-depths)) (* -1 polygon-depths)))

        (= polygon-winding-orders (for 
        (piecewise
            ((< (min 
                (get z-positions-r2 (get index-buffer (- i3 2)))
                (get z-positions-r2 (get index-buffer (- i3 1)))
                (get z-positions-r2 (get index-buffer (- i3 0)))
            ) 0.4) 1
            )
            ((> 2 1) (+
                (*
                    (-
                        (.x (get screen-space-points (get index-buffer (- i3 2))))
                        (.x (get screen-space-points (get index-buffer (- i3 1))))
                    )
                    (+
                        (.y (get screen-space-points (get index-buffer (- i3 2))))
                        (.y (get screen-space-points (get index-buffer (- i3 1))))
                    )
                )
                (*
                    (-
                        (.x (get screen-space-points (get index-buffer (- i3 1))))
                        (.x (get screen-space-points (get index-buffer (- i3 0))))
                    )
                    (+
                        (.y (get screen-space-points (get index-buffer (- i3 1))))
                        (.y (get screen-space-points (get index-buffer (- i3 0))))
                    )
                )
                (*
                    (-
                        (.x (get screen-space-points (get index-buffer (- i3 0))))
                        (.x (get screen-space-points (get index-buffer (- i3 2))))
                    )
                    (+
                        (.y (get screen-space-points (get index-buffer (- i3 0))))
                        (.y (get screen-space-points (get index-buffer (- i3 2))))
                    )
                )
            ))
        )
         (i3 (* 3 polygon-ordering))))
        
        (= polygon-filter (get polygon-ordering (<= polygon-winding-orders 0)))






        (= lambert-shading (max 0 (+
                (* (get x-normals polygon-filter) 0.577350269)
                (* (get y-normals polygon-filter) 0.577350269)
                (* (get z-normals polygon-filter) -0.577350269)
            )))

        (= polygon-centers-norotate-x (for
            (mean
                (get x-positions-t (get index-buffer (+ i2 1)))
                (get x-positions-t (get index-buffer (+ i2 2)))
                (get x-positions-t (get index-buffer (+ i2 3)))
            )
        (i2 (* 3 (list 0 ... (/ (length index-buffer) 3))))))
        (= polygon-centers-norotate-y (for
            (mean
                (get y-positions-t (get index-buffer (+ i2 1)))
                (get y-positions-t (get index-buffer (+ i2 2)))
                (get y-positions-t (get index-buffer (+ i2 3)))
            )
        (i2 (* 3 (list 0 ... (/ (length index-buffer) 3))))))
        (= polygon-centers-norotate-z (for
            (mean
                (get z-positions-t (get index-buffer (+ i2 1)))
                (get z-positions-t (get index-buffer (+ i2 2)))
                (get z-positions-t (get index-buffer (+ i2 3)))
            )
        (i2 (* 3 (list 0 ... (/ (length index-buffer) 3))))))

        (= viewer-offset-length (length3
            (get polygon-centers-norotate-x polygon-filter)
            (get polygon-centers-norotate-y polygon-filter)
            (get polygon-centers-norotate-z polygon-filter)))

        ; (= reflection-vectors-x 
        ;     (- (* 2 lambert-shading (get x-normals polygon-filter)) 0.577350269))
        ; (= reflection-vectors-y 
        ;     (- (* 2 lambert-shading (get y-normals polygon-filter)) 0.577350269))
        ; (= reflection-vectors-z 
        ;     (- (* 2 lambert-shading (get z-normals polygon-filter)) -0.577350269))

        (= specular-factors (+
            (* (get x-normals polygon-filter)
               0.577350269)
            (* (get y-normals polygon-filter)
               0.577350269)
            (* (get z-normals polygon-filter)
               -0.577350269)
        ))

        (= specular-shading (piecewise
            ((< specular-factors 0) 0)
            ((>= specular-factors 0) (^ (min (+
                (* reflection-vectors-x
                    (/ (get polygon-centers-norotate-x polygon-filter) viewer-offset-length))
                (* reflection-vectors-y 
                    (/ (get polygon-centers-norotate-y polygon-filter) viewer-offset-length))
                (* reflection-vectors-z
                    (/ (get polygon-centers-norotate-z polygon-filter) viewer-offset-length))
            ) 0) 6))
        ))




        (= screen-space-polygon-centers
            (for
                (point
                    (mean
                        (.x (get screen-space-points (get index-buffer (- i4 2))))
                        (.x (get screen-space-points (get index-buffer (- i4 1))))
                        (.x (get screen-space-points (get index-buffer (- i4 0))))
                    )
                    (mean
                        (.y (get screen-space-points (get index-buffer (- i4 2))))
                        (.y (get screen-space-points (get index-buffer (- i4 1))))
                        (.y (get screen-space-points (get index-buffer (- i4 0))))
                    )
                )
            (i4 (* 3 (list 1 ... (/ (length index-buffer) 3)))))
        )

        (display (for (polygon 
            (+ (* (- 
                (get screen-space-points (get index-buffer (+ i -2)))
                (get screen-space-polygon-centers (/ i 3))
            ) 1.1) (get screen-space-polygon-centers (/ i 3)))
            (+ (* (- 
                (get screen-space-points (get index-buffer (+ i -1)))
                (get screen-space-polygon-centers (/ i 3))
            ) 1.1) (get screen-space-polygon-centers (/ i 3)))
            (+ (* (- 
                (get screen-space-points (get index-buffer (+ i -0)))
                (get screen-space-polygon-centers (/ i 3))
            ) 1.1) (get screen-space-polygon-centers (/ i 3)))
        ) (i (* 3 polygon-filter)))


            ; (color-latex (rgb
            ;     (* 256 (+
            ;         (* 
            ;            (max 0.3 lambert-shading)
            ;         (get diffuse-colors (- (* 3 filtered-polygon-material-indices) 2))
            ;         )
            ;         (*
            ;             specular-shading
            ;             (get specular-colors (- (* 3 filtered-polygon-material-indices) 2))
            ;         )
            ;         (get emission-colors (- (* 3 filtered-polygon-material-indices) 2))
            ;     ))
            ;     (* 256 (+
            ;         (* 
            ;            (max 0.3 lambert-shading)
            ;         (get diffuse-colors (- (* 3 filtered-polygon-material-indices) 1))
            ;         )
            ;         (*
            ;             specular-shading
            ;             (get specular-colors (- (* 3 filtered-polygon-material-indices) 1))
            ;         )
            ;         (get emission-colors (- (* 3 filtered-polygon-material-indices) 1))
            ;     ))
            ;     (* 256 (+
            ;         (* 
            ;             (max 0.3 lambert-shading)
            ;         (get diffuse-colors (- (* 3 filtered-polygon-material-indices) 0))
            ;         )
            ;         (*
            ;             specular-shading
            ;             (get specular-colors (- (* 3 filtered-polygon-material-indices) 0))
            ;         )
            ;         (get emission-colors (- (* 3 filtered-polygon-material-indices) 0))
            ;     ))
            ; ))

            (color-latex (get ray-traced-colors polygon-filter))


            (lines #f)
            (fill-opacity 1.0)
        )

        (= hemispherical-samples-x (rand-norm (length polygon-centers-x-original) 
            (+ 1 (* 6 sample-count))))
        (= hemispherical-samples-y (rand-norm (length polygon-centers-y-original) 
            (+ 2 (* 6 sample-count))))
        (= hemispherical-samples-z (rand-norm (length polygon-centers-z-original) 
            (+ 3 (* 6 sample-count))))
        (= hemispherical-sample-multipliers (hemispherical-sample-multiplier
            hemispherical-samples-x
            hemispherical-samples-y
            hemispherical-samples-z
            x-normals
            y-normals
            z-normals
            1
        ))


        (= perfect-reflection-vectors-dot ,(lispsmos-static-dot
            'x-normals 'y-normals 'z-normals
            'polygon-centers-norotate-x 'polygon-centers-norotate-y 'polygon-centers-norotate-z
        ))
        (= perfect-reflection-vectors-x (- polygon-centers-norotate-x
            (* 2 perfect-reflection-vectors-dot x-normals)
        ))
        (= perfect-reflection-vectors-y (- polygon-centers-norotate-y
            (* 2 perfect-reflection-vectors-dot y-normals)
        ))
        (= perfect-reflection-vectors-z (- polygon-centers-norotate-z
            (* 2 perfect-reflection-vectors-dot z-normals)
        ))
        (fn (lerp a b fac) (+ a (* fac (- b a))))
        (= reflection-vectors-x (lerp perfect-reflection-vectors-x 
            (/ hemispherical-samples-x hemispherical-sample-multipliers) 0.2))
        (= reflection-vectors-y (lerp perfect-reflection-vectors-y 
            (/ hemispherical-samples-y hemispherical-sample-multipliers) 0.2))
        (= reflection-vectors-z (lerp perfect-reflection-vectors-z
            (/ hemispherical-samples-z hemispherical-sample-multipliers) 0.2))
        (= reflection-vectors-magnitude (length3
            reflection-vectors-x
            reflection-vectors-y
            reflection-vectors-z
        ))


        (= ray-triangle-intersections-for-ray-tracing
            ;(for 
                (get-ray-triangle-intersection-list
                    (get polygon-centers-x-original i6)
                    (get polygon-centers-y-original i6)
                    (get polygon-centers-z-original i6)
                    (/ (get reflection-vectors-x i6) (get reflection-vectors-magnitude i6))
                    (/ (get reflection-vectors-y i6) (get reflection-vectors-magnitude i6))
                    (/ (get reflection-vectors-z i6) (get reflection-vectors-magnitude i6))
                )
            ;(i6 (list 1 ... (length polygon-centers-x-original)))
            ;)
        )

        ; (= ray-traced-material-indices (for 
            ; (get simple-polygon-material-indices (get-first-ray-triangle-intersection-face-index
            ;     (get polygon-centers-x-original i6)
            ;     (get polygon-centers-y-original i6)
            ;     (get polygon-centers-z-original i6)
            ;     (/ (get hemispherical-samples-x i6) (get hemispherical-sample-multipliers i6))
            ;     (/ (get hemispherical-samples-y i6) (get hemispherical-sample-multipliers i6))
            ;     (/ (get hemispherical-samples-z i6) (get hemispherical-sample-multipliers i6))
            ; ))
       ; (i6 (list 1 ... (length polygon-centers-x-original)))))

        (= ray-tracing-results (for 
            (+
                (* (get-face-index-from-first-rti
                   ray-triangle-intersections-for-ray-tracing
                ) 1024)
                (get-first-ray-triangle-intersection
                    ray-triangle-intersections-for-ray-tracing)
            )
        (i6 (list 1 ... (length polygon-centers-x-original)))))


        (fn (get-ray-tracing-material-index x)
            (get simple-polygon-material-indices (floor (/ x 1024))))

        (fn (get-ray-tracing-collision-index x)
            (floor (/ x 1024)))

        (fn (get-ray-tracing-path-length x)
            (mod x 1024))

        (= ray-traced-colors ;(for 
            (rgb 
                (/ accum-ray-traced-r sample-count)
                (/ accum-ray-traced-g sample-count)
                (/ accum-ray-traced-b sample-count)
            ))
        ;(i7 (list 1 ... (length polygon-centers-x-original)))))

        (= ray-traced-r (for (* 256 
            (+
                ; light first bounce
                (get emission-colors (- (* (get polygon-material-indices i7) 3) 2))

                ; light second bounce
                (* 
                    (get diffuse-colors (- (* (get polygon-material-indices i7) 3) 2))
                    (get emission-colors (- (* 
                        (get (get-ray-tracing-material-index ray-tracing-results) i7) 3) 2))
                )

                ; light third bounce
                (*
                    (get diffuse-colors (- (* (get polygon-material-indices i7) 3) 2))
                    (get diffuse-colors (- (* 
                        (get (get-ray-tracing-material-index ray-tracing-results) i7) 3) 2))
                    (get emission-colors (- (* (get 
                        (get-ray-tracing-material-index ray-tracing-results-bounce2) i7) 3) 2))
                )
            ))
                (i7 (list 1 ... (length polygon-centers-x-original)))))

        (= ray-traced-g (for (* 256 
            (+
                ; light first bounce
                (get emission-colors (- (* (get polygon-material-indices i7) 3) 1))

                ; light second bounce
                (* 
                    (get diffuse-colors (- (* (get polygon-material-indices i7) 3) 1))
                    (get emission-colors (- (* 
                        (get (get-ray-tracing-material-index ray-tracing-results) i7) 3) 1))
                )

                ; light third bounce
                (*
                    (get diffuse-colors (- (* (get polygon-material-indices i7) 3) 1))
                    (get diffuse-colors (- (* 
                        (get (get-ray-tracing-material-index ray-tracing-results) i7) 3) 1))
                    (get emission-colors (- (* (get 
                        (get-ray-tracing-material-index ray-tracing-results-bounce2) i7) 3) 1))
                )
            ))
                (i7 (list 1 ... (length polygon-centers-x-original)))))

        (= ray-traced-b (for (* 256 
            (+
                ; light first bounce
                (get emission-colors (- (* (get polygon-material-indices i7) 3) 0))

                ; light second bounce
                (* 
                    (get diffuse-colors (- (* (get polygon-material-indices i7) 3) 0))
                    (get emission-colors (- (* 
                        (get (get-ray-tracing-material-index ray-tracing-results) i7) 3) 0))
                )

                ; light third bounce
                (*
                    (get diffuse-colors (- (* (get polygon-material-indices i7) 3) 0))
                    (get diffuse-colors (- (* 
                        (get (get-ray-tracing-material-index ray-tracing-results) i7) 3) 0))
                    (get emission-colors (- (* (get 
                        (get-ray-tracing-material-index ray-tracing-results-bounce2) i7) 3) 0))
                )
            ))
                (i7 (list 1 ... (length polygon-centers-x-original)))))


        ; (= ray-traced-g (for (* 256 (get diffuse-colors (- (* (get 
        ;             (get-ray-tracing-material-index ray-tracing-results) i7) 3) 1))
        ;         (get emission-colors (- (* (get 
        ;             (get-ray-tracing-material-index ray-tracing-results-bounce2) i7) 3) 1)))
        ;         (i7 (list 1 ... (length polygon-centers-x-original)))))


        ; (= ray-traced-b (for (* 256 (get diffuse-colors (- (* (get 
        ;             (get-ray-tracing-material-index ray-tracing-results) i7) 3) 0))
        ;         (get emission-colors (- (* (get 
        ;             (get-ray-tracing-material-index ray-tracing-results-bounce2) i7) 3) 0)))
        ;         (i7 (list 1 ... (length polygon-centers-x-original)))))

        (= accum-ray-traced-r (* 0 (list 1 ... (length polygon-centers-x-original))))
        (= accum-ray-traced-g (* 0 (list 1 ... (length polygon-centers-x-original))))
        (= accum-ray-traced-b (* 0 (list 1 ... (length polygon-centers-x-original))))
        (= sample-count 0) 

        (= accumulate-sample (group
            (-> accum-ray-traced-r (+ accum-ray-traced-r ray-traced-r))
            (-> accum-ray-traced-g (+ accum-ray-traced-g ray-traced-g))
            (-> accum-ray-traced-b (+ accum-ray-traced-b ray-traced-b))
            (-> sample-count (+ sample-count 1))
        ))



        (= ray-end-positions-x-bounce1
                        (+
                    (get polygon-centers-x-original i8)
                    (* (- (get-ray-tracing-path-length (get ray-tracing-results i8)) 0.01)
                    ;(/ (get hemispherical-samples-x i8) (get hemispherical-sample-multipliers i8)))
                    (/ (get reflection-vectors-x i8) (get reflection-vectors-magnitude i8)))
                )
            )
        (= ray-end-positions-y-bounce1
                    (+  
                (get polygon-centers-y-original i8)
                (* (- (get-ray-tracing-path-length (get ray-tracing-results i8)) 0.01)
                ;(/ (get hemispherical-samples-y i8) (get hemispherical-sample-multipliers i8)))
                    (/ (get reflection-vectors-y i8) (get reflection-vectors-magnitude i8)))
            )
        )
        (= ray-end-positions-z-bounce1
                    (+
                (get polygon-centers-z-original i8)
                (* (- (get-ray-tracing-path-length (get ray-tracing-results i8)) 0.01)
                ;(/ (get hemispherical-samples-z i8) (get hemispherical-sample-multipliers i8)))
                    (/ (get reflection-vectors-z i8) (get reflection-vectors-magnitude i8)))
            )
        )
        (= ray-end-normals-x-bounce1
            (get simple-x-normals (get-ray-tracing-collision-index ray-tracing-results)))
        (= ray-end-normals-y-bounce1
            (get simple-y-normals (get-ray-tracing-collision-index ray-tracing-results)))
        (= ray-end-normals-z-bounce1
            (get simple-z-normals (get-ray-tracing-collision-index ray-tracing-results)))
        (= ray-triangle-intersections-for-ray-tracing-bounce2
                (get-ray-triangle-intersection-list
                    ray-end-positions-x-bounce1
                    ray-end-positions-y-bounce1
                    ray-end-positions-z-bounce1
                    (/ (get hemispherical-samples-x-bounce2 i8) (get hemispherical-sample-multipliers i8))
                    (/ (get hemispherical-samples-y-bounce2 i8) (get hemispherical-sample-multipliers i8))
                    (/ (get hemispherical-samples-z-bounce2 i8) (get hemispherical-sample-multipliers i8))
                )
        )
        (= hemispherical-samples-x-bounce2 (rand-norm (length polygon-centers-x-original) 
            (+ 4 (* 6 sample-count))))
        (= hemispherical-samples-y-bounce2 (rand-norm (length polygon-centers-y-original) 
            (+ 5 (* 6 sample-count))))
        (= hemispherical-samples-z-bounce2 (rand-norm (length polygon-centers-z-original) 
            (+ 6 (* 6 sample-count))))




        (= perfect-reflection-vectors-dot-bounce2 ,(lispsmos-static-dot
            'ray-end-normals-x-bounce1
            'ray-end-normals-y-bounce1
            'ray-end-normals-z-bounce1
            '(- ray-end-positions-x-bounce1 x-pos)
            '(- ray-end-positions-y-bounce1 y-pos)
            '(- ray-end-positions-z-bounce1 z-pos)
        ))
        (= perfect-reflection-vectors-x-bounce2 (- (- ray-end-positions-x-bounce1 x-pos)
            (* 2 perfect-reflection-vectors-dot ray-end-normals-x-bounce1)
        ))
        (= perfect-reflection-vectors-y-bounce2 (- (- ray-end-positions-y-bounce1 y-pos)
            (* 2 perfect-reflection-vectors-dot ray-end-normals-y-bounce1)
        ))
        (= perfect-reflection-vectors-z-bounce2 (- (- ray-end-positions-z-bounce1 z-pos)
            (* 2 perfect-reflection-vectors-dot ray-end-normals-z-bounce1)
        ))
        (= reflection-vectors-x-bounce2 (lerp perfect-reflection-vectors-x-bounce2
            (/ hemispherical-samples-x-bounce2 hemispherical-sample-multipliers-bounce2) 0.2))
        (= reflection-vectors-y-bounce2 (lerp perfect-reflection-vectors-y-bounce2 
            (/ hemispherical-samples-y-bounce2 hemispherical-sample-multipliers-bounce2) 0.2))
        (= reflection-vectors-z-bounce2 (lerp perfect-reflection-vectors-z-bounce2
            (/ hemispherical-samples-z-bounce2 hemispherical-sample-multipliers-bounce2) 0.2))
        (= reflection-vectors-magnitude-bounce2 (length3
            reflection-vectors-x-bounce2
            reflection-vectors-y-bounce2
            reflection-vectors-z-bounce2
        ))


        (= hemispherical-sample-multipliers-bounce2 (hemispherical-sample-multiplier
            hemispherical-samples-x-bounce2
            hemispherical-samples-y-bounce2
            hemispherical-samples-z-bounce2
            ray-end-normals-x-bounce1
            ray-end-normals-y-bounce1
            ray-end-normals-z-bounce1
            1
        ))

        (= ray-tracing-results-bounce2 (for 
            (+
                (* (get-face-index-from-first-rti
                   ray-triangle-intersections-for-ray-tracing-bounce2 
                ) 1024)
                (get-first-ray-triangle-intersection
                    ray-triangle-intersections-for-ray-tracing-bounce2)
            )
        (i8 (list 1 ... (length polygon-centers-x-original)))))





        (folder ("ray triangle intersection" #t)    
            ,@muller-trumbore-ray-triangle-intersection-formula
        )






        (folder ("ray tracing stuff" #t)

            (= ray-triangle-intersections (for
                (muller-trumbore
                    rti-start-x rti-start-y rti-start-z
                    rti-dir-x rti-dir-y rti-dir-z
                    (get simple-x-positions (get simple-index-buffer (- i4 2)))
                    (get simple-y-positions (get simple-index-buffer (- i4 2)))
                    (get simple-z-positions (get simple-index-buffer (- i4 2)))
                    (get simple-x-positions (get simple-index-buffer (- i4 1)))
                    (get simple-y-positions (get simple-index-buffer (- i4 1)))
                    (get simple-z-positions (get simple-index-buffer (- i4 1)))
                    (get simple-x-positions (get simple-index-buffer (- i4 0)))
                    (get simple-y-positions (get simple-index-buffer (- i4 0)))
                    (get simple-z-positions (get simple-index-buffer (- i4 0)))
                )
            (i4 (* 3 (list 1 ... (/ (length simple-index-buffer) 3))))))
            (= min-rti (min (get ray-triangle-intersections (> ray-triangle-intersections 0))))
            (= min-rti-face-index (get (get (list 1 ... (length ray-triangle-intersections)) 
                (= ray-triangle-intersections min-rti)) 1))
            (fn (get-first-ray-triangle-intersection-face-index
                rti-start-x rti-start-y rti-start-z
                rti-dir-x rti-dir-y rti-dir-z)
                min-rti-face-index
            )
            (fn (get-ray-triangle-intersection-list
                rti-start-x rti-start-y rti-start-z
                rti-dir-x rti-dir-y rti-dir-z)
                ray-triangle-intersections
            )
            (fn (get-first-ray-triangle-intersection
                ray-triangle-intersection-list)
                (min (get ray-triangle-intersection-list (> ray-triangle-intersection-list 0)))
            )

            (fn (get-face-index-from-first-rti ray-triangle-intersection-list) 
                (get (get (list 1 ... (length ray-triangle-intersection-list)) 
                (= ray-triangle-intersection-list 
                (min (get ray-triangle-intersection-list (> ray-triangle-intersection-list 0))))) 1)
            )

            (fn (rand-norm count seed) (latex "\\operatorname{normaldist}\\left(\\right).
                \\operatorname{random}\\left(c_{ount},s_{eed}\\right)"))

            (fn (hemispherical-sample-multiplier x y z nx ny nz seed)
                (*  
                    (sign ,(lispsmos-static-dot 
                    'nx 'ny 'nz 
                    'x
                    'y
                    'z)) (/ 1 (length3
                        x
                        y
                        z
                    )))
            )
        )
    )
)))

(define out (open-output-file "out.json" #:mode 'binary #:exists 'replace))


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