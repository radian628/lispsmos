; Configure procedural/action code
(procedureConfig
  (desmosEntryPoint main)
  (pointerStack ps)
  (programCounter pc)
)

(folder ((title "PLY Stuff"))
  (defineFindAndReplace PLYGet fileVar elementType propertyType
    (concatTokens fileVar ELEM elementType PROP propertyType)
  )
  (importPLY "http://localhost:8080/airplane.ply" Airplane)
  (importPLY "http://localhost:8080/canyon.ply" Canyon)
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
(defineFindAndReplace getRotated inputVarName outputVarName amounts
    (
        (= (concatTokens x outputVarName) (xRotateAboutYAxis (concatTokens x inputVarName) (concatTokens y inputVarName) (concatTokens z inputVarName) amounts))
        (= (concatTokens z inputVarName LISPSMOSIntermediate) (zRotateAboutYAxis (concatTokens x inputVarName) (concatTokens y inputVarName) (concatTokens z inputVarName) amounts))
        (= (concatTokens y outputVarName) (yRotateAboutXAxis (concatTokens x outputVarName) (concatTokens y inputVarName) (concatTokens z inputVarName LISPSMOSIntermediate) amounts))
        (= (concatTokens z outputVarName) (zRotateAboutXAxis (concatTokens x outputVarName) (concatTokens y inputVarName) (concatTokens z inputVarName LISPSMOSIntermediate) amounts))
    )
)
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

; translating vertex buffers
(defineFindAndReplace getTranslated inputVar outputVar x y z
  (defineXYZ outputVar
    (+ (x3 inputVar) x)
    (+ (y3 inputVar) y)
    (+ (z3 inputVar) z)
  )
)

(folder ((title "3D Transformations"))
  ; linalg stuff
  (fn dot x1 y1 z1 x2 y2 z2 (+ (* x1 x2) (* y1 y2) (* z1 z2)))
  (fn dotVec3 vec1 vec2 (dot ([] vec1 1) ([] vec1 2) ([] vec1 3) ([] vec2 1) ([] vec2 2) ([] vec2 3)))
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


  ; Ray-triangle intersection for collision detection
  (= rtiEpsilon 0.0001)
  (fn rtiDeterminant rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2
    (dotVec3
      (list 
        (- x1 x0)
        (- y1 y0)
        (- z1 z0)
      )
      (cross 
        rayVector
        (list 
          (- x2 x0)
          (- y2 y0)
          (- z2 z0)
        )
      )
    )
  )
  (fn rtiRayVecCrossEdge2 rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2
    (cross 
      rayVector
      (list 
        (- x2 x0)
        (- y2 y0)
        (- z2 z0)
      )
    )
  )
  (fn rayTriangleIntersectionIntermediate3 rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2 determinant rayVecCrossEdge2 f s u q v
    (piecewise
      ((< v 0) -1)
      ((> (+ v u) 1) -1)
      ((* f (dotVec3 (list (- x2 x0) (- y2 y0) (- z2 z0)) q)))
    )
  )
  (fn rayTriangleIntersectionIntermediate2 rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2 determinant rayVecCrossEdge2 f s u
    (piecewise
      ((< u 0) -1)
      ((> u 1) -1)
      ((rayTriangleIntersectionIntermediate3 rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2 determinant rayVecCrossEdge2 f s u
        (cross s (list (- x1 x0) (- y1 y0) (- z1 z0)))
        (* f (dotVec3 rayVector (cross s (list (- x1 x0) (- y1 y0) (- z1 z0)))))
      ))
    )
  )
  (fn rayTriangleIntersectionIntermediate1 rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2 determinant rayVecCrossEdge2
    (piecewise
      ((< (* -1 rtiEpsilon) determinant rtiEpsilon) -1)
      ((rayTriangleIntersectionIntermediate2
        rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2 determinant rayVecCrossEdge2
        (/ 1 determinant) (- rayOrigin (list x0 y0 z0)) (* (/ 1 determinant) (dotVec3 (- rayOrigin (list x0 y0 z0)) rayVecCrossEdge2))
      ))
    )
  )
  (fn rayTriangleIntersection rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2
    (rayTriangleIntersectionIntermediate1 rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2 
      (rtiDeterminant rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2)
      (rtiRayVecCrossEdge2 rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2)
    )
  )
  (fn rayTriangleIntersectionList rayOrigin rayVector xValues yValues zValues indices
    (comprehension
      (rayTriangleIntersection rayOrigin rayVector 
        ([] xValues ([] indices (+ n 1)))
        ([] yValues ([] indices (+ n 1)))
        ([] zValues ([] indices (+ n 1)))
        ([] xValues ([] indices (+ n 2)))
        ([] yValues ([] indices (+ n 2)))
        ([] zValues ([] indices (+ n 2)))
        ([] xValues ([] indices (+ n 3)))
        ([] yValues ([] indices (+ n 3)))
        ([] zValues ([] indices (+ n 3)))
      )
      (n (* 3 (list 0 ... (/ (floor (length indices)) 3))))
    )
  )

  ; cull faces if needed
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
  (fn drawIndexedIntermediate points indices ordering triangleCenters
    (comprehension (
      polygon 
      (+ 
        ([] points ([] indices (+ n 1))) 
        (* (normalize (- ([] points ([] indices (+ n 1))) ([] triangleCenters (+ 1 (floor (/ n 3)))))) 0.01)
      ) 
      (+ 
        ([] points ([] indices (+ n 2))) 
        (* (normalize (- ([] points ([] indices (+ n 2))) ([] triangleCenters (+ 1 (floor (/ n 3)))))) 0.01)
      ) 
      (+ 
        ([] points ([] indices (+ n 3))) 
        (* (normalize (- ([] points ([] indices (+ n 3))) ([] triangleCenters (+ 1 (floor (/ n 3)))))) 0.01)
      ) 
    ) (n (* 3 ([] (list 0 ... (/ (floor (length indices)) 3)) (join ordering 0)))))
  )
  (fn drawIndexed points indices ordering
    (drawIndexedIntermediate points indices ordering (getTriangleAverages points indices))
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
  ; Add a slight triangle overlap to prevent strange lines
  (fn addTriangleOverlapIntermediate points indices avg
    (comprehension
      (+ 
        ([] points ([] indices n)) 
        (* (normalize (- ([] points ([] indices n)) ([] avg n))) 0.01)
      )
      (n (list 1 ... (length indices)))
    )
  )
  (fn getTriangleAverages triangleList indices
    (comprehension
      (point 
        (mean
          (.x ([] triangleList ([] indices (+ n 1))))
          (.x ([] triangleList ([] indices (+ n 2))))
          (.x ([] triangleList ([] indices (+ n 3))))
        )
        (mean
          (.y ([] triangleList ([] indices (+ n 1))))
          (.y ([] triangleList ([] indices (+ n 2))))
          (.y ([] triangleList ([] indices (+ n 3))))
        )
      )
      (n (* 3 (list 0 ... (/ (floor (length indices)) 3))))
    )
  )
  (fn addTriangleOverlap triangleList indices
    (addTriangleOverlapIntermediate triangleList indices (getTriangleAverages triangleList indices))
  )
  (defineFindAndReplace getNormalMaker dimension
    (
      (fn (concatTokens dimension GetIndexedNormal) xs ys zs indices
        (comprehension (
          (concatTokens dimension Cross) 
          (- ([] xs ([] indices (+ n 1))) ([] xs ([] indices (+ n 2))))
          (- ([] ys ([] indices (+ n 1))) ([] ys ([] indices (+ n 2))))
          (- ([] zs ([] indices (+ n 1))) ([] zs ([] indices (+ n 2))))
          (- ([] xs ([] indices (+ n 1))) ([] xs ([] indices (+ n 3))))
          (- ([] ys ([] indices (+ n 1))) ([] ys ([] indices (+ n 3))))
          (- ([] zs ([] indices (+ n 1))) ([] zs ([] indices (+ n 3))))
        )
        (n (* 3 (list 0 ... (/ (floor (length indices)) 3)))))
      )
    )
  )
  (getNormalMaker x)
  (getNormalMaker y)
  (getNormalMaker z)
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
  (defineFindAndReplace join3D name src1 src2
    (defineXYZ name
      (join (x3 src1) (x3 src2))
      (join (y3 src1) (y3 src2))
      (join (z3 src1) (z3 src2))
    )
  )

  (fn mag x y (sqrt (+ (^ x 2) (^ y 2))))
  (fn normalize pt (/ pt (mag (.x pt) (.y pt))))
  (fn project3D x y z (piecewise ((> z 0) (point (/ x z) (/ y z))) ((point (/ 0 0) (/ 0 0)))))
  (fn project3DTranslated x y z (piecewise
    ((> z -16) (project3D (+ x 0) (+ y 0) (+ z 16)))
    ((* 1000000 (point (/ x (mag x y)) (/ y (mag x y)))))
  ))
  (fn xRotateAboutYAxis x y z rotation (- (* x (cos (.x rotation))) (* z (sin (.x rotation)))))
  (fn zRotateAboutYAxis x y z rotation (+ (* x (sin (.x rotation))) (* z (cos (.x rotation)))))
  (fn yRotateAboutXAxis x y z rotation  (- (* y (cos (.y rotation))) (* z (sin (.y rotation)))))
  (fn zRotateAboutXAxis x y z rotation (+ (* y (sin (.y rotation))) (* z (cos (.y rotation)))))
)

(folder ((title "Path"))
  ; Transform airplane
  (defineXYZ AirplaneModelSpace (PLYGet Airplane vertex x) (PLYGet Airplane vertex y) (PLYGet Airplane vertex z))
  (= AirplaneModelMatrix (mat3Multiply
    (mat3Multiply
      (rotateAboutZAxis roll)
      (rotateAboutXAxis pitch)
    )
    (rotateAboutYAxis yaw)
  ))
  (getRotatedByMatrix AirplaneModelSpace AirplaneWorldSpaceIntermediate1 
    AirplaneModelMatrix
  )
  ; (getRotated AirplaneModelSpace AirplaneWorldSpaceIntermediate1 (point t2 0))
  (getTranslated AirplaneWorldSpaceIntermediate1 AirplaneWorldSpace ([] planePos 1) ([] planePos 2) ([] planePos 3))

  ; Transform canyon
  (defineXYZ CanyonModelSpace (PLYGet Canyon vertex x) (PLYGet Canyon vertex y) (PLYGet Canyon vertex z))
  (getTranslated CanyonModelSpace CanyonWorldSpace 8 -3 8)

  ; Combine both into single VBO
  (join3D VBOWorldSpace AirplaneWorldSpace CanyonWorldSpace)
  (= IndexBuffer (join 
    (+ AirplaneELEMfacePROPvertexunderscoreindices 1) 
    (+ CanyonELEMfacePROPvertexunderscoreindices 1 (length (PLYGet Airplane vertex x)))
  ))

  ; View space to camera space to 2D on the VBO

  (getTranslated VBOWorldSpace VBOCameraSpaceIntermediate1 (* -1 ([] planePos 1)) (* -1 ([] planePos 2)) (* -1 ([] planePos 3)))
  (= cameraMatrix (mat3Multiply (rotateAboutYAxis (* -1 (.x cameraRotation))) (rotateAboutXAxis (* -1 (.y cameraRotation)))))
  (getRotatedByMatrix VBOCameraSpaceIntermediate1 VBOCameraSpace cameraMatrix)
  (= vboProjected (join (project3DTranslated (x3 VBOCameraSpace) (y3 VBOCameraSpace) (z3 VBOCameraSpace)) (point (/ 0 0) (/ 0 0))))

  ; Calculate normals and lighting
  (= xFaceNormals (xGetIndexedNormal (x3 VBOWorldSpace) (y3 VBOWorldSpace) (z3 VBOWorldSpace) IndexBuffer));(indexedMean TestPLYELEMvertexPROPnx PathIndexBuffer))
  (= yFaceNormals (yGetIndexedNormal (x3 VBOWorldSpace) (y3 VBOWorldSpace) (z3 VBOWorldSpace) IndexBuffer));(indexedMean TestPLYELEMvertexPROPny PathIndexBuffer))
  (= zFaceNormals (zGetIndexedNormal (x3 VBOWorldSpace) (y3 VBOWorldSpace) (z3 VBOWorldSpace) IndexBuffer));(indexedMean TestPLYELEMvertexPROPnz PathIndexBuffer))
  (= faceBrightness (max 0.25 
    (dotNormalized
      xFaceNormals yFaceNormals zFaceNormals
      (cos t) (sin t) -0.5
    )
  ))

  ; Calculate colors
  (= colors 
    ([]
      ([]
        (rgb 
          (* (indexedMean (join AirplaneELEMvertexPROPred CanyonELEMvertexPROPred) IndexBuffer) faceBrightness)
          (* (indexedMean (join AirplaneELEMvertexPROPgreen CanyonELEMvertexPROPgreen) IndexBuffer) faceBrightness)
          (* (indexedMean (join AirplaneELEMvertexPROPblue CanyonELEMvertexPROPblue) IndexBuffer) faceBrightness)
        )
        ScenePolygonOrdering
      )
      (> SceneWindingOrders 0)
    )
  )

  (= SceneDepths (getIndexedDepths (z3 VBOCameraSpace) IndexBuffer))
  (= ScenePolygonOrdering (getPolygonOrdering SceneDepths))
  (= SceneWindingOrders (getCullingInformation vboProjected (z3 VBOCameraSpace) IndexBuffer ScenePolygonOrdering))

  (displayMe
    (polygon (point -100 -100) (point 100 -100) (point 100 100) (point -100 100))
    (colorLatex (rgb 100 150 255))
  )
  (displayMe  
    ([] (drawIndexed vboProjected IndexBuffer ScenePolygonOrdering) (> SceneWindingOrders 0))
    (color red)
    (colorLatex colors)
    (fillOpacity 1)
    (lines false)
  )
)

