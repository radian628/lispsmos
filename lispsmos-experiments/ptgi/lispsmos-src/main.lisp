(include "../lispsmos-src/binary-decode.lisp")
(importOBJ "../assets/untitled.obj" cube)
(= y (* 2 (^ x 2)))
(= obj (getOBJData cube))

;; (= halfListLength (floor (/ (length l) 2)))
;; (fn flatmap1 l
;;   (piecewise 
;;     ((> (length l) 1) (execIf (> (length l) 1) indexer
;;       (join (flatmap2 ([] l 1 ... halfListLength)) (flatmap2 ([] l (+ halfListLength 1) ...)))
;;     ))
;;     ((list ([] l 1) ([] l 1)))
;;   )
;; )
;; (fn flatmap2 l
;;   (piecewise 
;;     ((> (length l) 1) (execIf (> (length l) 1) indexer2
;;       (join (flatmap3 ([] l 1 ... halfListLength)) (flatmap3 ([] l (+ halfListLength 1) ...)))
;;     ))
;;     ((list ([] l 1) ([] l 1)))
;;   )
;; )
;; (fn flatmap3 l
;;   (piecewise 
;;     ((> (length l) 1) (execIf (> (length l) 1) indexer3
;;       (join ([] l 1 ... halfListLength) ([] l (+ halfListLength 1) ...))
;;     ))
;;     ((list ([] l 1) ([] l 1)))
;;   )
;; )
;; (flatmap1 (list 2 7 14 85))

(= q 15)
;(+ q (execIf (> q 10) indexer (sum n 1 400000000 (+ indexer (* q n)))))
(folder ((title "Linear Algebra"))
    
  (multilayerFn dotNormalized x1 y1 z1 x2 y2 z2
    (
      (mag1 (sqrt (+ (* x1 x1) (* y1 y1) (* z1 z1))))
      (mag2 (sqrt (+ (* x2 x2) (* y2 y2) (* z2 z2))))
      (result (+ (* (/ x1 mag1) (/ x2 mag2)) (* (/ y1 mag1) (/ y2 mag2)) (* (/ z1 mag1) (/ z2 mag2))))
    )
  )
  (fn normalizeList L
    (/ L (sqrt (+ (* ([] L 1) ([] L 1)) (* ([] L 2) ([] L 2)) (* ([] L 3) ([] L 3)))))
  )

  (= a 1)
  (dotNormalized 2 2 2 -3 -3 -3)

  (defineFindAndReplace xStaticCross ax ay az bx by bz
    ((- (* ay bz) (* az by)))
  )
  (defineFindAndReplace yStaticCross ax ay az bx by bz
    ((- (* az bx) (* ax bz)))
  )
  (defineFindAndReplace zStaticCross ax ay az bx by bz
    ((- (* ax by) (* ay bx)))
  )
  (defineFindAndReplace staticDot x1 y1 z1 x2 y2 z2
    ((+ (* x1 x2) (* y1 y2) (* z1 z2)))
  )
  (multilayerFn mullerTrumbore 
    xRay yRay zRay 
    xDir yDir zDir 
    xTri1 yTri1 zTri1 
    xTri2 yTri2 zTri2 
    xTri3 yTri3 zTri3 
    (
      (xE1 (- xTri2 xTri1))
      (yE1 (- yTri2 yTri1))
      (zE1 (- zTri2 zTri1))
      (xE2 (- xTri3 xTri1))
      (yE2 (- yTri3 yTri1))
      (zE2 (- zTri3 zTri1))
      (xN (xStaticCross xE1 yE1 zE1 xE2 yE2 zE2))
      (yN (yStaticCross xE1 yE1 zE1 xE2 yE2 zE2))
      (zN (zStaticCross xE1 yE1 zE1 xE2 yE2 zE2))
      (det (* -1 (staticDot xDir yDir zDir xN yN zN)))
      (invdet (/ 1 det))
      (xAO (- xRay xTri1))
      (yAO (- yRay yTri1))
      (zAO (- zRay zTri1))
      (xDAO (xStaticCross xAO yAO zAO xDir yDir zDir))
      (yDAO (yStaticCross xAO yAO zAO xDir yDir zDir))
      (zDAO (zStaticCross xAO yAO zAO xDir yDir zDir))
      (u (* (staticDot xE2 yE2 zE2 xDAO yDAO zDAO) invdet))
      (v (* -1 (staticDot xE1 yE1 zE1 xDAO yDAO zDAO) invdet))
      (t (* (staticDot xAO yAO zAO xN yN zN) invdet))
      (return (piecewise
        ((< det 0.00001) -1)
        ((< t 0) -1)
        ((< u 0) -1)
        ((< v 0) -1)
        ((> (+ u v) 1) -1)
        (t)
      ))
      ;(return det)
    )
  )
)