(multilayerFn dotNormalized x1 y1 z1 x2 y2 z2
  (
    (mag1 (sqrt (+ (* x1 x1) (* y1 y1) (* z1 z1))))
    (mag2 (sqrt (+ (* x2 x2) (* y2 y2) (* z2 z2))))
    (result (+ (* (/ x1 mag1) (/ x2 mag2)) (* (/ y1 mag1) (/ y2 mag2)) (* (/ z1 mag1) (/ z2 mag2))))
  )
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


(mullerTrumbore
  0 0 0
  0 0 1
  -1 -1 1
  0 2 2
  1 -1 3
)