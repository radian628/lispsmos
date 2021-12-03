; Configure procedural/action code
(procedureConfig
  (desmosEntryPoint main)
  (pointerStack ps)
  (programCounter pc)
)

(folder ((title "PLY File"))
  (importPLY "http://localhost:8080/monke.ply" TestPLY)
)

; Define starting viewport
(viewport -2 2 -2 2)

; Define XYZ values
(defineFindAndReplace defineXYZ inputVarName xVals yVals zVals
    (
        (= (concatTokens x inputVarName) xVals)
        (= (concatTokens y inputVarName) yVals)
        (= (concatTokens z inputVarName) zVals)
    )
)
; Define rotated version of lists
(defineFindAndReplace getRotated inputVarName outputVarName
    (
        (= (concatTokens x outputVarName) (xRotateAboutYAxis (concatTokens x inputVarName) (concatTokens y inputVarName) (concatTokens z inputVarName)))
        (= (concatTokens z inputVarName LISPSMOSIntermediate) (zRotateAboutYAxis (concatTokens x inputVarName) (concatTokens y inputVarName) (concatTokens z inputVarName)))
        (= (concatTokens y outputVarName) (yRotateAboutXAxis (concatTokens x outputVarName) (concatTokens y inputVarName) (concatTokens z inputVarName LISPSMOSIntermediate)))
        (= (concatTokens z outputVarName) (zRotateAboutXAxis (concatTokens x outputVarName) (concatTokens y inputVarName) (concatTokens z inputVarName LISPSMOSIntermediate)))
    )
)
; 3D Component Interface
(defineFindAndReplace x3 v
  (concatTokens x v)
)
(defineFindAndReplace y3 v
  (concatTokens y v)
)
(defineFindAndReplace z3 v
  (concatTokens z v)
)


(folder ((title "3D Transformations"))
  ; linalg stuff
  (fn dot x1 y1 z1 x2 y2 z2 (+ (* x1 x2) (* y1 y2) (* z1 z2)))
  (fn mag3D x y z (sqrt (+ (^ x 2) (^ y 2) (^ z 2))))
  (fn dotNormalizedInternal1 x1 y1 z1 x2 y2 z2 mag1 mag2 (dot (/ x1 mag1) (/ y1 mag1) (/ z1 mag1) (/ x2 mag2) (/ y2 mag2) (/ z2 mag2)))
  (fn dotNormalized x1 y1 z1 x2 y2 z2 (dotNormalizedInternal1 x1 y1 z1 x2 y2 z2 (mag3D x1 y1 z1) (mag3D x2 y2 z2)))
  ; winding order
  (fn windingOrderContribution p1 p2 (* (- (.x p2) (.x p1)) (+ (.y p2) (.y p1))))
  (fn getCullingInformation points zValues indices ordering
    (comprehension 
      (piecewise
        ((> 
          (max
            ([] zValues ([] indices (+ n 1)))
            ([] zValues ([] indices (+ n 2)))
            ([] zValues ([] indices (+ n 3)))
          )
          -16
          )
          (+
            (windingOrderContribution ([] points ([] indices (+ n 1))) ([] points ([] indices (+ n 2))))
            (windingOrderContribution ([] points ([] indices (+ n 2))) ([] points ([] indices (+ n 3))))
            (windingOrderContribution ([] points ([] indices (+ n 3))) ([] points ([] indices (+ n 1))))
          )
        )
        (-1)
      )
      (n (* 3 ([] (list 0 ... (/ (floor (length indices)) 3)) (join ordering 0))))
    )
  )
  ; Indexed Triangles
  (fn drawIndexed points indices ordering
    (comprehension (
      polygon 
      ([] points ([] indices (+ n 1))) 
      ([] points ([] indices (+ n 2)))
      ([] points ([] indices (+ n 3)))
    ) (n (* 3 ([] (list 0 ... (/ (floor (length indices)) 3)) (join ordering 0)))))
  )
  (fn getIndexedDepths depths indices
    (comprehension (
      (/ (+
        ([] depths ([] indices (+ n 1))) 
        ([] depths ([] indices (+ n 2)))
        ([] depths ([] indices (+ n 3)))
      ) 3)
    )
    (n (* 3 (list 0 ... (/ (floor (length indices)) 3)))))
  )
  ;; (fn getIndexedQuadNormals xs ys zs indices
  ;;   (comprehension (
  ;;     ()
  ;;   )
  ;;   (n (* 4 (list 0 ... (/ (floor (length indices)) 4)))))
  ;; )
  (fn getPolygonOrdering depths
    (sort (list 1 ... (length depths)) (* -1 depths))
  )
  (fn getMinimumDepths depths
    (comprehension (
      (min
        ([] depths ([] indices (+ n 1))) 
        ([] depths ([] indices (+ n 2)))
        ([] depths ([] indices (+ n 3)))
      )
    )
    (n (* 3 (list 0 ... (/ (floor (length indices)) 3)))))
  )
  (fn getFaceColors rs gs bs indices
    (comprehension (
      (rgb
        (mean
          ([] rs ([] indices (+ n 1))) 
          ([] rs ([] indices (+ n 2)))
          ([] rs ([] indices (+ n 3)))
        )
        (mean
          ([] gs ([] indices (+ n 1))) 
          ([] gs ([] indices (+ n 2)))
          ([] gs ([] indices (+ n 3)))
        )
        (mean
          ([] bs ([] indices (+ n 1))) 
          ([] bs ([] indices (+ n 2)))
          ([] bs ([] indices (+ n 3)))
        )
      )
    )
    (n (* 3 (list 0 ... (/ (floor (length indices)) 3)))))
  )
  (fn indexedMean property indices
    (comprehension (
      (mean
        ([] property ([] indices (+ n 1))) 
        ([] property ([] indices (+ n 2)))
        ([] property ([] indices (+ n 3)))
      )
    )
    (n (* 3 (list 0 ... (/ (floor (length indices)) 3)))))
  )
  (= cuboidIndexBuffer (list 
    2 1 3 4 2 3
    6 8 7 5 6 7
    1 2 6 5 1 6
    4 3 7 8 4 7
    3 1 5 7 3 5
    4 8 6 2 4 6
  ))
  (defineFindAndReplace cuboidVertexBuffer name x y z xPos yPos zPos
    (defineXYZ name
      (+ (list (* -1 x) x (* -1 x) x (* -1 x) x (* -1 x) x) xPos)
      (+ (list (* -1 y) (* -1 y) y y (* -1 y) (* -1 y) y y) yPos)
      (+ (list (* -1 z) (* -1 z) (* -1 z) (* -1 z) z z z z) zPos)
    )
  )
  (defineFindAndReplace join3D name src1 src2
    (defineXYZ name
      (join (x3 src1) (x3 src2))
      (join (y3 src1) (y3 src2))
      (join (z3 src1) (z3 src2))
    )
  )

  ; View rotation
  (displayMe
    (= rotationView (point 0 0))
  )
  (= rotation (* 5 rotationView))
  (fn mag x y (sqrt (+ (^ x 2) (^ y 2))))
  (fn project3D x y z (piecewise ((> z 0) (point (/ x z) (/ y z))) ((point (/ 0 0) (/ 0 0)))))
  (fn project3DTranslated x y z (piecewise
    ((> z -16) (project3D (+ x 0) (+ y 0) (+ z 16)))
    ((* 1000000 (point (/ x (mag x y)) (/ y (mag x y)))))
  ))
  (fn xRotateAboutYAxis x y z (- (* x (cos (.x rotation))) (* z (sin (.x rotation)))))
  (fn zRotateAboutYAxis x y z (+ (* x (sin (.x rotation))) (* z (cos (.x rotation)))))
  (fn yRotateAboutXAxis x y z (- (* y (cos (.y rotation))) (* z (sin (.y rotation)))))
  (fn zRotateAboutXAxis x y z (+ (* y (sin (.y rotation))) (* z (cos (.y rotation)))))
)

