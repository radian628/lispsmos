; Configure procedural/action code
(procedureConfig
  (desmosEntryPoint main)
  (pointerStack ps)
  (programCounter pc)
)

(inlineJS "
compiler.macroState.desmosPlane = {};
return [];
")

(evalMacro withAssetPath
  "
  let url = '\u0022http://localhost:8080/desmos-plane/assets/' + args[2].slice(1, args[2].length-1) + '\u0022';
  console.log(url);
  return [[args[1], url, args[3]]];
  "
)
(evalMacro withRootPath
  "
  let url = '\u0022http://localhost:8080/desmos-plane/' + args[2].slice(1, args[2].length-1) + '\u0022';
  console.log(url);
  return [[args[1], url, args[3]]];
  "
)

(folder ((title "PLY Stuff"))
  (defineFindAndReplace PLYGet fileVar elementType propertyType
    ((concatTokens fileVar ELEM elementType PROP propertyType))
  )

  (withAssetPath importPLY "menu_scene.ply" MenuScene)
  (= MenuSceneViewbox (withAssetPath importPLYBounds "menu_scene_viewbox.ply"))
  (= MenuSceneViewboxAvgPos (averagePLYPos MenuScene))
  (getFaceColors MenuScene)

  (withAssetPath importPLY "better_airplane.ply" Airplane)
  (withAssetPath importPLY "canyon_1.ply" Terrain1)
  (withAssetPath importPLY "canyon_2.ply" Terrain2)
  (withAssetPath importPLY "canyon_3.ply" Terrain3)
  (withAssetPath importPLY "canyon_4.ply" Terrain4)
  (withAssetPath importPLY "canyon_5.ply" Terrain5)
  (withAssetPath importPLY "canyon_6.ply" Terrain6)
  (withAssetPath importPLY "canyon_7.ply" Terrain7)
  (withAssetPath importPLY "canyon_8.ply" Terrain8)
  (withAssetPath importPLY "canyon_9.ply" Terrain9)
  (= Terrain1Viewbox (withAssetPath importPLYBounds "canyon_1_viewbox.ply"))
  (= Terrain2Viewbox (withAssetPath importPLYBounds "canyon_2_viewbox.ply"))
  (= Terrain3Viewbox (withAssetPath importPLYBounds "canyon_3_viewbox.ply"))
  (= Terrain4Viewbox (withAssetPath importPLYBounds "canyon_4_viewbox.ply"))
  (= Terrain5Viewbox (withAssetPath importPLYBounds "canyon_5_viewbox.ply"))
  (= Terrain6Viewbox (withAssetPath importPLYBounds "canyon_6_viewbox.ply"))
  (= Terrain7Viewbox (withAssetPath importPLYBounds "canyon_7_viewbox.ply"))
  (= Terrain8Viewbox (withAssetPath importPLYBounds "canyon_8_viewbox.ply"))
  (= Terrain9Viewbox (withAssetPath importPLYBounds "canyon_9_viewbox.ply"))
  (= SunOccluder1 (withAssetPath importPLYBounds "sun_occluder_1.ply"))
  ;(= PointLight1 (withAssetPath importPLYStats "point_light_1.ply"))
  (getFaceColors Airplane)
  (getFaceColors Terrain1)
  (getFaceColors Terrain2)
  (getFaceColors Terrain3)
  (getFaceColors Terrain4)
  (getFaceColors Terrain5)
  (getFaceColors Terrain6)
  (getFaceColors Terrain7)
  (getFaceColors Terrain8)
  (getFaceColors Terrain9)

  (withAssetPath importPLY "star.ply" Star)
  (getFaceColors Star)
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
  ;; (evalMacro addTerrainSlotOpacities "
  ;;   let terrains = args[1];
  ;;   let index = args[2];
  ;;   let result = terrains.map((terrain, i) => {
  ;;     return [['=', 'terrainSlot'+index+'ToLoad', (i+1).toString()], ['min', '1', ['max', '0', ['*', ['distanceInsideBox', 'playerPos', terrain + 'Viewbox'], '0.3']]]]
  ;;   });
  ;;   return result;
  ;; ")
  (defineFindAndReplace createTerrainSlot i terrains
    (
      (= (concatTokens terrainDistsSlot i) (list 
        (addTerrainSlotAverages terrains)
      ))
      (= (concatTokens terrainSlot i ToLoad) 
        (piecewise
          (determineTerrainSlotToLoad terrains)
          (-1)
        )
      )
      (= (concatTokens xTerrainSlot i) (piecewise 
        (addTerrainSlotProperties vertex x terrains i)
        ((list))
      ))
      (= (concatTokens yTerrainSlot i) (piecewise 
        (addTerrainSlotProperties vertex y terrains i)
        ((list))
      ))
      (= (concatTokens zTerrainSlot i) (piecewise 
        (addTerrainSlotProperties vertex z terrains i)
        ((list))
      ))
      (= (concatTokens rTerrainSlot i) (piecewise 
        (addTerrainSlotProperties face red terrains i)
        ((list))
      ))
      (= (concatTokens gTerrainSlot i) (piecewise 
        (addTerrainSlotProperties face green terrains i)
        ((list))
      ))
      (= (concatTokens bTerrainSlot i) (piecewise 
        (addTerrainSlotProperties face blue terrains i)
        ((list))
      ))
      (= (concatTokens iTerrainSlot i) (piecewise 
        (addTerrainSlotProperties face vertexunderscoreindices terrains i)
        ((list))
      ))
    )
  )
  (createTerrainSlot 1 (MenuScene Terrain1 Terrain4 Terrain7))
  (createTerrainSlot 2 (Terrain2 Terrain5 Terrain8))
  (createTerrainSlot 3 (Terrain3 Terrain6 Terrain9))
  (= planePosForTerrainSlots (list -0 -0 0))


  ; fade color
  (= sunOcclusionFactor  (piecewise
    ((== (isInsideViewbox planePos SunOccluder1) 1) 
    (min (max (* 0.3 (distanceInsideBox planePos SunOccluder1)) 0) 1))
    (0)))
  (= fadeColor 
    (mix
      (list 160 200 255)
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
  ;; (= AirplaneModelMatrix (mat3Multiply
  ;;   ;; (mat3Multiply
  ;;   ;;   (rotateAboutZAxis roll)
  ;;   ;; )
  ;;   (rotateAboutXAxis pitch)
  ;;   (rotateAboutYAxis yaw)
  ;; ))
  ;; (getRotatedByMatrixAndThenTranslate AirplaneModelSpace AirplaneWorldSpace AirplaneModelMatrix ([] planePos 1) ([] planePos 2) ([] planePos 3))
  (mat3WithoutListFromRollPitchYaw AirplaneModelMatrix 0 yaw pitch)
  (getRotatedByMatrixWithoutListAndThenTranslate AirplaneModelSpace AirplaneWorldSpace AirplaneModelMatrix ([] planePos 1) ([] planePos 2) ([] planePos 3)) 


  ; Transform star (TODO: FIX ROTATION)
  (defineXYZ StarModelSpace ;(PLYGet Star vertex x) (PLYGet Star vertex y) (PLYGet Star vertex z)
    (+ (* (cos (* 3.3 accumulatedTime)) (PLYGet Star vertex x)) (* (sin (* 3.3 accumulatedTime)) (PLYGet Star vertex z)))
    (PLYGet Star vertex y)
    (+ (* -1 (sin (* 3.3 accumulatedTime)) (PLYGet Star vertex x)) (* (cos (* 3.3 accumulatedTime)) (PLYGet Star vertex z)))
  )
  ;(= starMeshPos (list 5 -2.5 0))
  (getTranslated StarModelSpace StarWorldSpace ([] starMeshPos 1) ([] starMeshPos 2) ([] starMeshPos 3))


  ; Combine terrain data
  (join3D TerrainWorldSpace TerrainSlot1 TerrainSlot2 TerrainSlot3)
  (= rTerrain (join rTerrainSlot1 rTerrainSlot2 rTerrainSlot3))
  (= gTerrain (join gTerrainSlot1 gTerrainSlot2 gTerrainSlot3))
  (= bTerrain (join bTerrainSlot1 bTerrainSlot2 bTerrainSlot3))
  (= TerrainIndexBuffer (join
    iTerrainSlot1
    (+ iTerrainSlot2 (length xTerrainSlot1))
    (+ iTerrainSlot3 (length xTerrainSlot1) (length xTerrainSlot2))
  )
  )

  ; Combine both into single VBO, IndexBuffer, and Face Color Buffer
  (join3D VBOWorldSpace AirplaneWorldSpace TerrainWorldSpace StarWorldSpace)
  (= IndexBuffer (join 
    AirplaneELEMfacePROPvertexunderscoreindices
    (+ TerrainIndexBuffer (length (PLYGet Airplane vertex x)))
    (+ StarELEMfacePROPvertexunderscoreindices (length (PLYGet Airplane vertex x)) (length (x3 TerrainWorldSpace)))
  ))
  (= rSceneFaceColors (join 
    (PLYGet Airplane face red)  
    rTerrain 
    (PLYGet Star face red)
  ))
  (= gSceneFaceColors (join 
    (PLYGet Airplane face green) 
    gTerrain 
    (PLYGet Star face green)
  ))
  (= bSceneFaceColors (join 
    (PLYGet Airplane face blue) 
    bTerrain 
    (PLYGet Star face blue)
  ))

  ; View space to camera space to 2D on the VBO
  (getTranslatedAndThenRotateByMatrix VBOWorldSpace VBOCameraSpace cameraMatrix (* -1 ([] cameraPos 1)) (* -1 ([] cameraPos 2)) (* -1 ([] cameraPos 3)))
  ;(getTranslated VBOWorldSpace VBOCameraSpace (* -1 ([] cameraPos 1)) (* -1 ([] cameraPos 2)) (* -1 ([] cameraPos 3)))
  (= cameraMatrix (mat3Multiply (rotateAboutYAxis (* -1 (.x cameraRotation))) (rotateAboutXAxis (* -1 (.y cameraRotation)))))
  (= invCameraMatrix (mat3Multiply (rotateAboutXAxis (* 1 (.y cameraRotation))) (rotateAboutYAxis (* 1 (.x cameraRotation)))))
  (= vboProjected (join (project3DTranslated (x3 VBOCameraSpace) (y3 VBOCameraSpace) (z3 VBOCameraSpace)) (point (/ 0 0) (/ 0 0))))
  ; Calculations for polygon ordering and culling.
  (= SceneDepths (getIndexedDepths (x3 VBOCameraSpace) (y3 VBOCameraSpace) (z3 VBOCameraSpace) IndexBuffer))
  (= ScenePolygonOrdering (getPolygonOrdering SceneDepths))
  (= ScenePolygonFilter ([] ScenePolygonOrdering (> (getCullingInformation vboProjected (z3 VBOCameraSpace) IndexBuffer ScenePolygonOrdering 324) 0)))


  ; Calculate colors
  (= normalizedSceneDepths (/ SceneDepths 324))
  (= colors 
    ([]
      (rgb 
       (mixClampAbove rSceneFaceColors ([] fadeColor 1) (* normalizedSceneDepths normalizedSceneDepths))
       (mixClampAbove gSceneFaceColors ([] fadeColor 2) (* normalizedSceneDepths normalizedSceneDepths))
       (mixClampAbove bSceneFaceColors ([] fadeColor 3) (* normalizedSceneDepths normalizedSceneDepths))
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


  ; Graphics-related, plane, and collision
  (= cameraPos (list 0 0.1 1))
  (= idealCameraPos (+ planePos (getSingleRotatedByMatrix (list 0 0.06 -0.45) invCameraMatrix)))

  (= lightDir 0.8)
  (= yaw 4.33)
  (= pitch 0)
  (= roll 0)
  (= planePos (list 0 0 0))
  (= prevPlanePos (list 0 0 0))

  (= collisionPlanePos (list 0 0 0))
  (= collisionPrevPlanePos (list 0 0 0))

  ;(= cameraMatrix mat3Identity)

  (= planeVel (list 0 0 0))
  (= planeSpeed (+ 0.00000001 (mag3D ([] planeVel 1) ([] planeVel 2) ([] planeVel 3))))
  
  ;(= planeUpDir (getSingleRotatedByMatrix (list 0 1 0) AirplaneModelMatrix))
  ;(= planeForwardDir (getSingleRotatedByMatrix (list 0 0 1) AirplaneModelMatrix))
  ;(= planeRightDir (getSingleRotatedByMatrix (list 1 0 0) AirplaneModelMatrix))
  (= planeUpDir (list AirplaneModelMatrix4 AirplaneModelMatrix5 AirplaneModelMatrix6))
  (= planeForwardDir (list AirplaneModelMatrix7 AirplaneModelMatrix8 AirplaneModelMatrix9))
  (= planeRightDir (list AirplaneModelMatrix1 AirplaneModelMatrix2 AirplaneModelMatrix3))
  (= planeWingNormal planeUpDir)
  (= flowDirection (* -1 planeVel))
  (= aerodynamicForceAgainstWing (* (dotVec3 planeUpDir flowDirection) 5 planeUpDir))

  ;(= planeRudderNormal planeRightDir)
  (= aerodynamicForceAgainstRudder (* (dotVec3 planeRightDir flowDirection) 5 planeRightDir))


  (= gravity (list 0 -0.75 0))
  (= crashed 0)
  (= menuState 1)
  (= globalTime 0)
  (fn doPlanePhysicsStep deltaTime (
    piecewise
      ((== crashed 0)(,

        ; Move plane
        (-> framesPerSecond (/ 1 deltaTime))
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
              (-> menuState MenuStateCrash)
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
        (-> cameraPos (mix idealCameraPos cameraPos (^ 0.01 deltaTime)))
        ; add to global time
        (-> globalTime (+ globalTime 1))
        (piecewise ((== (mod globalTime 32) 0) (,
          (-> planePosForTerrainSlots planePos)
          handleCheckpointCollision
          ;(-> accumulatedTime 0)
        ))
        )
        (-> accumulatedTime (+ accumulatedTime deltaTime))
        handleCheckpointAnimation
        checkCollisionWithStar
      ))
    )
  )
  (fn mainMenuPhysicsStep deltaTime
    (, 
      (-> planePos (+ 
        (list -50 -2 50) 
        (* 0.9 (list (cos (* 0.01 globalTime)) (* 0.02 (sin (* 0.026 globalTime))) (sin (* 0.01 globalTime))))
      ))
      (-> pitch 0)
      (-> yaw (+ 5.37 (* 0.01 globalTime)))
      (-> cameraPos (list -50 -1.9 50))
      (-> globalTime (+ globalTime 1))
      (piecewise ((== (mod globalTime 32) 0) 
          ((-> planePosForTerrainSlots planePos))
        )
      )
      (-> accumulatedTime (+ accumulatedTime deltaTime))
    )
  )

  (fn main deltaTime (,
    (piecewise 
      ((== menuState MenuStateMain) (mainMenuPhysicsStep deltaTime))
      ((== menuState MenuStateCheckpoints) (mainMenuPhysicsStep deltaTime))
      ((== menuState MenuStateGame) (doPlanePhysicsStep deltaTime))
      ((== menuState MenuStateStartGame) startGame)
    )
    (-> avgFPS (mix avgFPS (/ 1 deltaTime) 0.05))
  ))
  

  (displayMe
    (= rotationJoystick (point 0 0))
    (colorLatex (rgb 255 0 0))
    (pointOpacity 1)
  )
  
  ; View rotation
  (= accumulatedCameraRotation (point 0 0))
  ;(= cameraRotation (+ accumulatedCameraRotation (* 1.5 rotationView)))
  (= cameraRotation (point yaw (* -1 (- 0.1 pitch))))

  (= intersections 
    (rayTriangleIntersectionList collisionPrevPlanePos (normalizeVec3 (- collisionPlanePos collisionPrevPlanePos)) (x3 TerrainWorldSpace) (y3 TerrainWorldSpace) (z3 TerrainWorldSpace) TerrainIndexBuffer)
  )

  (= framesPerSecond 0)
  (= accumulatedTime 0)
)

(= avgFPS 0)

(withRootPath include "gui.lisp")

; checkpoint stuff. 
(folder ((title "Checkpoints"))
  (= startGame
    (,
      (-> crashed 0)
      (-> planePos startPosition)
      (-> planeVel startVelocity)
      (-> pitch startPitch)
      (-> yaw startYaw)
      (-> prevPlanePos startPosition)
      (-> collisionPlanePos startPosition)
      (-> collisionPrevPlanePos startPosition)
      (-> globalTime 0)
      (-> rotationJoystick (point 0 0))
      (-> menuState MenuStateGame)
    )
  )
  (fn replaceSingleListElem L i replacement
    (comprehension (piecewise ((== n i) replacement) (([] L n))) (n (list 1 ... (length L))))
  )
  (fn getNListElems L start n
    ([] L start ... (+ start n))
  )

  (inlineJS "
    compiler.macroState.desmosPlane.checkpointCount = 3;
    return [];
  ")

  (inlineJS "
    let result = [];
    for (let i = 1; i < compiler.macroState.desmosPlane.checkpointCount; i++) {
      let checkpointIndex = (i+1).toString();
      let baseFileName = `checkpoint_${checkpointIndex}`;
      let baseVarName = `Checkpoint${checkpointIndex}`;
      result.push(['=',`${baseVarName}Collider`, ['withAssetPath', 'importPLYBounds', `\u0022${baseFileName}_collider.ply\u0022`]])
      result.push(['=',`${baseVarName}Location`, ['withAssetPath', 'importPLYStats', `\u0022${baseFileName}_location.ply\u0022`]])
      result.push(['=', `${baseVarName}Velocity`, ['-', ['withAssetPath', 'importPLYStats', `\u0022${baseFileName}_velocity.ply\u0022`], `${baseVarName}Location`]])
    }
    return result;
  ")
  ;; (= Checkpoint2Collider (withAssetPath importPLYBounds "checkpoint_2_collider.ply"))
  ;; (= Checkpoint2Location (withAssetPath importPLYStats "checkpoint_2_location.ply"))
  ;; (= Checkpoint2Velocity (- (withAssetPath importPLYStats "checkpoint_2_velocity.ply") Checkpoint2Location))
  ;(= Checkpoint3Collider (withAssetPath importPLYBounds "checkpoint_3_collider.ply"))
  ;(= Checkpoint3Location (withAssetPath importPLYStats "checkpoint_3_location.ply"))
  ;(= Checkpoint3Velocity (- (withAssetPath importPLYStats "checkpoint_3_velocity.ply") Checkpoint3Location))
  (defineFindAndReplace getCheckpointDataLists index
    (([] (concatTokens Checkpoint index Location) 1 ... 3)
    ([] (concatTokens Checkpoint index Velocity) 1 ... 3)
    (arctan ([] (concatTokens Checkpoint index Velocity) 2) (mag ([] (concatTokens Checkpoint index Velocity) 1) ([] (concatTokens Checkpoint index Velocity) 3)))
    (arctan ([] (concatTokens Checkpoint index Velocity) 1) ([] (concatTokens Checkpoint index Velocity) 3)))
  )
  (= checkpointData (join 
    (list 0 0 0 0 0 0 0 4.33)
    (getCheckpointDataLists 2)
    (getCheckpointDataLists 3)
  ))
  (= handleCheckpointAnimation (,
    (piecewise
      ((== checkpointAnimationStage 1) (,
        (-> checkpointNotifierOpacity (+ checkpointNotifierOpacity 0.04))
        (piecewise ((> checkpointNotifierOpacity 2.5) (-> checkpointAnimationStage 2)))
      ))
      ((== checkpointAnimationStage 2) (,
        (-> checkpointNotifierOpacity (- checkpointNotifierOpacity 0.02))
        (piecewise ((< checkpointNotifierOpacity 0) (-> checkpointAnimationStage 0)))
      ))
    )
  ))
  (= handleCheckpointCollision (,
    (piecewise ((== ([] checkpointsVisited 2) 0)
      (piecewise ((== (isInsideViewbox collisionPlanePos Checkpoint2Collider) 1) (,
        ;; (-> activeCheckpoint 1)
        (-> checkpointAnimationStage 1)
        (-> checkpointsVisited (replaceSingleListElem checkpointsVisited 2 1))
        (setActiveCheckpoint 2)
        ;; (-> startPosition ([] Checkpoint1Location 1 ... 3))
        ;; (-> startVelocity ([] Checkpoint1Velocity 1 ... 3) )
        ;; (-> startPitch (arctan ([] Checkpoint1Velocity 2) (mag ([] Checkpoint1Velocity 1) ([] Checkpoint1Velocity 3))))
        ;; (-> startYaw (arctan ([] Checkpoint1Velocity 1) ([] Checkpoint1Velocity 3)))
      )))
    ))
  ))
  (fn setActiveCheckpoint i 
    (,
      (-> activeCheckpoint i)
      (-> startPosition (getNListElems checkpointData (+ -7 (* i 8)) 3))
      (-> startVelocity (getNListElems checkpointData (+ -4 (* i 8)) 3))
      (-> startPitch ([] (getNListElems checkpointData (+ -1 (* i 8)) 1) 1))
      (-> startYaw ([] (getNListElems checkpointData (+ 0 (* i 8)) 1) 1))
    )
  )
  ; 0=not visited, 1=visited
  (= startPosition (list -0 0 0))
  (= startVelocity (list 0 0 0))
  (= startPitch 0)
  (= startYaw 4.33)
  (= checkpointsVisited (list 1 0 0))
  (= checkpointAnimationStage 0)
  (= checkpointNotifierOpacity 0)
  (= activeCheckpoint 1)
  (displayMe 
    (= checkpointNotifier (point 0 0.3))
    (colorLatex (rgb 255 255 255))
    (label "Checkpoint ${a_{ctiveCheckpoint}} Reached")
    (pointOpacity checkpointNotifierOpacity)
    (labelSize 4)
    (hidden true)
    (showLabel true)
    (suppressTextOutline true)
  )
)

(inlineJS  "
  compiler.macroState.desmosPlane.starCount = 2;
  return [];
")
(folder ((title "Stars"))
  ;(= Star1Location (withAssetPath importPLYStats "star_1_location.ply"))
  (= Star1Viewbox (withAssetPath importPLYBounds "star_1_viewbox.ply"))

  (= starLocations (join
    (inlineJS
      "
        let ast = [];
        for (let i = 0; i < compiler.macroState.desmosPlane.starCount; i++) {
          ast.push(
            ['[]', ['withAssetPath', 'importPLYStats', '\u0022star_'+(i+1)+'_location.ply\u0022'], '1', '...', '3']
          )
        }
        return ast;
      "
    )
    ;; ([] Star1Location 1 ... 3)
    (list)
  ))

  (= currentStarIndex (piecewise
    (inlineJS
      "
        let ast = [];
        for (let i = 0; i < compiler.macroState.desmosPlane.starCount; i++) {
          ast.push(
            [['==', ['isInsideViewbox', 'planePosForTerrainSlots', ['withAssetPath', 'importPLYBounds', '\u0022star_'+(i+1)+'_viewbox.ply\u0022']], '1'], (i+1).toString()]
          )
        }
        return ast;
      "
    )
    ;((== (isInsideViewbox planePosForTerrainSlots Star1Viewbox) 1) 1)
    (0)
  ))
  (= starMeshPos (piecewise
    ((== ([] starsFound currentStarIndex) 1) (list (/ 0 0) 0 0))
    ((getNListElems starLocations (- (* 3 currentStarIndex) 2) 3))
  ))
  (= checkCollisionWithStar (piecewise
    ((< (distance3D planePos starMeshPos) 1) (-> starsFound (replaceSingleListElem starsFound currentStarIndex 1)))
  ))

  (= starsFound (list 0 0))
)
;(= inlineJSTest (inlineJS "return [['+', '1', '1']]"))

(ticker (main (min 0.1 (/ dt 1000)))
