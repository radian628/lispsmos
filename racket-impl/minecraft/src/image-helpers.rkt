#lang racket

(require racket/draw racket/hash)


; gets an array of pixels from an image png file
(define (get-argb-pixels-from-file filename)
    (define image-file (read-bitmap filename 'png))
    (define w (send image-file get-width))
    (define h (send image-file get-height))
    (define pixels (make-bytes (* 4 w h)))
    (send image-file get-argb-pixels 0 0 w h pixels)
    (list pixels w h))

(provide get-argb-pixels-from-file)




(define (get-number-color-subregion pixels w h sx sy sw sh)
    (define alpha-indices (flatten (map 
        (lambda (ypos) (map (lambda (xpos)
            (* 4 (+ xpos (* w ypos)))
            ) (sequence->list (range sx (+ sx sw)))))
        (sequence->list (range sy (+ sy sh))))))

    (define colors (map (lambda (i) 
        (
            +
            (bytes-ref pixels (+ i 1))
            (* 256 (bytes-ref pixels (+ i 2)))
            (* 256 256 (bytes-ref pixels (+ i 3)))
        )
        ) alpha-indices))
    colors)

(provide get-number-color-subregion)



; finds all unique colors in an image and gets borders from them as well
(define (get-image-borders pixels w h sx sy sw sh)

    (define area (* sw sh))

    (define alpha-indices (flatten (map 
        (lambda (ypos) (map (lambda (xpos)
            (* 4 (+ xpos (* w ypos)))
            ) (sequence->list (range sx (+ sx sw)))))
        (sequence->list (range sy (+ sy sh))))))

    (define colors (map (lambda (i) 
        (
            +
            (bytes-ref pixels (+ i 1))
            (* 256 (bytes-ref pixels (+ i 2)))
            (* 256 256 (bytes-ref pixels (+ i 3)))
        )
        ) alpha-indices))

    (define unique-colors (foldl (lambda (i unique)
        (set-add unique colors)
        ) (set) colors))

    (define (get-unique-color-edges color)
        ; (define edge-hash (make-hash))
        (define is-edge-unvisited '())
        (define edge-list '())
        
        (define edge-hash (make-hash))
        (for-each (lambda (i)
            (hash-set! edge-hash i '())
            ) (range (* (+ sw 1) (+ sh 1))))

        (for-each (lambda (color i)
            (define above (if (>= (- i sw) 0) (list-ref colors (- i sw)) -1))
            (define below (if (< (+ i sw) area) (list-ref colors (+ i sw)) -1))
            (define left (if (not (eq? (modulo i sw) 0)) (list-ref colors (- i 1)) -1))
            (define right (if (not (eq? (modulo i sw) (- sw 1))) (list-ref colors (+ i 1)) -1))

            (define topleft-pos i)
            (define topright-pos (+ i 1))
            (define bottomleft-pos (+ i sw))
            (define bottomright-pos (+ i sw 1))

            (define (check-square square endpoint1 endpoint2)
                (cond ((not (eq? color square))
                    (set! is-edge-unvisited (append is-edge-unvisited (list #t)))
                    (set! edge-list (append edge-list (list (list endpoint1 endpoint2))))
                    (hash-update! edge-hash endpoint1 (lambda (edges) (append edges (list (- (length edge-list) 1)))))
                    (hash-update! edge-hash endpoint2 (lambda (edges) (append edges (list (- (length edge-list) 1))))))))

            (check-square above topleft-pos topright-pos)
            (check-square below bottomleft-pos bottomright-pos)
            (check-square left topleft-pos bottomleft-pos)
            (check-square right topright-pos bottomright-pos)
        ) colors (range 0 area))

        (define vertex-list '())
        
        (define (edge-reorder-loop)
            (define unchecked-edge-index (index-of is-edge-unvisited #t))
            (cond (unchecked-edge-index 
                (define first-endpoint-index (car (list-ref edge-list unchecked-edge-index)))
                (set! vertex-list (append vertex-list 
                    (list (list (/ (modulo first-endpoint-index sw) sw) (/ (floor (/ first-endpoint-index sw)) sw)))))
                (define endpoint-edges (hash-ref edge-hash first-endpoint-index))

                (define (edge-reorder-inner-loop)
                    (set! is-edge-unvisited (list-set is-edge-unvisited unchecked-edge-index #f))
                    (define connected-edge-index (findf (lambda (edge) (list-ref is-edge-unvisited edge)) endpoint-edges
                        ))
                    (cond (connected-edge-index 
                        (define endpoints (list-ref edge-list connected-edge-index))
                        (set! first-endpoint-index 
                            (if (eq? first-endpoint-index (car endpoints)) (cadr endpoints) (car endpoints)))
                        (set! endpoint-edges (hash-ref edge-hash first-endpoint-index))
                        (edge-reorder-inner-loop)))
                )

                (edge-reorder-inner-loop)

                (edge-reorder-loop))
                (else 
                (set! vertex-list (append vertex-list 
                    (list (list -1 -1))))))
                
                )
            
            (edge-reorder-loop)
            vertex-list
            )    

        (list unique-colors (map (lambda (col) (get-unique-color-edges col)) (set->list unique-colors)))
    )


(provide get-image-borders)