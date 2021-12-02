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
  (importPLY "http://localhost:8080/better_airplane.ply" Airplane)
  (importPLY "http://localhost:8080/lowpoly_canyon_1.ply" Terrain1)
  (importPLY "http://localhost:8080/lowpoly_canyon_2.ply" Terrain2)
)

(include "http://localhost:8080/desmos-plane/linear-algebra.lisp")
(include "http://localhost:8080/desmos-plane/3d-utility-macros.lisp")
(include "http://localhost:8080/desmos-plane/graphics-library.lisp")

; Define starting viewport
(viewport -2 2 -2 2)


(folder ((title "3D Transformations"))
  (fn project3D x y z (piecewise ((> z 0) (point (/ x z) (/ y z))) ((point (/ 0 0) (/ 0 0)))))
  (fn project3DTranslated x y z (piecewise
    ((> z -0) (project3D (+ x 0) (+ y 0) (+ z 0)))
    ((* 1000000 (point (/ x (mag x y)) (/ y (mag x y)))))
  ))
)

(folder ((title "Buffers and Drawing"))
  ; mix function
  (fn mix a b fac (+ a (* fac (- b a))))
  (fn mixClampAbove a b fac (mix a b (min fac 1)))

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




  ; Combine terrain data
  (defineXYZ Terrain1WorldSpace (PLYGet Terrain1 vertex x) (PLYGet Terrain1 vertex y) (PLYGet Terrain1 vertex z))
  (defineXYZ Terrain2WorldSpace (PLYGet Terrain2 vertex x) (PLYGet Terrain2 vertex y) (PLYGet Terrain2 vertex z))
  (join3D TerrainWorldSpace Terrain1WorldSpace Terrain2WorldSpace)
  (= rTerrain (join (PLYGet Terrain1 vertex red) (PLYGet Terrain2 vertex red)))
  (= gTerrain (join (PLYGet Terrain1 vertex green) (PLYGet Terrain2 vertex green)))
  (= bTerrain (join (PLYGet Terrain1 vertex blue) (PLYGet Terrain2 vertex blue)))
  (= TerrainIndexBuffer (join
    (+ (PLYGet Terrain1 face vertexunderscoreindices) 1)
    (+ (PLYGet Terrain2 face vertexunderscoreindices) 1 (length (PLYGet Terrain1 face vertexunderscoreindices)))
  ))

  ; Combine both into single VBO, IndexBuffer, and Vertex Color Buffer
  (join3D VBOWorldSpace AirplaneWorldSpace TerrainWorldSpace)
  (= IndexBuffer (join 
    (+ AirplaneELEMfacePROPvertexunderscoreindices 1) 
    (+ TerrainIndexBuffer (length (PLYGet Airplane vertex x)))
  ))
  (= rSceneVertexColors (join (PLYGet Airplane vertex red) rTerrain))
  (= gSceneVertexColors (join (PLYGet Airplane vertex green) gTerrain))
  (= bSceneVertexColors (join (PLYGet Airplane vertex blue) bTerrain))
  (= rSceneFaceColors (indexedMean rSceneVertexColors IndexBuffer))
  (= gSceneFaceColors (indexedMean gSceneVertexColors IndexBuffer))
  (= bSceneFaceColors (indexedMean bSceneVertexColors IndexBuffer))

  ; View space to camera space to 2D on the VBO
  ;; (getTranslated VBOWorldSpace VBOCameraSpaceIntermediate1 (* -1 ([] planePos 1)) (* -1 ([] planePos 2)) (* -1 ([] planePos 3))
  (getTranslated VBOWorldSpace VBOCameraSpaceIntermediate1 (* -1 ([] cameraPos 1)) (* -1 ([] cameraPos 2)) (* -1 ([] cameraPos 3)))
  (= cameraMatrix (mat3Multiply (rotateAboutYAxis (* -1 (.x cameraRotation))) (rotateAboutXAxis (* -1 (.y cameraRotation)))))
  (= invCameraMatrix (mat3Multiply (rotateAboutXAxis (* 1 (.y cameraRotation))) (rotateAboutYAxis (* 1 (.x cameraRotation)))))
  (getRotatedByMatrix VBOCameraSpaceIntermediate1 VBOCameraSpaceIntermediate2 cameraMatrix)
  (getTranslated VBOCameraSpaceIntermediate2 VBOCameraSpace 0 0 0 )
  (= vboProjected (join (project3DTranslated (x3 VBOCameraSpace) (y3 VBOCameraSpace) (z3 VBOCameraSpace)) (point (/ 0 0) (/ 0 0))))
  ; Calculations for polygon ordering and culling.
  (= SceneDepths (getIndexedDepths (z3 VBOCameraSpace) IndexBuffer))
  (= ScenePolygonOrdering (getPolygonOrdering SceneDepths))
  (= SceneWindingOrders (getCullingInformation vboProjected (z3 VBOCameraSpace) IndexBuffer ScenePolygonOrdering))
  (= ScenePolygonFilter ([] ScenePolygonOrdering (> SceneWindingOrders 0)))
  


  ; Calculate normals and lighting
  (= xFaceNormals (xGetIndexedNormal (x3 VBOWorldSpace) (y3 VBOWorldSpace) (z3 VBOWorldSpace) IndexBuffer));(indexedMean TestPLYELEMvertexPROPnx PathIndexBuffer))
  (= yFaceNormals (yGetIndexedNormal (x3 VBOWorldSpace) (y3 VBOWorldSpace) (z3 VBOWorldSpace) IndexBuffer));(indexedMean TestPLYELEMvertexPROPny PathIndexBuffer))
  (= zFaceNormals (zGetIndexedNormal (x3 VBOWorldSpace) (y3 VBOWorldSpace) (z3 VBOWorldSpace) IndexBuffer));(indexedMean TestPLYELEMvertexPROPnz PathIndexBuffer))
  (= faceBrightness (max 0.35 
    (min 1.0 (* 1.6 (dotNormalized
      xFaceNormals yFaceNormals zFaceNormals
      (cos lightDir) (sin lightDir) -0.5
    )))
  ))

  ; Calculate colors
  (= colors 
    ([]
      (rgb 
        (mixClampAbove (* rSceneFaceColors faceBrightness) 100 (/ SceneDepths 250))
        (mixClampAbove (* gSceneFaceColors faceBrightness) 150 (/ SceneDepths 250))
        (mixClampAbove (* bSceneFaceColors faceBrightness) 255 (/ SceneDepths 250))
      )
      ScenePolygonFilter
    )
  )

  (displayMe
    (polygon (point -100 -100) (point 100 -100) (point 100 100) (point -100 100))
    (colorLatex (rgb 100 150 255))
    (fillOpacity 1)
  )
  (displayMe  
    ([] (drawIndexed vboProjected IndexBuffer) ScenePolygonFilter)
    (color red)
    (colorLatex colors)
    (fillOpacity 1)
    (lines false)
  )
)

