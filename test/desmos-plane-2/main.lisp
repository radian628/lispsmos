(include "http://localhost:8080/desmos-plane-2/import-helpers.lisp")
(include "http://localhost:8080/desmos-plane-2/linalg.lisp")
(viewport -2 2 -2 2)


(defineFindAndReplace x3 varName
  ((concatTokens x varName))
)
(defineFindAndReplace y3 varName
  ((concatTokens y varName))
)
(defineFindAndReplace z3 varName
  ((concatTokens z varName))
)
(defineFindAndReplace staticVec3 varName xval yval zval
  ((= (x3 varName) xval)
  (= (y3 varName) yval)
  (= (z3 varName) zval))
)

(defineFindAndReplace staticVec3Copy dstVarName srcVarName
  (
    (= (x3 dstVarName) (x3 srcVarName))
    (= (y3 dstVarName) (y3 srcVarName))
    (= (z3 dstVarName) (z3 srcVarName))
  )
)
(defineFindAndReplace staticVec3Spread varName
  ((x3 varName) (y3 varName) (z3 varName))
)



(folder ((title "Camera Trig"))
  
  ; camera rotation
  (= xContribToX (* (cos xViewRotation)))
  (= yContribToX 0)
  (= zContribToX (* (sin xViewRotation)))

  (= xContribToY (* (sin yViewRotation) (sin xViewRotation)))
  (= yContribToY (* (cos yViewRotation)))
  (= zContribToY (* -1 (sin yViewRotation) (cos xViewRotation)))

  (= xContribToZ (* -1 (sin xViewRotation) (cos yViewRotation)))
  (= yContribToZ (* (sin yViewRotation)))
  (= zContribToZ (* (cos xViewRotation) (cos yViewRotation)))

  (= xViewRotationReverse (* -1 xViewRotation))
  (= yViewRotationReverse (* -1 yViewRotation))

  (defineFindAndReplace xContribToXReverse (xContribToX))
  (defineFindAndReplace yContribToXReverse (xContribToY))
  (defineFindAndReplace zContribToXReverse (xContribToZ))

  (defineFindAndReplace xContribToYReverse (yContribToX))
  (defineFindAndReplace yContribToYReverse (yContribToY))
  (defineFindAndReplace zContribToYReverse (yContribToZ))

  (defineFindAndReplace xContribToZReverse (zContribToX))
  (defineFindAndReplace yContribToZReverse (zContribToY))
  (defineFindAndReplace zContribToZReverse (zContribToZ))
)

