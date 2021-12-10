; Configure procedural/action code
(procedureConfig
  (desmosEntryPoint main)
  (pointerStack ps)
  (programCounter pc)
)

(evalMacro withPath
  "
  let url = '\u0022http://localhost:8080/desmos-plane/' + args[2].slice(1, args[2].length-1) + '\u0022';
  console.log(url);
  return [[args[1], url, args[3]]];
  "
)

(folder ((title "PLY Stuff"))
  (defineFindAndReplace PLYGet fileVar elementType propertyType
    (concatTokens fileVar ELEM elementType PROP propertyType)
  )
  (withPath importPLY "better_airplane.ply" Airplane)
  (withPath importPLY "lowpoly_canyon_1.ply" Terrain1)
  (withPath importPLY "lowpoly_canyon_2.ply" Terrain2)
  (withPath importPLY "lowpoly_canyon_3.ply" Terrain3)
  (withPath importPLY "lowpoly_canyon_4.ply" Terrain4)
  (= Terrain1Viewbox (withPath importPLYBounds "lowpoly_canyon_1_viewbox.ply"))
  (= Terrain2Viewbox (withPath importPLYBounds "lowpoly_canyon_2_viewbox.ply"))
  (= Terrain3Viewbox (withPath importPLYBounds "lowpoly_canyon_3_viewbox.ply"))
  (= Terrain4Viewbox (withPath importPLYBounds "lowpoly_canyon_4_viewbox.ply"))
  (= SunOccluder1 (withPath importPLYBounds "sun_occluder_1.ply"))
  (= PointLight1 (withPath importPLYStats "point_light_1.ply"))
  (= Terrain1AvgPos (averagePLYPos Terrain1))
  (= Terrain2AvgPos (averagePLYPos Terrain2))
  (= Terrain3AvgPos (averagePLYPos Terrain3))
  (= Terrain4AvgPos (averagePLYPos Terrain4))
  (getFaceColors Airplane)
  (getFaceColors Terrain1)
  (getFaceColors Terrain2)
  (getFaceColors Terrain3)
  (getFaceColors Terrain4)
)

(include "http://localhost:8080/desmos-plane/linear-algebra.lisp")
(include "http://localhost:8080/desmos-plane/3d-utility-macros.lisp")
(include "http://localhost:8080/desmos-plane/graphics-library.lisp")

; Define starting viewport
(viewport -2 2 -2 2)


(folder ((title "3D Transformations"))
  (fn project3D x y z (piecewise ((> z 0) (point (/ x z) (/ y z))) ((point (/ 0 0) (/ 0 0)))))
  (fn project3DTranslated x y z (piecewise
    ((> z -0) (project3D x y z))
    ((* 1000 (point (/ x (magSq x y)) (/ y (magSq x y)))))
  ))
)