(folder ((title "Test/Controls"))
  ;; (image "http://localhost:8080/desmos-plane/dragger.png"
  ;;   (
  ;;     (width 1000)
  ;;     (height 1000)
  ;;     (foreground true)
  ;;     (draggable true)
  ;;     (center rotationView)
  ;;   )
  ;; )
  (= t 0.8)
  (= yaw 3.5)
  (= pitch 0)
  (= roll 0)
  (= planePos (list -60 -15 70))
  (= prevPlanePos (list -60 -15 70))
  (= planeVel (list 0 0 0))
  (= planeSpeed (+ 0.00000001 (mag3D ([] planeVel 1) ([] planeVel 2) ([] planeVel 3))))
  
  (= planeUpDir (getSingleRotatedByMatrix (list 0 1 0) AirplaneModelMatrix))
  (= planeForwardDir (getSingleRotatedByMatrix (list 0 0 1) AirplaneModelMatrix))
  (= planeRightDir (getSingleRotatedByMatrix (list 1 0 0) AirplaneModelMatrix))
  (= planeWingNormal planeUpDir)
  (= flowDirection (* -1 planeVel))
  (= aerodynamicForceAgainstWing (* (dotVec3 planeUpDir flowDirection) 10 planeWingNormal))

  (= planeRudderNormal planeRightDir)
  (= aerodynamicForceAgainstRudder (* (dotVec3 planeRightDir flowDirection) 10 planeRudderNormal))


  (= gravity (list 0 -25 0))
  (= wrapCamera
    (
      ,
      (-> rotationView (point 0 0))
      (-> accumulatedCameraRotation (+ accumulatedCameraRotation (* 1.5 rotationView)))
    )
  )
  (fn doPlanePhysicsStep deltaTime (
    (,
      ; Move plane
      (-> planePos (+ planePos (* deltaTime planeVel)))
      (-> prevPlanePos planePos)
      ; Forces acting on plane
      (-> planeVel (+ (* 0.9998 planeVel) (* deltaTime (+ gravity aerodynamicForceAgainstWing aerodynamicForceAgainstRudder))))
      ;(-> rotationView (point 0 0))
      ;; (piecewise
      ;;   ((> (.x rotationView) 1.0) wrapCamera)
      ;;   ((< (.x rotationView) -1.0) wrapCamera)
      ;;   ((> (.y rotationView) 1.0) wrapCamera)
      ;;   ((< (.y rotationView) -1.0) wrapCamera)
      ;; )
      ;(-> cameraRotation (+ cameraRotation (* 1.5 rotationView)))
      (-> yaw (+ yaw (* -0.05 (.x rotationJoystick))))
      (-> pitch (+ pitch (* 0.05 (.y rotationJoystick))))
    )
  ))

  (displayMe
    (= rotationJoystick (point 0 0))
    (colorLatex (rgb 255 0 0))
    (pointOpacity 1)
  )
  
  ; View rotation
  (displayMe
    (= rotationView (point 0 0))
    (colorLatex (rgb 255 0 0))
    (pointOpacity 0)
  )
  (= accumulatedCameraRotation (point 0 0))
  ;(= cameraRotation (+ accumulatedCameraRotation (* 1.5 rotationView)))
  (= cameraRotation (point yaw (* -1 (- 0.1 pitch))))

  (= intersections 
    (rayTriangleIntersectionList planePos planeForwardDir (x3 CanyonWorldSpace) (y3 CanyonWorldSpace) (z3 CanyonWorldSpace) CanyonELEMfacePROPvertexunderscoreindices)
  )
)

  ([] intersections (< 0 intersections (distance3D planePos prevPlanePos)))
(ticker (doPlanePhysicsStep (/ dt 1000)))