#lang racket

(require 
    "../lispsmos-racket/lispsmos.rkt" 
    "../lispsmos-racket/obj-parser.rkt" 
    "../lispsmos-racket/lispsmos-3d.rkt"
    pict
    racket/draw)


; materials
(define cube-complex-mtl (open-input-file "assets/diamonds.mtl"))
(define cube-complex-mtl-contents (read-string 99999999 cube-complex-mtl))




; simple (for global illumination)
(define cube-simple-obj (open-input-file "assets/diamonds.obj"))
(define cube-simple-obj-contents (read-string 99999999 cube-simple-obj))


(define 3d-col (get-3d-collection (hash
    ;"complex" cube-complex-obj-contents
    "simple" cube-simple-obj-contents) (list cube-complex-mtl-contents)))
(display 3d-col)


(define minecraft-diffuse (read-bitmap "./diffuse-map.png" 'png))
(define diffuse-pixels-dst (make-bytes (* 4 96 48)))
(send minecraft-diffuse get-width)
(send minecraft-diffuse get-height)
(send minecraft-diffuse get-argb-pixels 0 0 96 48 diffuse-pixels-dst)

(define minecraft-emission (read-bitmap "./emissive-map.png" 'png))
(define emission-pixels-dst (make-bytes (* 4 96 48)))
(send minecraft-emission get-argb-pixels 0 0 96 48 emission-pixels-dst)

(define minecraft-specular (read-bitmap "./specular-map.png" 'png))
(define specular-pixels-dst (make-bytes (* 4 96 48)))
(send minecraft-specular get-argb-pixels 0 0 96 48 specular-pixels-dst)

(define minecraft-specular-roughness (read-bitmap "./specular-roughness-map.png" 'png))
(define specular-roughness-pixels-dst (make-bytes (* 4 96 48)))
(send minecraft-specular-roughness get-argb-pixels 0 0 96 48 specular-roughness-pixels-dst)

(define (symbol-append . args)
    (string->symbol (apply string-append (map symbol->string args))))

(define (number->symbol x)
    (string->symbol (number->string x)))

(define (create-light-bounce-code past-prefix current-prefix seed-offset)
    (define prefixed-raytracing-results (symbol-append current-prefix 'ray-tracing-results))
    (define prefixed-raytracing-result (symbol-append current-prefix 'ray-tracing-result))
    (define prefixed-minimum-index (symbol-append current-prefix 'minimum-index))
    (define prefixed-triangle-index (symbol-append current-prefix 'triangle-index))
    (define prefixed-barycentric-coord-1 (symbol-append current-prefix 'barycentric-coord-1))
    (define prefixed-barycentric-coord-2 (symbol-append current-prefix 'barycentric-coord-2))
    (define prefixed-pixel-texcoords (symbol-append current-prefix 'pixel-texcoords))
    (define prefixed-texture-pixel-space-texcoords (symbol-append current-prefix 'texture-pixel-space-texcoords))
    (define prefixed-ray-path-length (symbol-append current-prefix 'ray-path-length))
    (define prefixed-x-normals (symbol-append current-prefix 'x-normals))
    (define prefixed-y-normals (symbol-append current-prefix 'y-normals))
    (define prefixed-z-normals (symbol-append current-prefix 'z-normals))
    (define prefixed-dot-incident-normal (symbol-append current-prefix 'dot-incident-normal))

    (define prefixed-i3 (symbol-append current-prefix 'i3))
    (define prefixed-x-rand-norm (symbol-append current-prefix 'x-rand-norm))
    (define prefixed-y-rand-norm (symbol-append current-prefix 'y-rand-norm))
    (define prefixed-z-rand-norm (symbol-append current-prefix 'z-rand-norm))
    (define prefixed-x-hemisphere (symbol-append current-prefix 'x-hemisphere))
    (define prefixed-y-hemisphere (symbol-append current-prefix 'y-hemisphere))
    (define prefixed-z-hemisphere (symbol-append current-prefix 'z-hemisphere))
    (define prefixed-hemisphere-mag (symbol-append current-prefix 'hemisphere-mag))

    (define prefixed-specular-roughness (symbol-append current-prefix 'specular-roughness))

    (define prefixed-x-specular (symbol-append current-prefix 'x-specular))
    (define prefixed-y-specular (symbol-append current-prefix 'y-specular))
    (define prefixed-z-specular (symbol-append current-prefix 'z-specular))
    (define prefixed-specular-mag (symbol-append current-prefix 'specular-mag))

    (define prefixed-x-directions (symbol-append current-prefix 'x-directions))
    (define prefixed-y-directions (symbol-append current-prefix 'y-directions))
    (define prefixed-z-directions (symbol-append current-prefix 'z-directions))

    (define prefixed-diffuse-r (symbol-append current-prefix 'diffuse-r))
    (define prefixed-diffuse-g (symbol-append current-prefix 'diffuse-g))
    (define prefixed-diffuse-b (symbol-append current-prefix 'diffuse-b))
    (define prefixed-specular-r (symbol-append current-prefix 'specular-r))
    (define prefixed-specular-g (symbol-append current-prefix 'specular-g))
    (define prefixed-specular-b (symbol-append current-prefix 'specular-b))

    (define prefixed-brightness-factor (symbol-append current-prefix 'brightness-factor))

    (define prefixed-reflection-type-randoms (symbol-append current-prefix '-reflection-type-randoms))

    (define past-x-pos (symbol-append past-prefix 'x-pos))
    (define past-y-pos (symbol-append past-prefix 'y-pos))
    (define past-z-pos (symbol-append past-prefix 'z-pos))
    (define past-x-directions (symbol-append past-prefix 'x-directions))
    (define past-y-directions (symbol-append past-prefix 'y-directions))
    (define past-z-directions (symbol-append past-prefix 'z-directions))
    (define past-r-albedo (symbol-append past-prefix 'r-albedo))
    (define past-g-albedo (symbol-append past-prefix 'g-albedo))
    (define past-b-albedo (symbol-append past-prefix 'b-albedo))
    `(
        (= ,prefixed-raytracing-results
            (muller-trumbore-full-data
                (get ,past-x-pos ,prefixed-i3)
                (get ,past-y-pos ,prefixed-i3)
                (get ,past-z-pos ,prefixed-i3)
                (get ,past-x-directions ,prefixed-i3)
                (get ,past-y-directions ,prefixed-i3)
                (get ,past-z-directions ,prefixed-i3)
                indexed-x-vpos-tri1 indexed-y-vpos-tri1 indexed-z-vpos-tri1 
                indexed-x-vpos-tri2 indexed-y-vpos-tri2 indexed-z-vpos-tri2 
                indexed-x-vpos-tri3 indexed-y-vpos-tri3 indexed-z-vpos-tri3 
            ))

        (= ,prefixed-minimum-index
            (get (get 
                (list 1 ... (length ,prefixed-raytracing-results)) 
                (== (.x ,prefixed-raytracing-results) 
                    (min (get (.x ,prefixed-raytracing-results) (> (.x ,prefixed-raytracing-results) 0))))) 1))

        (= ,prefixed-raytracing-result (for
            (+ (get ,prefixed-raytracing-results ,prefixed-minimum-index) (point (* 1024 ,prefixed-minimum-index) 0))
        (,prefixed-i3 (list 1 ... LIST-LENGTH))))

        (= ,prefixed-triangle-index (floor (/ (.x ,prefixed-raytracing-result) 1024)))
        (= ,prefixed-barycentric-coord-1 (/ (mod (.y ,prefixed-raytracing-result) 67108864) 67108864))
        (= ,prefixed-barycentric-coord-2 (/ (floor (/ (.y ,prefixed-raytracing-result) 67108864)) 67108864))

        (= ,prefixed-pixel-texcoords (+
            (* ,prefixed-barycentric-coord-1 (get texcoords (+ (* ,prefixed-triangle-index 3) -1)))
            (* ,prefixed-barycentric-coord-2 (get texcoords (+ (* ,prefixed-triangle-index 3) -0)))
            (* (- 1 ,prefixed-barycentric-coord-1 ,prefixed-barycentric-coord-2) 
                (get texcoords (+ (* ,prefixed-triangle-index 3) -2)))
        ))

        (= ,prefixed-texture-pixel-space-texcoords (+ 1 
            (floor (* (.x ,prefixed-pixel-texcoords) 96)) 
            (* 96 (- 47 (floor (* (.y ,prefixed-pixel-texcoords) 48))))))

        (= ,prefixed-diffuse-r (get mc-diffuse-tex-r ,prefixed-texture-pixel-space-texcoords))
        (= ,prefixed-diffuse-g (get mc-diffuse-tex-g ,prefixed-texture-pixel-space-texcoords))
        (= ,prefixed-diffuse-b (get mc-diffuse-tex-b ,prefixed-texture-pixel-space-texcoords))
        (= ,prefixed-specular-r (get mc-specular-tex-r ,prefixed-texture-pixel-space-texcoords))
        (= ,prefixed-specular-g (get mc-specular-tex-g ,prefixed-texture-pixel-space-texcoords))
        (= ,prefixed-specular-b (get mc-specular-tex-b ,prefixed-texture-pixel-space-texcoords))
        (= ,prefixed-specular-roughness (get mc-specular-roughness ,prefixed-texture-pixel-space-texcoords))

        (= ,prefixed-brightness-factor (+
            (/ 1
            (+ (/ 
                (+ ,prefixed-specular-r ,prefixed-specular-g ,prefixed-specular-b)
                (+ ,prefixed-diffuse-r ,prefixed-diffuse-g ,prefixed-diffuse-b 0.0000001)
            ) 1))
        ))

        (= ,prefixed-reflection-type-randoms (random LIST-LENGTH (+ raytracer-reseeder ,seed-offset)))

        (= ,(symbol-append current-prefix 'r-albedo) 
            (* ,past-r-albedo 
                (piecewise
                    ((> ,prefixed-reflection-type-randoms ,prefixed-brightness-factor) (
                        * ,prefixed-specular-r ,prefixed-brightness-factor)
                    )
                    ((* ,prefixed-diffuse-r (- 1 ,prefixed-brightness-factor)))
                )
            ))
        (= ,(symbol-append current-prefix 'g-albedo) 
            (* ,past-g-albedo 
                (piecewise
                    ((> ,prefixed-reflection-type-randoms ,prefixed-brightness-factor) (
                        * ,prefixed-specular-g ,prefixed-brightness-factor)
                    )
                    ((* ,prefixed-diffuse-g (- 1 ,prefixed-brightness-factor)))
                )
            ))
        (= ,(symbol-append current-prefix 'b-albedo) 
            (* ,past-b-albedo 
                (piecewise
                    ((> ,prefixed-reflection-type-randoms ,prefixed-brightness-factor) (
                        * ,prefixed-specular-b ,prefixed-brightness-factor)
                    )
                    ((* ,prefixed-diffuse-b (- 1 ,prefixed-brightness-factor)))
                )
            ))
        ; (= ,(symbol-append current-prefix 'g-albedo) 
        ;     (* ,past-g-albedo
        ;         (get mc-diffuse-tex-g ,prefixed-texture-pixel-space-texcoords)))
        ; (= ,(symbol-append current-prefix 'b-albedo) 
        ;     (* ,past-b-albedo 
        ;         (get mc-diffuse-tex-b ,prefixed-texture-pixel-space-texcoords)))

        (= ,(symbol-append current-prefix 'r-emission) 
            (+ ,(symbol-append past-prefix 'r-emission) 
                (* ,past-r-albedo (get mc-emission-tex-r ,prefixed-texture-pixel-space-texcoords))))
        (= ,(symbol-append current-prefix 'g-emission) 
            (+ ,(symbol-append past-prefix 'g-emission) 
                (* ,past-g-albedo (get mc-emission-tex-g ,prefixed-texture-pixel-space-texcoords))))
        (= ,(symbol-append current-prefix 'b-emission) 
            (+ ,(symbol-append past-prefix 'b-emission) 
                (* ,past-b-albedo (get mc-emission-tex-b ,prefixed-texture-pixel-space-texcoords))))

        (= ,prefixed-ray-path-length (- (mod (.x ,prefixed-raytracing-result) 1024) 0.001))
        (= ,(symbol-append current-prefix 'x-pos)
            (+ ,past-x-pos (* ,past-x-directions ,prefixed-ray-path-length)))
        (= ,(symbol-append current-prefix 'y-pos)
            (+ ,past-y-pos (* ,past-y-directions ,prefixed-ray-path-length)))
        (= ,(symbol-append current-prefix 'z-pos)
            (+ ,past-z-pos (* ,past-z-directions ,prefixed-ray-path-length)))

        (= ,prefixed-x-normals (get x-normals ,prefixed-triangle-index))
        (= ,prefixed-y-normals (get y-normals ,prefixed-triangle-index))
        (= ,prefixed-z-normals (get z-normals ,prefixed-triangle-index))

        (= ,prefixed-dot-incident-normal (+
            (* ,past-x-directions ,prefixed-x-normals)
            (* ,past-y-directions ,prefixed-y-normals)
            (* ,past-z-directions ,prefixed-z-normals)))

        (= ,prefixed-x-rand-norm
            (rand-norm LIST-LENGTH (+ 0 raytracer-reseeder ,seed-offset)))
        (= ,prefixed-y-rand-norm
            (rand-norm LIST-LENGTH (+ 1 raytracer-reseeder ,seed-offset)))
        (= ,prefixed-z-rand-norm
            (rand-norm LIST-LENGTH (+ 2 raytracer-reseeder ,seed-offset)))

        (= ,(symbol-append current-prefix 'hemispherical-sample-signs)
            (sign ,(lispsmos-static-dot
                prefixed-x-rand-norm prefixed-y-rand-norm prefixed-z-rand-norm
                prefixed-x-normals prefixed-y-normals prefixed-z-normals)))

        (= ,prefixed-hemisphere-mag (^ (+
            (* ,prefixed-x-rand-norm ,prefixed-x-rand-norm)
            (* ,prefixed-y-rand-norm ,prefixed-y-rand-norm)
            (* ,prefixed-z-rand-norm ,prefixed-z-rand-norm)) 0.5))

        (= ,prefixed-x-hemisphere
            (* ,prefixed-hemisphere-mag 
            ,(symbol-append current-prefix 'hemispherical-sample-signs)
            ,prefixed-x-rand-norm))
        (= ,prefixed-y-hemisphere
            (* ,prefixed-hemisphere-mag 
            ,(symbol-append current-prefix 'hemispherical-sample-signs)
            ,prefixed-y-rand-norm))
        (= ,prefixed-z-hemisphere
            (* ,prefixed-hemisphere-mag 
            ,(symbol-append current-prefix 'hemispherical-sample-signs)
            ,prefixed-z-rand-norm))

        (= ,prefixed-x-specular
            (lerp
            (- ,past-x-directions (* 2.0 ,prefixed-dot-incident-normal ,prefixed-x-normals))
            ,prefixed-x-hemisphere
            ,prefixed-specular-roughness))
        (= ,prefixed-y-specular
            (lerp
            (- ,past-y-directions (* 2.0 ,prefixed-dot-incident-normal ,prefixed-y-normals))
            ,prefixed-y-hemisphere
            ,prefixed-specular-roughness))
        (= ,prefixed-z-specular
            (lerp
            (- ,past-z-directions (* 2.0 ,prefixed-dot-incident-normal ,prefixed-z-normals))
            ,prefixed-z-hemisphere
            ,prefixed-specular-roughness))
        (= ,prefixed-specular-mag (^ (+
            (* ,prefixed-x-specular ,prefixed-x-specular)
            (* ,prefixed-y-specular ,prefixed-y-specular)
            (* ,prefixed-z-specular ,prefixed-z-specular)
        ) 0.5))

        (= ,prefixed-x-directions
            (piecewise
                ((> ,prefixed-reflection-type-randoms ,prefixed-brightness-factor) (/ ,prefixed-x-specular ,prefixed-specular-mag))
                (,prefixed-x-hemisphere)))
        (= ,prefixed-y-directions
            (piecewise
                ((> ,prefixed-reflection-type-randoms ,prefixed-brightness-factor) (/ ,prefixed-y-specular ,prefixed-specular-mag))
                (,prefixed-y-hemisphere)))
        (= ,prefixed-z-directions
            (piecewise
                ((> ,prefixed-reflection-type-randoms ,prefixed-brightness-factor) (/ ,prefixed-z-specular ,prefixed-specular-mag))
                (,prefixed-z-hemisphere)))
        ;(= ,prefixed-y-specular
        ;    (- ,past-y-directions (* 2.0 ,prefixed-dot-incident-normal ,prefixed-y-hemisphere)))
        ;(= ,prefixed-z-specular
        ;    (- ,past-z-directions (* 2.0 ,prefixed-dot-incident-normal ,prefixed-z-hemisphere)))
    ))

(define TOTAL-LIST-COUNT 64)

(define code (compile-lispsmos `(
    (folder ("Other" #t) 
        (fn (lerp a b fac) (+ a (* fac (- b a))))
        (= raytracer-reseeder 0)
        (= brightness-divider 0.1)
        (= texcoords-noindex ,(3d-col-texture-coordinates 3d-col "simple"))
        (= texcoords-indices ,(3d-col-texcoord-indices 3d-col "simple"))
        (= texcoords (get texcoords-noindex texcoords-indices))
        (= gamma (/ 1 2.2))

        (= WIDTH 384)
        (= HEIGHT 384)
        (= AREA (* WIDTH HEIGHT))
        (= LIST-LENGTH (/ AREA ,TOTAL-LIST-COUNT))

        ;(= render-list-index 0)
    )
    (= sample-count 0)

    (group ,@(foldl (lambda (list-index prev)
    (define prefixed-result-r
        (symbol-append 'result-r (number->symbol list-index)))
    (define prefixed-result-g
        (symbol-append 'result-g (number->symbol list-index)))
    (define prefixed-result-b
        (symbol-append 'result-b (number->symbol list-index)))
        (append prev `(
                (-> ,prefixed-result-r (/ (floor (* 1000 ,prefixed-result-r)) 1000))
                (-> ,prefixed-result-g (/ (floor (* 1000 ,prefixed-result-g)) 1000))
                (-> ,prefixed-result-b (/ (floor (* 1000 ,prefixed-result-b)) 1000))))
        )
        '() (sequence->list (in-range TOTAL-LIST-COUNT))))

    (= do-ray-trace (group
        (piecewise
            ,@(map (lambda (list-index)
            (define prefixed-result-r
                (symbol-append 'result-r (number->symbol list-index)))
            (define prefixed-result-g
                (symbol-append 'result-g (number->symbol list-index)))
            (define prefixed-result-b
                (symbol-append 'result-b (number->symbol list-index)))
                `(
                    (== (mod sample-count ,TOTAL-LIST-COUNT) ,list-index)
                    (group
                        (-> ,prefixed-result-r (+ ,prefixed-result-r bounce3-r-emission))
                        (-> ,prefixed-result-g (+ ,prefixed-result-g bounce3-g-emission))
                        (-> ,prefixed-result-b (+ ,prefixed-result-b bounce3-b-emission)))
                )
                ) (sequence->list (in-range TOTAL-LIST-COUNT))))
        ; (-> result-r (+ result-r bounce3-r-emission))
        ; (-> result-g (+ result-g bounce3-g-emission))
        ; (-> result-b (+ result-b bounce3-b-emission))
        (-> raytracer-reseeder (+ raytracer-reseeder 1011))
        (-> sample-count (+ sample-count 1))
        (-> brightness-divider (+ brightness-divider 0.025))
    ))
    (folder ("Texture Data" #t)
        (= mc-diffuse-tex-r (list ,@(get-reds diffuse-pixels-dst)))
        (= mc-diffuse-tex-g (list ,@(get-greens diffuse-pixels-dst)))
        (= mc-diffuse-tex-b (list ,@(get-blues diffuse-pixels-dst)))
        (= mc-emission-tex-r (list ,@(get-reds emission-pixels-dst)))
        (= mc-emission-tex-g (list ,@(get-greens emission-pixels-dst)))
        (= mc-emission-tex-b (list ,@(get-blues emission-pixels-dst)))
        (= mc-specular-tex-r (list ,@(get-reds specular-pixels-dst)))
        (= mc-specular-tex-g (list ,@(get-greens specular-pixels-dst)))
        (= mc-specular-tex-b (list ,@(get-blues specular-pixels-dst)))
        (= mc-specular-roughness (list ,@(get-reds specular-roughness-pixels-dst)))
    )
    (folder ("3D Object Data" #t)
        

        ,@(map-variables-to-values-lispsmos
            (3d-col-positions 3d-col "simple") '(x-vpos y-vpos z-vpos))
        ,@(map-variables-to-values-lispsmos
            (3d-col-face-normals 3d-col "simple") '(x-normals y-normals z-normals))
        (= vertex-indices ,(3d-col-vertex-indices 3d-col "simple"))

        (= diffuse-colors (* 255 ,(3d-col-diffuse-colors 3d-col)))
        (= diffuse-colors-r (for
            (get diffuse-colors i2)
        (i2 (list 1 4 ... (length diffuse-colors)))))
        (= diffuse-colors-g (for
            (get diffuse-colors i2)
        (i2 (list 2 5 ... (length diffuse-colors)))))
        (= diffuse-colors-b (for
            (get diffuse-colors i2)
        (i2 (list 3 6 ... (length diffuse-colors)))))

        (= material-indices ,(3d-col-material-indices 3d-col "simple"))
    )

    (= viewer-x-pos 0)
    (= viewer-y-pos 0)
    (= viewer-z-pos 0)

    (folder ("Ray Tracing" #t)
        (fn (clamp xmin xmax x) (min (max x xmin) xmax))
        (fn (compress-color-channel channel)
            (for 
                (
                    (* (floor (* 8192 (clamp 0 1 (get channel color-index)))) 1)
                    (* (floor (* 8192 (clamp 0 1 (get channel color-index)))) 8192)
                    (* (floor (* 8192 (clamp 0 1 (get channel color-index)))) 67108864)
                    (* (floor (* 8192 (clamp 0 1 (get channel color-index)))) 549755813888)
                )
                (color-index (* 4 (list 1 ... (/ 4 (length channel)))))))
        (fn (length3 x y z) (^ (+ (* x x) (* y y) (* z z)) 0.5))
        (= ray-start-directions-x-unnormalized  
            (* 4 (- (/ (mod (+ (list 0 ... (- LIST-LENGTH 1)) (* LIST-LENGTH (mod sample-count ,TOTAL-LIST-COUNT))) WIDTH) WIDTH) 0.5))
        )
        (= ray-start-directions-y-unnormalized  
            (* 4 (/ HEIGHT WIDTH) (- (/ (floor (/ (+ (list 0 ... (- LIST-LENGTH 1)) (* LIST-LENGTH (mod sample-count ,TOTAL-LIST-COUNT))) WIDTH)) HEIGHT) 0.5))
        )

        (= ray-start-directions-magnitude (length3 
            1 
            ray-start-directions-x-unnormalized
            ray-start-directions-y-unnormalized))
        (= ray-start-directions-x 
            (/ ray-start-directions-x-unnormalized ray-start-directions-magnitude))
        (= ray-start-directions-y 
            (/ ray-start-directions-y-unnormalized ray-start-directions-magnitude))
        (= ray-start-directions-z
            (/ 1 ray-start-directions-magnitude))

        (= indexed-x-vpos-tri1 (for
            (get x-vpos (get vertex-indices i2))
        (i2 (list 1 4 ... (length vertex-indices)))))
        (= indexed-y-vpos-tri1 (for
            (get y-vpos (get vertex-indices i2))
        (i2 (list 1 4 ... (length vertex-indices)))))
        (= indexed-z-vpos-tri1 (for
            (get z-vpos (get vertex-indices i2))
        (i2 (list 1 4 ... (length vertex-indices)))))

        (= indexed-x-vpos-tri2 (for
            (get x-vpos (get vertex-indices i2))
        (i2 (list 2 5 ... (length vertex-indices)))))
        (= indexed-y-vpos-tri2 (for
            (get y-vpos (get vertex-indices i2))
        (i2 (list 2 5 ... (length vertex-indices)))))
        (= indexed-z-vpos-tri2 (for
            (get z-vpos (get vertex-indices i2))
        (i2 (list 2 5 ... (length vertex-indices)))))

        (= indexed-x-vpos-tri3 (for
            (get x-vpos (get vertex-indices i2))
        (i2 (list 3 6 ... (length vertex-indices)))))
        (= indexed-y-vpos-tri3 (for
            (get y-vpos (get vertex-indices i2))
        (i2 (list 3 6 ... (length vertex-indices)))))
        (= indexed-z-vpos-tri3 (for
            (get z-vpos (get vertex-indices i2))
        (i2 (list 3 6 ... (length vertex-indices)))))

        (= original-x-directions ray-start-directions-x)
        (= original-y-directions ray-start-directions-y)
        (= original-z-directions ray-start-directions-z)

        (= original-x-pos (+ viewer-x-pos (* 0 (list 1 ... LIST-LENGTH))))
        (= original-y-pos (+ viewer-y-pos (* 0 (list 1 ... LIST-LENGTH))))
        (= original-z-pos (+ viewer-z-pos (* 0 (list 1 ... LIST-LENGTH))))

        (= original-r-albedo 1)
        (= original-g-albedo 1)
        (= original-b-albedo 1)

        (= original-r-emission 0)
        (= original-g-emission 0)
        (= original-b-emission 0)

        ,@(create-light-bounce-code 'original- 'bounce1- 0)
        ,@(create-light-bounce-code 'bounce1- 'bounce2- 3)
        ,@(create-light-bounce-code 'bounce2- 'bounce3- 6)

        (= zeroes (* 0 (list 1 ... LIST-LENGTH)))
        ; (= ray-tracing-results 
        ;     (muller-trumbore-full-data
        ;         viewer-x-pos viewer-y-pos viewer-z-pos
        ;         (get ray-start-directions-x i3)
        ;         (get ray-start-directions-y i3)
        ;         (get ray-start-directions-z i3)
        ;         indexed-x-vpos-tri1 indexed-y-vpos-tri1 indexed-z-vpos-tri1 
        ;         indexed-x-vpos-tri2 indexed-y-vpos-tri2 indexed-z-vpos-tri2 
        ;         indexed-x-vpos-tri3 indexed-y-vpos-tri3 indexed-z-vpos-tri3 
        ;     ))

        ; (= minimum-index
        ;     (get (get 
        ;         (list 1 ... (length ray-tracing-results)) 
        ;         (== (.x ray-tracing-results) (min (get (.x ray-tracing-results) (> (.x ray-tracing-results) 0))))) 1))

        ; (= ray-tracing-result (for
        ;     (+ (get ray-tracing-results minimum-index) (point (* 1024 minimum-index) 0))
        ; (i3 (list 1 ... 10000))))

        ; (= triangle-index (floor (/ (.x ray-tracing-result) 1024)))
        ; (= barycentric-coord-1 (/ (mod (.y ray-tracing-result) 67108864) 67108864))
        ; (= barycentric-coord-2 (/ (floor (/ (.y ray-tracing-result) 67108864)) 67108864))

        ; (= pixel-texcoords (+
        ;     (* barycentric-coord-1 (get texcoords (+ (* triangle-index 3) -1)))
        ;     (* barycentric-coord-2 (get texcoords (+ (* triangle-index 3) -0)))
        ;     (* (- 1 barycentric-coord-1 barycentric-coord-2) (get texcoords (+ (* triangle-index 3) -2)))
        ; ))

        ; (= texture-pixel-space-texcoords (+ 1 
        ;     (floor (* (.x pixel-texcoords) 384)) 
        ;     (* 96 (- 575 (floor (* (.y pixel-texcoords) 576))))))

        ; (= result-r (get mc-diffuse-tex-r texture-pixel-space-texcoords))
        ; (= result-g (get mc-diffuse-tex-g texture-pixel-space-texcoords))
        ; (= result-b (get mc-diffuse-tex-b texture-pixel-space-texcoords))
    (fn (truncate x) (/ (floor (* x 1000)) 1000))
    ,@(foldl (lambda (list-index prev)
        (define prefixed-ray-traced-colors
            (symbol-append 'ray-traced-colors (number->symbol list-index)))
        (define prefixed-result-r
            (symbol-append 'result-r (number->symbol list-index)))
        (define prefixed-result-g
            (symbol-append 'result-g (number->symbol list-index)))
        (define prefixed-result-b
            (symbol-append 'result-b (number->symbol list-index)))
        (append prev `(
        (= ,prefixed-result-r zeroes)
        (= ,prefixed-result-g zeroes)
        (= ,prefixed-result-b zeroes)
        (= ,prefixed-ray-traced-colors
            (rgb 
                (/ (* 256 (^ ,prefixed-result-r gamma)) brightness-divider) 
                (/ (* 256 (^ ,prefixed-result-g gamma)) brightness-divider) 
                (/ (* 256 (^ ,prefixed-result-b gamma)) brightness-divider)))
        (display
            (for
                (polygon 
                    (point i j)
                    (point (+ i 0.015) j)
                    (point (+ i 0.015) (+ j 0.015))
                    (point i (+ j 0.015)))
                (i (* 0.01 (list 1 ... WIDTH)))
                (j (* 0.01 
                    (+ 
                        (* (/ HEIGHT ,TOTAL-LIST-COUNT) ,list-index)    
                    (list 1 ... (/ HEIGHT ,TOTAL-LIST-COUNT)))))
            )
            (lines #f)
            (fill-opacity 1)
            ; (color-latex (rgb 
            ;     (get diffuse-colors-r (get material-indices ray-tracing-polygon-indices))
            ;     (get diffuse-colors-g (get material-indices ray-tracing-polygon-indices))
            ;     (get diffuse-colors-b (get material-indices ray-tracing-polygon-indices))))
            (color-latex ,prefixed-ray-traced-colors)
        )

        ))
            ) `() (sequence->list (in-range TOTAL-LIST-COUNT)))
    )

    
    
    (folder ("Ray-triangle Intersection Formula" #t)
        ,@muller-trumbore-ray-triangle-intersection-formula
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