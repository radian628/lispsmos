(folder ((title "Linear Algebra"))
  ; Matrix multiplication
  (evalMacro ct "
    return [['concatTokens'].concat(args.slice(1))];
  ")

  (defineFindAndReplace inlineDot x1 y1 z1 x2 y2 z2
    ((+ (* x1 x2) (* y1 y2) (* z1 z2)))
  )
  (defineFindAndReplace mat3WithoutLists varName a b c d e f g h i
    (
      (= (ct varName 1) a)
      (= (ct varName 2) b)
      (= (ct varName 3) c)
      (= (ct varName 4) d)
      (= (ct varName 5) e)
      (= (ct varName 6) f)
      (= (ct varName 7) g)
      (= (ct varName 8) h)
      (= (ct varName 9) i)
    )
  )
  (defineFindAndReplace spreadMat3WithoutLists varName
    (
      (ct varName 1)
      (ct varName 2)
      (ct varName 3)
      (ct varName 4)
      (ct varName 5)
      (ct varName 6)
      (ct varName 7)
      (ct varName 8)
      (ct varName 9)
    ) 
  )

  (defineFindAndReplace mat3MultiplyWithoutLists mat1 mat2 outMat
    (
      (= (ct outMat 1) (inlineDot (ct mat1 1) (ct mat1 2) (ct mat1 3) (ct mat2 1) (ct mat2 4) (ct mat2 7)))
      (= (ct outMat 2) (inlineDot (ct mat1 1) (ct mat1 2) (ct mat1 3) (ct mat2 2) (ct mat2 5) (ct mat2 8)))
      (= (ct outMat 3) (inlineDot (ct mat1 1) (ct mat1 2) (ct mat1 3) (ct mat2 3) (ct mat2 6) (ct mat2 9)))
      (= (ct outMat 4) (inlineDot (ct mat1 4) (ct mat1 5) (ct mat1 6) (ct mat2 1) (ct mat2 4) (ct mat2 7)))
      (= (ct outMat 5) (inlineDot (ct mat1 4) (ct mat1 5) (ct mat1 6) (ct mat2 2) (ct mat2 5) (ct mat2 8)))
      (= (ct outMat 6) (inlineDot (ct mat1 4) (ct mat1 5) (ct mat1 6) (ct mat2 3) (ct mat2 6) (ct mat2 9)))
      (= (ct outMat 7) (inlineDot (ct mat1 7) (ct mat1 8) (ct mat1 9) (ct mat2 1) (ct mat2 4) (ct mat2 7)))
      (= (ct outMat 8) (inlineDot (ct mat1 7) (ct mat1 8) (ct mat1 9) (ct mat2 2) (ct mat2 5) (ct mat2 8)))
      (= (ct outMat 9) (inlineDot (ct mat1 7) (ct mat1 8) (ct mat1 9) (ct mat2 3) (ct mat2 6) (ct mat2 9)))
    )
  )

  (defineFindAndReplace getRotatedByMatrixWithoutListAndThenTranslate ivn ovn mat x y z
    (
      (= (x3 ovn) (+ (inlineDot (x3 ivn) (y3 ivn) (z3 ivn) (ct mat 1) (ct mat 4) (ct mat 7)) x))
      (= (y3 ovn) (+ (inlineDot (x3 ivn) (y3 ivn) (z3 ivn) (ct mat 2) (ct mat 5) (ct mat 8)) y))
      (= (z3 ovn) (+ (inlineDot (x3 ivn) (y3 ivn) (z3 ivn) (ct mat 3) (ct mat 6) (ct mat 9)) z))
    )
  )
  (defineFindAndReplace getTranslatedAndThenRotateByMatrixWithoutList ivn ovn mat x y z
    (
      (= (x3 ovn) (inlineDot (+ x (x3 ivn)) (+ y (y3 ivn)) (+ z (z3 ivn)) (ct mat 1) (ct mat 4) (ct mat 7)))
      (= (y3 ovn) (inlineDot (+ x (x3 ivn)) (+ y (y3 ivn)) (+ z (z3 ivn)) (ct mat 2) (ct mat 5) (ct mat 8)))
      (= (z3 ovn) (inlineDot (+ x (x3 ivn)) (+ y (y3 ivn)) (+ z (z3 ivn)) (ct mat 3) (ct mat 6) (ct mat 9)))
    )
  )
  (fn getListVecRotatedByMatrixWithoutList vec mat1 mat2 mat3 mat4 mat5 mat6 mat7 mat8 mat9
    (list
      (inlineDot ([] vec 1) ([] vec 2) ([] vec 3) mat1 mat4 mat7)
      (inlineDot ([] vec 1) ([] vec 2) ([] vec 3) mat2 mat5 mat8)
      (inlineDot ([] vec 1) ([] vec 2) ([] vec 3) mat3 mat6 mat9)
    )
  )
  (defineFindAndReplace mat3WithoutListFromRollPitchYaw outMat r p y
    (
      (= (ct outMat 1) (* (cos y) (cos p)))
      (= (ct outMat 2) (- (* (cos y) (sin p) (sin r)) (* (sin y) (cos r))))
      (= (ct outMat 3) (+ (* (cos y) (sin p) (cos r)) (* (sin y) (sin r))))
      (= (ct outMat 4) (* (sin y) (cos p)))
      (= (ct outMat 5) (+ (* (sin y) (sin p) (sin r)) (* (cos y) (cos r))))
      (= (ct outMat 6) (- (* (sin y) (sin p) (cos r)) (* (cos y) (sin r))))
      (= (ct outMat 7) (* -1 (sin p)))
      (= (ct outMat 8) (* (cos p) (sin r)))
      (= (ct outMat 9) (* (cos p) (cos r)))
    )
  )

  (defineFindAndReplace getRotatedByMatrix inputVarName outputVarName matrix
    (
      (= (x3 outputVarName) (+ (* (x3 inputVarName) ([] matrix 1)) (* (y3 inputVarName) ([] matrix 4)) (* (z3 inputVarName) ([] matrix 7))))
      (= (y3 outputVarName) (+ (* (x3 inputVarName) ([] matrix 2)) (* (y3 inputVarName) ([] matrix 5)) (* (z3 inputVarName) ([] matrix 8))))
      (= (z3 outputVarName) (+ (* (x3 inputVarName) ([] matrix 3)) (* (y3 inputVarName) ([] matrix 6)) (* (z3 inputVarName) ([] matrix 9))))
    )
  )
  (defineFindAndReplace getTranslatedAndThenRotateByMatrix inputVarName outputVarName matrix x y z
    (
      (= (x3 outputVarName) (+ (* (+ x (x3 inputVarName)) ([] matrix 1)) (* (+ y (y3 inputVarName)) ([] matrix 4)) (* (+ z (z3 inputVarName)) ([] matrix 7))))
      (= (y3 outputVarName) (+ (* (+ x (x3 inputVarName)) ([] matrix 2)) (* (+ y (y3 inputVarName)) ([] matrix 5)) (* (+ z (z3 inputVarName)) ([] matrix 8))))
      (= (z3 outputVarName) (+ (* (+ x (x3 inputVarName)) ([] matrix 3)) (* (+ y (y3 inputVarName)) ([] matrix 6)) (* (+ z (z3 inputVarName)) ([] matrix 9))))
    )
  )
  (defineFindAndReplace getRotatedByMatrixAndThenTranslate inputVarName outputVarName matrix x y z
    (
      (= (x3 outputVarName) (+ (* (x3 inputVarName) ([] matrix 1)) (* (y3 inputVarName) ([] matrix 4)) (* (z3 inputVarName) ([] matrix 7)) x))
      (= (y3 outputVarName) (+ (* (x3 inputVarName) ([] matrix 2)) (* (y3 inputVarName) ([] matrix 5)) (* (z3 inputVarName) ([] matrix 8)) y))
      (= (z3 outputVarName) (+ (* (x3 inputVarName) ([] matrix 3)) (* (y3 inputVarName) ([] matrix 6)) (* (z3 inputVarName) ([] matrix 9)) z))
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
  (fn mag3DSq x y z (+ (* x x) (* y y) (* z z)))
  (fn mag3D x y z (sqrt (+ (* x x) (* y y) (* z z))))
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
  (fn magSq x y (+ (* x x) (* y y)))
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