(folder ((title "Buffers and Drawing"))
  ; Determine whether a thing is inside a viewbox
  (fn isInsideViewbox position viewbox
    (piecewise
      ((< ([] position 1) ([] viewbox 1)) -1)
      ((> ([] position 1) ([] viewbox 4)) -1)
      ((< ([] position 2) ([] viewbox 2)) -1)
      ((> ([] position 2) ([] viewbox 5)) -1)
      ((< ([] position 3) ([] viewbox 3)) -1)
      ((> ([] position 3) ([] viewbox 6)) -1)
      (1)
    )
  )
  (fn distanceInsideBox position box
    (min
      (abs (- ([] position 1) ([] box 1)))
      (abs (- ([] position 1) ([] box 4)))
      (abs (- ([] position 2) ([] box 2)))
      (abs (- ([] position 2) ([] box 5)))
      (abs (- ([] position 3) ([] box 3)))
      (abs (- ([] position 3) ([] box 6)))
      ;(abs (- ([] position 1) (mean ([] box 1) ([] box 4))))
      ;(abs (- ([] position 2) (mean ([] box 2) ([] box 5))))
      ;(abs (- ([] position 3) (mean ([] box 3) ([] box 6))))
    )
  )
  
  ; Choose which terrain to load.
  (= terrainDistsRangeList (list 1 ... 2)) ;FIX THIS 
  (evalMacro addTerrainSlotProperties "
    let tspCat = args[1];
    let tspName = args[2];
    let terrains = args[3];
    let index = args[4];
    let result = terrains.map((terrain, i) => {
      return [['=', 'terrainSlot'+index+'ToLoad', (i+1).toString()], ['PLYGet', terrain, tspCat, tspName]]
    });
    console.log(result);
    return result;
  ")
  (evalMacro addTerrainSlotAverages "
    let terrains = args[1];
    return terrains.map(terrain => {
      return ['distance3D', 'planePosForTerrainSlots', terrain + 'AvgPos'];
    });
  ")
  (evalMacro determineTerrainSlotToLoad "
    let terrains = args[1];
    return terrains.map((terrain, i) => {
      return [['==', ['isInsideViewbox', 'planePosForTerrainSlots', terrain + 'Viewbox'], '1'], (i+1).toString()];
    });
  ")
  (defineFindAndReplace createTerrainSlot index terrains
    (
      (= (concatTokens terrainDistsSlot index) (list 
        (addTerrainSlotAverages terrains)
      ))
      (= (concatTokens terrainSlot index ToLoad) 
        ;; ([] ([] terrainDistsRangeList 
        ;;   (= (concatTokens terrainDistsSlot index) (min (concatTokens terrainDistsSlot index)))
        ;; ) 1)
        (piecewise
          (determineTerrainSlotToLoad terrains)
          (-1)
        )
      )
      (= (concatTokens xTerrainSlot index) (piecewise 
        (addTerrainSlotProperties vertex x terrains index)
        ((list))
      ))
      (= (concatTokens yTerrainSlot index) (piecewise 
        (addTerrainSlotProperties vertex y terrains index)
        ((list))
      ))
      (= (concatTokens zTerrainSlot index) (piecewise 
        (addTerrainSlotProperties vertex z terrains index)
        ((list))
      ))
      (= (concatTokens rTerrainSlot index) (piecewise 
        (addTerrainSlotProperties face red terrains index)
        ((list))
      ))
      (= (concatTokens gTerrainSlot index) (piecewise 
        (addTerrainSlotProperties face green terrains index)
        ((list))
      ))
      (= (concatTokens bTerrainSlot index) (piecewise 
        (addTerrainSlotProperties face blue terrains index)
        ((list))
      ))
      (= (concatTokens iTerrainSlot index) (piecewise 
        (addTerrainSlotProperties face vertexunderscoreindices terrains index)
        ((list))
      ))
    )
  )
  (createTerrainSlot 1 (Terrain1 Terrain4))
  (createTerrainSlot 2 (Terrain2))
  (createTerrainSlot 3 (Terrain3))
  (= planePosForTerrainSlots (list -70 -15 70))


  ; fade color
 
  (= sunOcclusionFactor  (piecewise
    ((== (isInsideViewbox planePos SunOccluder1) 1) 
    (min (max (* 0.3 (distanceInsideBox planePos SunOccluder1)) 0) 1))
    (0)))
  (= fadeColor 
    (mix
      (list 100 150 255)
      (list 0 0 0)
      sunOcclusionFactor
    )
  )

  ; mix function
  (fn mix a b fac (+ a (* fac (- b a))))
  (fn mixClampAbove a b fac (mix a b (min fac 1)))
  (fn mixClamp a b fac (mix a b (min fac (max fac 0) 1)))

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
  ; (defineXYZ Terrain1WorldSpace (PLYGet Terrain1 vertex x) (PLYGet Terrain1 vertex y) (PLYGet Terrain1 vertex z))
  ; (defineXYZ Terrain2WorldSpace (PLYGet Terrain2 vertex x) (PLYGet Terrain2 vertex y) (PLYGet Terrain2 vertex z))
  ; (defineXYZ Terrain3WorldSpace (PLYGet Terrain3 vertex x) (PLYGet Terrain3 vertex y) (PLYGet Terrain3 vertex z))
  ; (defineXYZ Terrain4WorldSpace (PLYGet Terrain4 vertex x) (PLYGet Terrain4 vertex y) (PLYGet Terrain4 vertex z))
  (join3D TerrainWorldSpace TerrainSlot1 TerrainSlot2 TerrainSlot3)
  (= rTerrain (join rTerrainSlot1 rTerrainSlot2 rTerrainSlot3))
  (= gTerrain (join gTerrainSlot1 gTerrainSlot2 gTerrainSlot3 ))
  (= bTerrain (join bTerrainSlot1 bTerrainSlot2 bTerrainSlot3 ))
  (= TerrainIndexBuffer (join
    (+ iTerrainSlot1 1)
    (+ iTerrainSlot2 1 (length xTerrainSlot1))
    (+ iTerrainSlot3 1 (length xTerrainSlot1) (length xTerrainSlot2))
    ;(+ (PLYGet Terrain2 face vertexunderscoreindices) 1 (length xTerrainSlot1))
    ;(+ (PLYGet Terrain3 face vertexunderscoreindices) 1 (length xTerrainSlot1) (length (PLYGet Terrain2 vertex x)))
    ;(+ (PLYGet Terrain4 face vertexunderscoreindices) 1 (length (PLYGet Terrain1 vertex x)) (length (PLYGet Terrain2 vertex x)) (length (PLYGet Terrain3 vertex x)))
  )
  )

  ; Combine both into single VBO, IndexBuffer, and Vertex Color Buffer
  (join3D VBOWorldSpace AirplaneWorldSpace TerrainWorldSpace)
  (= IndexBuffer (join 
    (+ AirplaneELEMfacePROPvertexunderscoreindices 1) 
    (+ TerrainIndexBuffer (length (PLYGet Airplane vertex x)))
  ))
  (= rSceneFaceColors (join (PLYGet Airplane face red) rTerrain))
  (= gSceneFaceColors (join (PLYGet Airplane face green) gTerrain))
  (= bSceneFaceColors (join (PLYGet Airplane face blue) bTerrain))
 ; (= rSceneFaceColors (indexedMean rSceneVertexColors IndexBuffer))
  ;(= gSceneFaceColors (indexedMean gSceneVertexColors IndexBuffer))
  ;(= bSceneFaceColors (indexedMean bSceneVertexColors IndexBuffer))

  ; View space to camera space to 2D on the VBO
  ;; (getTranslated VBOWorldSpace VBOCameraSpaceIntermediate1 (* -1 ([] planePos 1)) (* -1 ([] planePos 2)) (* -1 ([] planePos 3))
  (getRotatedByMatrixAndTranslate VBOWorldSpace VBOCameraSpace cameraMatrix (* -1 ([] cameraPos 1)) (* -1 ([] cameraPos 2)) (* -1 ([] cameraPos 3)))
  (= cameraMatrix (mat3Multiply (rotateAboutYAxis (* -1 (.x cameraRotation))) (rotateAboutXAxis (* -1 (.y cameraRotation)))))
  (= invCameraMatrix (mat3Multiply (rotateAboutXAxis (* 1 (.y cameraRotation))) (rotateAboutYAxis (* 1 (.x cameraRotation)))))
  ;; (getRotatedByMatrix VBOCameraSpaceIntermediate1 VBOCameraSpace cameraMatrix)
  ;; (getTranslated VBOCameraSpaceIntermediate2 VBOCameraSpace 0 0 0 )
  (= vboProjected (join (project3DTranslated (x3 VBOCameraSpace) (y3 VBOCameraSpace) (z3 VBOCameraSpace)) (point (/ 0 0) (/ 0 0))))
  ; Calculations for polygon ordering and culling.
  (= SceneDepths (getIndexedDepths (z3 VBOCameraSpace) IndexBuffer))
  (= ScenePolygonOrdering (getPolygonOrdering SceneDepths))
  ; (= SceneWindingOrders )
  (= ScenePolygonFilter ([] ScenePolygonOrdering (> (getCullingInformation vboProjected (z3 VBOCameraSpace) IndexBuffer ScenePolygonOrdering 18) 0)))
  
  (= PointLight2 (list 577 577 577))

  (= pointLight1Color (* (list 200.0 100.0 30.0) (+ 0.9 (* 0.2 ([] (random 1 globalTime) 1)))))
  (= pointLight2Color (* (list 1000000.0 1000000.0 1000000.0) 1))
  ;; (= rPointLights (list ([] pointLightColor 1)))
  ;; (= gPointLights (list ([] pointLightColor 2)))
  ;; (= bPointLights (list ([] pointLightColor 3)))
  ;; (= xPointLights (list ([] PointLight1 1)))
  ;; (= yPointLights (list ([] PointLight1 2)))
  ;; (= zPointLights (list ([] PointLight1 3)))

  ; Calculate normals and lighting
  ;; (= sunFaceBrightness (* (max 0.15 (- 1 sunOcclusionFactor)) (max 0.35 
  ;;   (min 1.0 (* 1.6 (dotNormalized
  ;;     xFaceNormals yFaceNormals zFaceNormals
  ;;     1 1 1
  ;;   ))))
  ;; ))


  ;; (= xFaceNormals (xGetIndexedNormal (x3 VBOWorldSpace) (y3 VBOWorldSpace) (z3 VBOWorldSpace) IndexBuffer));(indexedMean TestPLYELEMvertexPROPnx PathIndexBuffer))
  ;; (= yFaceNormals (yGetIndexedNormal (x3 VBOWorldSpace) (y3 VBOWorldSpace) (z3 VBOWorldSpace) IndexBuffer));(indexedMean TestPLYELEMvertexPROPny PathIndexBuffer))
  ;; (= zFaceNormals (zGetIndexedNormal (x3 VBOWorldSpace) (y3 VBOWorldSpace) (z3 VBOWorldSpace) IndexBuffer));(indexedMean TestPLYELEMvertexPROPnz PathIndexBuffer))
  ;; (= xMeans (indexedMean (x3 VBOWorldSpace) IndexBuffer))
  ;; (= yMeans (indexedMean (y3 VBOWorldSpace) IndexBuffer))
  ;; (= zMeans (indexedMean (z3 VBOWorldSpace) IndexBuffer))
  ;; (= xPointLight1Offset (- ([] PointLight1 1) xMeans))
  ;; (= yPointLight1Offset (- ([] PointLight1 2) yMeans))
  ;; (= zPointLight1Offset (- ([] PointLight1 3) zMeans))
  ;; (= pointLight1Brightness (/ (max 0 (dotNormalized
  ;;   xFaceNormals yFaceNormals zFaceNormals
  ;;   xPointLight1Offset yPointLight1Offset zPointLight1Offset
  ;; )) (mag3DSq xPointLight1Offset yPointLight1Offset zPointLight1Offset)))
  
  ;; (= xPointLight2Offset (- ([] PointLight2 1) xMeans))
  ;; (= yPointLight2Offset (- ([] PointLight2 2) yMeans))
  ;; (= zPointLight2Offset (- ([] PointLight2 3) zMeans))
  ;; (= pointLight2Brightness (/ (max 0 (dotNormalized
  ;;   xFaceNormals yFaceNormals zFaceNormals
  ;;   xPointLight2Offset yPointLight2Offset zPointLight2Offset
  ;; )) (mag3DSq xPointLight2Offset yPointLight2Offset zPointLight2Offset)))



  ;; (= rPointLight (* rSceneFaceColors 
  ;;   (sum lightIndex 1 (length rPointLights) 
  ;;     (* ([] rPointLights lightIndex) (/ (max 0 (dotNormalized
  ;;       xFaceNormals yFaceNormals zFaceNormals
  ;;       (- ([] xPointLights lightIndex) xMeans) (- ([] yPointLights lightIndex) yMeans) (- ([] zPointLights lightIndex) zMeans)
  ;;     )) (mag3DSq (- ([] xPointLights lightIndex) xMeans) (- ([] yPointLights lightIndex) yMeans) (- ([] zPointLights lightIndex) zMeans))))
  ;;   )
  ;; ))
  ;; (= gPointLight (* gSceneFaceColors 
  ;;   (sum lightIndex 1 (length gPointLights) 
  ;;     (* ([] bPointLights lightIndex) (/ (max 0 (dotNormalized
  ;;       xFaceNormals yFaceNormals zFaceNormals
  ;;       (- ([] xPointLights lightIndex) xMeans) (- ([] yPointLights lightIndex) yMeans) (- ([] zPointLights lightIndex) zMeans)
  ;;     )) (mag3DSq (- ([] xPointLights lightIndex) xMeans) (- ([] yPointLights lightIndex) yMeans) (- ([] zPointLights lightIndex) zMeans))))
  ;;   )
  ;; ))
  ;; (= bPointLight (* bSceneFaceColors 
  ;;   (sum lightIndex 1 (length bPointLights) 
  ;;     (* ([] bPointLights lightIndex) (/ (max 0 (dotNormalized
  ;;       xFaceNormals yFaceNormals zFaceNormals
  ;;       (- ([] xPointLights lightIndex) xMeans) (- ([] yPointLights lightIndex) yMeans) (- ([] zPointLights lightIndex) zMeans)
  ;;     )) (mag3DSq (- ([] xPointLights lightIndex) xMeans) (- ([] yPointLights lightIndex) yMeans) (- ([] zPointLights lightIndex) zMeans))))
  ;;   )
  ;; ))


  ;; (= rPointLight1 (* gSceneFaceColors ([] pointLight1Color 1) pointLight1Brightness))
  ;; (= gPointLight1 (* gSceneFaceColors ([] pointLight1Color 2) pointLight1Brightness))
  ;; (= bPointLight1 (* bSceneFaceColors ([] pointLight1Color 3) pointLight1Brightness))
  ;; (= rPointLight2 (* gSceneFaceColors ([] pointLight2Color 1) pointLight2Brightness))
  ;; (= gPointLight2 (* gSceneFaceColors ([] pointLight2Color 2) pointLight2Brightness))
  ;; (= bPointLight2 (* bSceneFaceColors ([] pointLight2Color 3) pointLight2Brightness))

  ; Calculate colors
  (= colors 
    ([]
      (rgb 
        ;rSceneFaceColors
        ;gSceneFaceColors
        ;bSceneFaceColors
        (mixClampAbove rSceneFaceColors ([] fadeColor 1) (/ SceneDepths 18))
        (mixClampAbove gSceneFaceColors ([] fadeColor 2) (/ SceneDepths 18))
        (mixClampAbove bSceneFaceColors ([] fadeColor 3) (/ SceneDepths 18))
        ;(mixClampAbove (+ rPointLight1 rPointLight2 (* rSceneFaceColors 0.15)) ([] fadeColor 1) (/ SceneDepths 18))
        ;(mixClampAbove (+ gPointLight1 gPointLight2 (* gSceneFaceColors 0.15)) ([] fadeColor 2) (/ SceneDepths 18))
        ;(mixClampAbove (+ bPointLight1 bPointLight2 (* bSceneFaceColors 0.15)) ([] fadeColor 3) (/ SceneDepths 18))
      )
      ScenePolygonFilter
    )
  )

  (displayMe
    (polygon (point -100 -100) (point 100 -100) (point 100 100) (point -100 100))
    (colorLatex (rgb ([] fadeColor 1) ([] fadeColor 2) ([] fadeColor 3)))
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
  (= cameraPos (list -3.4 -0.3 1.6))
  (= idealCameraPos (+ planePos (getSingleRotatedByMatrix (list 0 0.08 -0.6) invCameraMatrix)))

  (= lightDir 0.8)
  (= yaw 3.5)
  (= pitch 0)
  (= roll 0)
  (= planePos (list -3.4 -0.3 1.20))
  (= prevPlanePos (list -3.4 -0.3 1.20))

  (= collisionPlanePos (list -3.4 -0.3 1.20))
  (= collisionPrevPlanePos (list -3.4 -0.3 1.20))

  (= planeVel (list 0 0 0))
  (= planeSpeed (+ 0.00000001 (mag3D ([] planeVel 1) ([] planeVel 2) ([] planeVel 3))))
  
  (= planeUpDir (getSingleRotatedByMatrix (list 0 1 0) AirplaneModelMatrix))
  (= planeForwardDir (getSingleRotatedByMatrix (list 0 0 1) AirplaneModelMatrix))
  (= planeRightDir (getSingleRotatedByMatrix (list 1 0 0) AirplaneModelMatrix))
  (= planeWingNormal planeUpDir)
  (= flowDirection (* -1 planeVel))
  (= aerodynamicForceAgainstWing (* (dotVec3 planeUpDir flowDirection) 5 planeWingNormal))

  (= planeRudderNormal planeRightDir)
  (= aerodynamicForceAgainstRudder (* (dotVec3 planeRightDir flowDirection) 5 planeRudderNormal))


  (= gravity (list 0 -0.75 0))
  (= wrapCamera
    (
      ,
      (-> rotationView (point 0 0))
      (-> accumulatedCameraRotation (+ accumulatedCameraRotation (* 1.5 rotationView)))
    )
  )
  (= crashed 0)
  (= globalTime 0)
  (fn doPlanePhysicsStep deltaTime (
    piecewise
      ((== crashed 0)(,
        ; Move plane
        (-> framesPerSecond (/ 1 deltaTime))
        (-> accumulatedTime (+ accumulatedTime deltaTime))
        (-> planePos (+ planePos (* deltaTime planeVel)))
        (-> prevPlanePos planePos)
        ; Forces acting on plane
        (-> planeVel (+ (* (^ 0.99 deltaTime) planeVel) (* deltaTime (+ gravity aerodynamicForceAgainstWing aerodynamicForceAgainstRudder))))
        ; Control plane directions
        (-> yaw (+ yaw (* (* -1.25 deltaTime) (.x rotationJoystick))))
        (-> pitch (+ pitch (* (* 1.25 deltaTime) (.y rotationJoystick))))
        ; Test for crash
        (piecewise
          (
            (> (length 
              ([] intersections (< 0 intersections (* 1 (distance3D collisionPlanePos collisionPrevPlanePos))))
            ) 0)
            (,
              (-> crashed 1)
            )
          )
        )
        (piecewise
          ((== (mod globalTime 10) 0)
            (,
              (-> collisionPrevPlanePos collisionPlanePos)
              (-> collisionPlanePos planePos)
            )
          )
        )
        ; Move camera
        (-> cameraPos (mix idealCameraPos cameraPos (^ 0.05 deltaTime)))
        ; add to global time
        (-> globalTime (+ globalTime 1))
        (piecewise ((== (mod globalTime 30) 0) (-> planePosForTerrainSlots planePos)))
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
    (rayTriangleIntersectionList collisionPrevPlanePos (normalizeVec3 (- collisionPlanePos collisionPrevPlanePos)) (x3 TerrainWorldSpace) (y3 TerrainWorldSpace) (z3 TerrainWorldSpace) TerrainIndexBuffer)
  )

  (= framesPerSecond 0)
  (= accumulatedTime 0)
)

(= avgFPS (/ globalTime accumulatedTime))

(ticker (doPlanePhysicsStep (/ dt 1000)))