(folder ((title "Test/Controls"))
  (= cameraPos (list -70 -15 80))
  (= idealCameraPos (+ planePos (getSingleRotatedByMatrix (list 0 4 -12) invCameraMatrix)))

  (= lightDir 0.8)
  (= yaw 3.5)
  (= pitch 0)
  (= roll 0)
  (= planePos (list -70 -15 70))
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
  (= crashed 0)
  (fn doPlanePhysicsStep deltaTime (
    piecewise
      ((== crashed 0)(,
        ; Move plane
        (-> framesPerSecond (/ 1 deltaTime))
        (-> planePos (+ planePos (* deltaTime planeVel)))
        (-> prevPlanePos planePos)
        ; Forces acting on plane
        (-> planeVel (+ (* (^ 0.999 deltaTime) planeVel) (* deltaTime (+ gravity aerodynamicForceAgainstWing aerodynamicForceAgainstRudder))))
        ; Control plane directions
        (-> yaw (+ yaw (* (* -1.25 deltaTime) (.x rotationJoystick))))
        (-> pitch (+ pitch (* (* 1.25 deltaTime) (.y rotationJoystick))))
        ; Test for crash
        (piecewise
          (
            (> (length 
              ([] intersections (< 0 intersections (* 1 (distance3D planePos prevPlanePos))))
            ) 0)
            (,
              (-> crashed 1)
            )
          )
        )
        ; Move camera
        (-> cameraPos (mix idealCameraPos cameraPos (^ 0.10 deltaTime)))
      ))
    )
  )

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
    (rayTriangleIntersectionList prevPlanePos (normalizeVec3 (- planePos prevPlanePos)) (x3 TerrainWorldSpace) (y3 TerrainWorldSpace) (z3 TerrainWorldSpace) TerrainIndexBuffer)
  )
)

(ticker (doPlanePhysicsStep (/ dt 1000)))

(= framesPerSecond 0)