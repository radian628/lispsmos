(folder ((title "Linear Algebra"))
  ; Matrix multiplication
  (defineFindAndReplace getRotatedByMatrix inputVarName outputVarName matrix
    (
      (= (x3 outputVarName) (+ (* (x3 inputVarName) ([] matrix 1)) (* (y3 inputVarName) ([] matrix 4)) (* (z3 inputVarName) ([] matrix 7))))
      (= (y3 outputVarName) (+ (* (x3 inputVarName) ([] matrix 2)) (* (y3 inputVarName) ([] matrix 5)) (* (z3 inputVarName) ([] matrix 8))))
      (= (z3 outputVarName) (+ (* (x3 inputVarName) ([] matrix 3)) (* (y3 inputVarName) ([] matrix 6)) (* (z3 inputVarName) ([] matrix 9))))
    )
  )
  (fn getSingleRotatedByMatrix vector matrix
    (list
      (+ (* ([] vector 1) ([] matrix 1)) (* ([] vector 2) ([] matrix 4)) (* ([] vector 3) ([] matrix 7)))
      (+ (* ([] vector 1) ([] matrix 2)) (* ([] vector 2) ([] matrix 5)) (* ([] vector 3) ([] matrix 8)))
      (+ (* ([] vector 1) ([] matrix 3)) (* ([] vector 2) ([] matrix 6)) (* ([] vector 3) ([] matrix 9)))
    )
  )
  (= mat3Identity (list 1 0 0 0 1 0 0 0 1))
  (fn mat3Multiply mat1 mat2
    (list
      (dot ([] mat1 1) ([] mat1 2) ([] mat1 3) ([] mat2 1) ([] mat2 4) ([] mat2 7))
      (dot ([] mat1 1) ([] mat1 2) ([] mat1 3) ([] mat2 2) ([] mat2 5) ([] mat2 8))
      (dot ([] mat1 1) ([] mat1 2) ([] mat1 3) ([] mat2 3) ([] mat2 6) ([] mat2 9))
      (dot ([] mat1 4) ([] mat1 5) ([] mat1 6) ([] mat2 1) ([] mat2 4) ([] mat2 7))
      (dot ([] mat1 4) ([] mat1 5) ([] mat1 6) ([] mat2 2) ([] mat2 5) ([] mat2 8))
      (dot ([] mat1 4) ([] mat1 5) ([] mat1 6) ([] mat2 3) ([] mat2 6) ([] mat2 9))
      (dot ([] mat1 7) ([] mat1 8) ([] mat1 9) ([] mat2 1) ([] mat2 4) ([] mat2 7))
      (dot ([] mat1 7) ([] mat1 8) ([] mat1 9) ([] mat2 2) ([] mat2 5) ([] mat2 8))
      (dot ([] mat1 7) ([] mat1 8) ([] mat1 9) ([] mat2 3) ([] mat2 6) ([] mat2 9))
    )
  )
  (fn dot x1 y1 z1 x2 y2 z2 (+ (* x1 x2) (* y1 y2) (* z1 z2)))
  (fn dotVec3 vec1 vec2 (dot ([] vec1 1) ([] vec1 2) ([] vec1 3) ([] vec2 1) ([] vec2 2) ([] vec2 3)))
  (fn mag3DSq x y z (+ (^ x 2) (^ y 2) (^ z 2)))
  (fn mag3D x y z (sqrt (+ (^ x 2) (^ y 2) (^ z 2))))
  (fn distance3D vec1 vec2
    (mag3D
      (- ([] vec1 1) ([] vec2 1))
      (- ([] vec1 2) ([] vec2 2))
      (- ([] vec1 3) ([] vec2 3))
    )
  )
  (fn dotNormalizedInternal1 x1 y1 z1 x2 y2 z2 mag1 mag2 (dot (/ x1 mag1) (/ y1 mag1) (/ z1 mag1) (/ x2 mag2) (/ y2 mag2) (/ z2 mag2)))
  (fn dotNormalized x1 y1 z1 x2 y2 z2 (dotNormalizedInternal1 x1 y1 z1 x2 y2 z2 (mag3D x1 y1 z1) (mag3D x2 y2 z2)))

  (fn xCross x1 y1 z1 x2 y2 z2 (- (* y1 z2) (* z1 y2)))
  (fn yCross x1 y1 z1 x2 y2 z2 (- (* z1 x2) (* x1 z2)))
  (fn zCross x1 y1 z1 x2 y2 z2 (- (* x1 y2) (* y1 x2)))
  (fn cross vec1 vec2
    (list
      (xCross ([] vec1 1) ([] vec1 2) ([] vec1 3) ([] vec2 1) ([] vec2 2) ([] vec2 3))
      (yCross ([] vec1 1) ([] vec1 2) ([] vec1 3) ([] vec2 1) ([] vec2 2) ([] vec2 3))
      (zCross ([] vec1 1) ([] vec1 2) ([] vec1 3) ([] vec2 1) ([] vec2 2) ([] vec2 3))
    )
  )
  (fn normalizeVec3 vec
   (/ vec (+ 0.00000001 (mag3D ([] vec 1) ([] vec 2) ([] vec 3))))
  )

  (fn reflect incident normal
    (- incident (* 2 (dotVec3 incident normal) normal))
  )
  
  (fn mag x y (sqrt (+ (^ x 2) (^ y 2))))
  (fn normalize pt (/ pt (mag (.x pt) (.y pt))))
  
    
  (fn rotateAboutXAxis amount
    (list
      1 0 0
      0 (cos amount) (* -1 (sin amount))
      0 (sin amount) (cos amount)
    )
  )
  (fn rotateAboutYAxis amount
    (list
      (cos amount) 0 (sin amount)
      0 1 0 
      (* -1 (sin amount)) 0 (cos amount)
    )
  )
  (fn rotateAboutZAxis amount
    (list
      (cos amount) (* -1 (sin amount)) 0
      (sin amount) (cos amount) 0
      0 0 1
    )
  )

  (fn xRotateAboutYAxis x y z rotation (- (* x (cos (.x rotation))) (* z (sin (.x rotation)))))
  (fn zRotateAboutYAxis x y z rotation (+ (* x (sin (.x rotation))) (* z (cos (.x rotation)))))
  (fn yRotateAboutXAxis x y z rotation  (- (* y (cos (.y rotation))) (* z (sin (.y rotation)))))
  (fn zRotateAboutXAxis x y z rotation (+ (* y (sin (.y rotation))) (* z (cos (.y rotation)))))
)