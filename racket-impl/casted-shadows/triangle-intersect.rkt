#lang racket

(define triangle-intersect-formula 
    `(
        (fn (to-barycentric x y x1 x2 x3 y1 y2 y3)
            (point
                (/ 
                    (+ (* (- y2 y3) (- x x3)) (* (- x3 x2) (- y y3)))
                    (+ (* (- y2 y3) (- x1 x3)) (* (- x3 x2) (- y1 y3))))
                (/ 
                    (+ (* (- y3 y1) (- x x3)) (* (- x1 x3) (- y y3)))
                    (+ (* (- y2 y3) (- x1 x3)) (* (- x3 x2) (- y1 y3))))
            ))

        (fn (cross2d v1 v2) (- (* (.x v1) (.y v2)) (* (.y v1) (.x v2))))

        (fn (halfspace a b p)
            (-
                (* (- (.x b) (.x a)) (- (.y p) (.y a)))
                (* (- (.y b) (.y a)) (- (.x p) (.x a)))
            ))

        (fn (line-segments-intersection-factor l1 l2 l3 l4)
            (* -1 ( /
                (cross2d (- l3 l1) (- l4 l3))
                (cross2d (- l4 l3) (- l2 l1))
            )))

        (= line-1-starts (list a1 a2 a3 a1 a2 a3 a1 a2 a3))
        (= line-1-ends (list a2 a3 a1 a2 a3 a1 a2 a3 a1))
        (= line-2-starts (list b1 b1 b1 b2 b2 b2 b3 b3 b3))
        (= line-2-ends (list b2 b2 b2 b3 b3 b3 b1 b1 b1))

        (= line-intersection-factors-1 (
            line-segments-intersection-factor
            line-1-starts
            line-1-ends
            line-2-starts
            line-2-ends
        ))
        (= line-intersection-factors-2 (
            line-segments-intersection-factor
            line-2-starts
            line-2-ends
            line-1-starts
            line-1-ends
        ))

        (= valid-intersects (
            piecewise
            ((< line-intersection-factors-1 0) 0)
            ((> line-intersection-factors-1 1) 0)
            ((< line-intersection-factors-2 0) 0)
            ((> line-intersection-factors-2 1) 0)
            (1)
        ))

        (= unfiltered-line-segment-intersects
            (+ (* (- line-1-ends line-1-starts)
            line-intersection-factors-1) line-1-starts))

        (= line-segment-intersects
            (get unfiltered-line-segment-intersects (= valid-intersects 1)))

        (= triangle-1-barycentrics
            (list
                (to-barycentric 
                    (.x a1) (.y a1)
                    (.x b1) (.x b2) (.x b3) (.y b1) (.y b2) (.y b3))
                (to-barycentric 
                    (.x a2) (.y a2)
                    (.x b1) (.x b2) (.x b3) (.y b1) (.y b2) (.y b3))
                (to-barycentric 
                    (.x a3) (.y a3)
                    (.x b1) (.x b2) (.x b3) (.y b1) (.y b2) (.y b3))
            )
            )
        (= triangle-2-barycentrics
            (list
                (to-barycentric 
                    (.x b1) (.y b1)
                    (.x a1) (.x a2) (.x a3) (.y a1) (.y a2) (.y a3))
                (to-barycentric 
                    (.x b2) (.y b2)
                    (.x a1) (.x a2) (.x a3) (.y a1) (.y a2) (.y a3))
                (to-barycentric 
                    (.x b3) (.y b3)
                    (.x a1) (.x a2) (.x a3) (.y a1) (.y a2) (.y a3))
            )
            )

        (fn (inside barycoord)
            (piecewise
                ((> (+ (.x barycoord) (.y barycoord)) 1) 0)
                ((< (.x barycoord) 0) 0)
                ((< (.y barycoord) 0) 0)
                (1)
            ))

        (= triangle-intersection-vertices
            (join
                line-segment-intersects
                (get (list a1 a2 a3) (= (inside triangle-1-barycentrics) 1))
                (get (list b1 b2 b3) (= (inside triangle-2-barycentrics) 1))    
            ))

        (fn (get-triangle-triangle-intersection
            a1 a2 a3 b1 b2 b3)
            triangle-intersection-vertices)

        (fn (get-triangle-triangle-intersection-polygon
            a1 a2 a3 b1 b2 b3)
            (sort triangle-intersection-vertices (arctan
                (- (.y triangle-intersection-vertices) (mean (.y triangle-intersection-vertices)))
                (- (.x triangle-intersection-vertices) (mean (.x triangle-intersection-vertices)))
            ))
        )
    ))


(provide triangle-intersect-formula)