(folder ((title "Path"))
  (= pathDims (list 2 2 2))
  (defineXYZ Path TestPLYELEMvertexPROPx TestPLYELEMvertexPROPy TestPLYELEMvertexPROPz)
  (= PathIndexBuffer (+ TestPLYELEMfacePROPvertexunderscoreindices 1))

  (getRotated Path PathRotated)
  (= pathProjected (join (project3DTranslated (x3 PathRotated) (y3 PathRotated) (z3 PathRotated)) (point (/ 0 0) (/ 0 0))))

  (= xFaceNormals (indexedMean TestPLYELEMvertexPROPnx PathIndexBuffer))
  (= yFaceNormals (indexedMean TestPLYELEMvertexPROPny PathIndexBuffer))
  (= zFaceNormals (indexedMean TestPLYELEMvertexPROPnz PathIndexBuffer))
  (= faceBrightness (max 0.1 
    (dotNormalized
      xFaceNormals yFaceNormals zFaceNormals
      (cos t) (sin t) 1
    )
  ))

  (= colors 
    ([]
      ([]
        (rgb 
          (* (indexedMean TestPLYELEMvertexPROPred PathIndexBuffer) faceBrightness)
          (* (indexedMean TestPLYELEMvertexPROPgreen PathIndexBuffer) faceBrightness)
          (* (indexedMean TestPLYELEMvertexPROPblue PathIndexBuffer) faceBrightness)
        )
        PathPolygonOrdering
      )
      (> PathWindingOrders 0)
    )
  )

  (= PathDepths (getIndexedDepths (z3 PathRotated) PathIndexBuffer))
  (= PathPolygonOrdering (getPolygonOrdering PathDepths))
  (= PathWindingOrders (getCullingInformation pathProjected (z3 PathRotated) PathIndexBuffer PathPolygonOrdering))

  (displayMe  
    ([] (drawIndexed pathProjected PathIndexBuffer PathPolygonOrdering) (> PathWindingOrders 0))
    (color red)
    (colorLatex colors)
    (fillOpacity 1)
    (lines false)
  )
)

(folder ((title "Test/Controls"))
  (= t 0)
)