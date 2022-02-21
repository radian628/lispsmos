(viewport -2 2 -2 2)

(displayMe (= cameraRotation3D (point 0 0)))
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

  (defineFindAndReplace expandVec3 L (([] L 1) ([] L 2) ([] L 3)))
  (defineFindAndReplace expandVec4 L (([] L 1) ([] L 2) ([] L 3) ([] L 4)))

  (= cTheta (cos angle))
  (= sTheta (sin angle))
  (= rodriguesMatrix angle n1 n2 n3
    (list
      (+ (* n1 n1) (* (- 1 (* n1 n1)) cTheta)) (- (* n1 n2 (- 1 cTheta)) (* n3 sTheta)) (+ (* n1 n3 (- 1 cTheta)) (* n2 sTheta))
      (+ (* n1 n2 (- 1 cTheta)) (* n3 sTheta)) (+ (* n2 n2) (* (- 1 (* n2 n2)) cTheta)) (- (* n2 n3 (- 1 cTheta)) (* n1 sTheta))
      (- (* n1 n2 (- 1 cTheta)) (* n2 sTheta)) (+ (* n2 n3 (- 1 cTheta)) (* n1 sTheta)) (+ (* n3 n3) (* (- 1 (* n3 n3)) cTheta))
    )  
  )
)

(folder ((title "4D --> 3D transformations and projection"))
  (= xVBO4D (- (* 2 (random 100 1)) 1))
  (= yVBO4D (- (* 2 (random 100 2)) 1))
  (= zVBO4D (- (* 2 (random 100 3)) 1))
  (= wVBO4D (+ 3 (random 100 4)))


)

(folder ((title "3D --> 2D Transformations and projection"))

  (= xVBO3D (/ xVBO4D wVBO4D))
  (= yVBO3D (/ yVBO4D wVBO4D))
  (= zVBO3D (- (/ zVBO4D wVBO4D) 0))

  (= xRotation13D (- (* xVBO3D (cos (.x cameraRotation3D))) (* zVBO3D (sin (.x cameraRotation3D)))))
  (= zRotation13D (+ (* xVBO3D (sin (.x cameraRotation3D))) (* zVBO3D (cos (.x cameraRotation3D)))))

  (= yRotation23D (- (* yVBO3D (cos (.y cameraRotation3D))) (* zRotation13D (sin (.y cameraRotation3D)))))
  (= zRotation23D (+ (* yVBO3D (sin (.y cameraRotation3D))) (* zRotation13D (cos (.y cameraRotation3D)))))

  (= x2D (/ xRotation13D (+ zRotation23D 5)))
  (= y2D (/ yRotation23D (+ zRotation23D 5)))

  (displayMe (= projectedPoints (point x2D y2D)))
)