(folder ((title "Graphics"))
  ; import
  (withRootPath importPLY "canyon_1.ply" Terrain1)
  (withRootPath importPLY "canyon_2.ply" Terrain2)
  ;; (withRootPath importPLY "canyon_2.ply" Terrain3)
  ;; (withRootPath importPLY "canyon_2.ply" Terrain4)
  ;; (withRootPath importPLY "canyon_2.ply" Terrain5)
  ;; (withRootPath importPLY "canyon_2.ply" Terrain6)
  ;; (withRootPath importPLY "canyon_2.ply" Terrain7)
  ;; (withRootPath importPLY "canyon_2.ply" Terrain8)
  ;; (withRootPath importPLY "canyon_2.ply" Terrain9)
  ;; (withRootPath importPLY "canyon_2.ply" Terrain10)
  ;; (withRootPath importPLY "canyon_2.ply" Terrain11)
  ;; (withRootPath importPLY "canyon_2.ply" Terrain12)
  (inlineJS "
  
    let testLists = [];
    for (let i = 0; i < 10; i++) {
      let newList = ['list'];
      for (let j = 0; j < 10000; j++) {
        newList.push(Math.random().toString());
      }
      testLists.push(['=', 'testList'+i, newList]);
    }
    return testLists;
  ")
  (getFaceColors Terrain1)
  (getFaceColors Terrain2)
  ; (defineFindAndReplace TerrainIBO ((PLYGet Terrain face vertexunderscoreindices)))
  (fn TerrainIBO (PLYGet Terrain1 face vertexunderscoreindices))
  (= xVBO (PLYGet Terrain1 vertex x))
  (= yVBO (PLYGet Terrain1 vertex y))
  (= zVBO (PLYGet Terrain1 vertex z))
  (= rVBO (PLYGet Terrain1 face red))
  (= gVBO (PLYGet Terrain1 face green))
  (= bVBO (PLYGet Terrain1 face blue))

  ; world space to view space intermediate
  (= xVBOViewSpaceIntermediate1 (- xVBO xViewPosition))
  (= yVBOViewSpaceIntermediate1 (- yVBO yViewPosition))
  (= zVBOViewSpaceIntermediate1 (- zVBO zViewPosition))


  (= VBOIndexingListLength (floor (/ (length (TerrainIBO)) 3)))
  (= listCompIndexingListForVBO (* 3 (list 1 ... VBOIndexingListLength)))

  (= xVBOViewSpace (+ (* xVBOViewSpaceIntermediate1 xContribToX) (* yVBOViewSpaceIntermediate1 yContribToX) (* zVBOViewSpaceIntermediate1 zContribToX)))
  (= yVBOViewSpace (+ (* xVBOViewSpaceIntermediate1 xContribToY) (* yVBOViewSpaceIntermediate1 yContribToY) (* zVBOViewSpaceIntermediate1 zContribToY)))
  (= zVBOViewSpace (+ (* xVBOViewSpaceIntermediate1 xContribToZ) (* yVBOViewSpaceIntermediate1 yContribToZ) (* zVBOViewSpaceIntermediate1 zContribToZ)))
  

  ; projection
  (fn project x y z
    (piecewise 
      ((> z 0) (point (/ x z) (/ y z)))
      ((* 1000 (point x y)))
    )
  )
  (= VBOScreenSpace (project xVBOViewSpace yVBOViewSpace zVBOViewSpace))


  ; depth sorting and backface culling
  (fn magnitudeSquared x y z (+ (* x x) (* y y) (* z z)))
  (fn magnitude x y z (sqrt (+ (* x x) (* y y) (* z z))))
  (fn distance x1 y1 z1 x2 y2 z2 (magnitude (- x1 x2) (- y1 y2) (- z1 z2)))
  (fn windingOrderContribution p1 p2 (* (- (.x p2) (.x p1)) (+ (.y p2) (.y p1))))
  (= VBOViewSpaceDepths 
    (comprehension
      (piecewise 
        ((<
          (+
            (windingOrderContribution ([] VBOScreenSpace ([] (TerrainIBO) (+ n 1))) ([] VBOScreenSpace ([] (TerrainIBO) (+ n 2))))
            (windingOrderContribution ([] VBOScreenSpace ([] (TerrainIBO) (+ n 2))) ([] VBOScreenSpace ([] (TerrainIBO) (+ n 3))))
            (windingOrderContribution ([] VBOScreenSpace ([] (TerrainIBO) (+ n 3))) ([] VBOScreenSpace ([] (TerrainIBO) (+ n 1))))
          )
          0
        ) -1) 
        ((< 
          (max
            ([] zVBOViewSpace ([] (TerrainIBO) (+ n 1)))
            ([] zVBOViewSpace ([] (TerrainIBO) (+ n 2)))
            ([] zVBOViewSpace ([] (TerrainIBO) (+ n 3)))
          )
          0
        ) -1)
        (
          (+
            (magnitudeSquared
              ([] xVBOViewSpace ([] (TerrainIBO) (+ n 1)))
              ([] yVBOViewSpace ([] (TerrainIBO) (+ n 1)))
              ([] zVBOViewSpace ([] (TerrainIBO) (+ n 1)))
            )
            (magnitudeSquared
              ([] xVBOViewSpace ([] (TerrainIBO) (+ n 2)))
              ([] yVBOViewSpace ([] (TerrainIBO) (+ n 2)))
              ([] zVBOViewSpace ([] (TerrainIBO) (+ n 2)))
            )
            (magnitudeSquared
              ([] xVBOViewSpace ([] (TerrainIBO) (+ n 3)))
              ([] yVBOViewSpace ([] (TerrainIBO) (+ n 3)))
              ([] zVBOViewSpace ([] (TerrainIBO) (+ n 3)))
            )
          )
        )
      )
      (n (- listCompIndexingListForVBO 3))
    )
  )

  ; Defining a filter for VBO faces
  (= VBOFaceFilter
    (sort 
      ([] (list 1 ... VBOIndexingListLength) (> VBOViewSpaceDepths 0))
      (* -1 ([] VBOViewSpaceDepths (> VBOViewSpaceDepths 0)))
    )
  )

  (displayMe
    (polygon
      (point -4 4)
      (point 4 4)
      (point 4 -4)
      (point -4 -4)
    )
    (colorLatex (rgb 200 200 255))
    (fillOpacity 1)
  )

  ; Display terrain VBO
  (displayMe
    ([] (comprehension
      (polygon 
        ([] VBOScreenSpace ([] (TerrainIBO) (+ n 1)))
        ([] VBOScreenSpace ([] (TerrainIBO) (+ n 2)))
        ([] VBOScreenSpace ([] (TerrainIBO) (+ n 3)))
      )
      (n (- listCompIndexingListForVBO 3))
    ) VBOFaceFilter)
    (colorLatex (
      []
      (rgb 
        rVBO
        gVBO
        bVBO 
      )  
      VBOFaceFilter
    ))
    (lines false)
    (fillOpacity 1)
  )
)



(folder ((title "Player & Physics"))
  ; canonical player state
  (staticVec3 PlayerPosition 0 0 -1)
  (staticVec3 PlayerVelocity 0 0 0)
  (= playerSpeed (sqrt 
    (magnitudeSquared (x3 PlayerVelocity) (y3 PlayerVelocity) (z3 PlayerVelocity)
  )))

  (staticVec3Copy ViewPosition PlayerPosition)
  
  (= xPlayerRotation -1.5)
  (= yPlayerRotation -0.1)
  (= xViewRotation xPlayerRotation)
  (= yViewRotation yPlayerRotation)

  (= forceAgainstWingMag
    (* -7 (staticDot 
      (staticVec3Spread PlayerVelocity) (yContribToXReverse) (yContribToYReverse) (yContribToZReverse)
    ))
  )
  (= forceAgainstRudderMag
    (* -7 (staticDot 
      (staticVec3Spread PlayerVelocity) (xContribToXReverse) (xContribToYReverse) (xContribToZReverse)
    ))
  )
  (= xForceOnPlayer
    (+
      (* forceAgainstWingMag (yContribToXReverse))
      (* forceAgainstRudderMag (xContribToXReverse))
    )
  )
  (= yForceOnPlayer
    (+
      (* forceAgainstWingMag (yContribToYReverse))
      (* forceAgainstRudderMag (xContribToYReverse))
      -0.75
    )
  )
  (= zForceOnPlayer
    (+
      (* forceAgainstWingMag (yContribToZReverse))
      (* forceAgainstRudderMag (xContribToZReverse))
    )
  )

  ;; (= playerPositionForCollisions (list 0 0 0))
  ;; (= previousPlayerPositionForCollisions (list 0 0 0))
  (staticVec3 PlayerPositionCollisions 0 0 0)
  (staticVec3 PrevPlayerPositionCollisions 0 0 0)
  (= ppcOffsetMag (distance 
    (staticVec3Spread PlayerPositionCollisions)
    (staticVec3Spread PrevPlayerPositionCollisions)
  ))
  (staticVec3 PlayerCollisionRaycastVector 
    (/ (- (x3 PlayerPositionCollisions) (x3 PrevPlayerPositionCollisions)) ppcOffsetMag)
    (/ (- (y3 PlayerPositionCollisions) (y3 PrevPlayerPositionCollisions)) ppcOffsetMag)
    (/ (- (z3 PlayerPositionCollisions) (z3 PrevPlayerPositionCollisions)) ppcOffsetMag)
  )
  ;; (= triangleCollisions (
  ;;   mullerTrumbore
  ;;   (staticVec3Spread PrevPlayerPositionCollisions)
  ;;   (staticVec3Spread)
  ;; ))
  (= triangleCollisions
    (comprehension
      (mullerTrumbore
        (staticVec3Spread PrevPlayerPositionCollisions)
        (staticVec3Spread PlayerCollisionRaycastVector)

        ([] xVBO ([] (TerrainIBO) (+ n 1)))
        ([] yVBO ([] (TerrainIBO) (+ n 1)))
        ([] zVBO ([] (TerrainIBO) (+ n 1)))

        ([] xVBO ([] (TerrainIBO) (+ n 2)))
        ([] yVBO ([] (TerrainIBO) (+ n 2)))
        ([] zVBO ([] (TerrainIBO) (+ n 2)))

        ([] xVBO ([] (TerrainIBO) (+ n 3)))
        ([] yVBO ([] (TerrainIBO) (+ n 3)))
        ([] zVBO ([] (TerrainIBO) (+ n 3)))
      )
    (n (- listCompIndexingListForVBO 3)))
  )
  (= nearestTriangleCollision (min ([] triangleCollisions (> triangleCollisions 0))))
)

(folder ((title "Controls"))
  (= pcJoystickCenterOffset (point 0 0))
  (displayMe
    (= pcControlJoystick (point 0 0))
    (colorLatex (rgb 255 0 0))
  )
  (= pcJoystickDeltaRotation (* 1.5 (- pcControlJoystick pcJoystickCenterOffset)))
  (= joystickDeltaRotation pcJoystickDeltaRotation)
)

(folder ((title "Main Game Loop"))
  (= GAMESTATE_MAIN_MENU 0)
  (= GAMESTATE_GAME 1)
  (= GAMESTATE_CRASH 2)

  (= gameState GAMESTATE_GAME)

  (= frameCount 0)

  (fn gameLoop deltaTime
    (,
      (piecewise 
        ((= gameState GAMESTATE_GAME)
          (,
            (-> xPlayerRotation (- xPlayerRotation (* deltaTime (.x joystickDeltaRotation))))
            (-> yPlayerRotation (+ yPlayerRotation (* deltaTime (.y joystickDeltaRotation))))
            (-> averageDeltaTime (+ (* averageDeltaTime 0.97) (* (* deltaTime 1000) 0.03)))
            (-> (x3 PlayerVelocity) (+ (* (^ 0.9997 deltaTime) (x3 PlayerVelocity)) (* deltaTime (x3 ForceOnPlayer))))
            (-> (y3 PlayerVelocity) (+ (* (^ 0.9997 deltaTime) (y3 PlayerVelocity)) (* deltaTime (y3 ForceOnPlayer))))
            (-> (z3 PlayerVelocity) (+ (* (^ 0.9997 deltaTime) (z3 PlayerVelocity)) (* deltaTime (z3 ForceOnPlayer))))
            (-> (x3 PlayerPosition) (+ (x3 PlayerPosition) (* deltaTime (x3 PlayerVelocity))))
            (-> (y3 PlayerPosition) (+ (y3 PlayerPosition) (* deltaTime (y3 PlayerVelocity))))
            (-> (z3 PlayerPosition) (+ (z3 PlayerPosition) (* deltaTime (z3 PlayerVelocity))))
            (piecewise 
              ((== (mod frameCount 10) 0)
                (,
                  (piecewise (
                    (< nearestTriangleCollision ppcOffsetMag)
                    (-> gameState GAMESTATE_CRASH)
                  ))
                  (-> xPlayerPositionCollisions xPlayerPosition)
                  (-> yPlayerPositionCollisions yPlayerPosition)
                  (-> zPlayerPositionCollisions zPlayerPosition)
                  (-> xPrevPlayerPositionCollisions xPlayerPositionCollisions)
                  (-> yPrevPlayerPositionCollisions yPlayerPositionCollisions)
                  (-> zPrevPlayerPositionCollisions zPlayerPositionCollisions)
                )
              )
            )
          )
        )
      )
      (-> frameCount (+ frameCount 1))
    )
  )
)

(ticker (gameLoop (/ dt 1000)))
(= averageDeltaTime 0)

;; ([] triangleCollisions (> triangleCollisions 0))