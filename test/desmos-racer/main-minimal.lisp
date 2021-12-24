(setKeyValueStore 
  (sunPosition (list 3 5 -3))
)
(inlineJS "
  compiler.macroState.desmosPlane = {};
  return [];
")
(include "http://localhost:8080/desmos-plane-2/import-helpers.lisp")
(include "http://localhost:8080/desmos-plane-2/linalg.lisp")
(folder ((title "Init"))
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
)

(folder ((title "Camera Trig"))

  ; camera rotation
  (= cosXViewRotation (cos xViewRotation))
  (= sinXViewRotation (sin xViewRotation))
  (= cosYViewRotation (cos yViewRotation))
  (= sinYViewRotation (sin yViewRotation))
  (= xContribToX (* cosXViewRotation))
  (= yContribToX 0)
  (= zContribToX (* sinXViewRotation))

  (= xContribToY (* sinYViewRotation sinXViewRotation))
  (= yContribToY (* cosYViewRotation))
  (= zContribToY (* -1 sinYViewRotation cosXViewRotation))

  (= xContribToZ (* -1 sinXViewRotation cosYViewRotation))
  (= yContribToZ (* sinYViewRotation))
  (= zContribToZ (* cosXViewRotation cosYViewRotation))

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

(folder ((title "Bitwise Hacking"))
  (fn extractMantissaBits floatNum bitStart bitCount (
    ;sum k bitStart (+ bitStart bitCount)
    ;(* (^ 2 (- k bitStart)) (mod (floor (/ floatNum (^ 2 k))) 2))
    (mod (floor (/ floatNum (^ 2 bitStart))) (^ 2 bitCount))
  ))
)

(folder ((title "Graphics"))
  ; import
  (defineFindAndReplace TerrainVertexAttribInBufferCount ((ceil (/ ([] TerrainCompressed 1) 2))))
  (defineFindAndReplace TerrainColorInBufferCount ((ceil (/ ([] TerrainCompressed 2) 8))))
  (defineFindAndReplace TerrainIndexInBufferCount ((ceil (/ (* 3 ([] TerrainCompressed 2)) 5))))

  ;create VBO
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
  (withAssetPath importBakedLightSource "light_1.ply")
  (withAssetPath importBakedLightSource "light_2.ply")
  (inlineJS "
    let ast = [];

    let terrainSlotFiles = [
      ['menu_scene', 'canyon_1', 'canyon_4', 'canyon_7'],
      ['canyon_2', 'canyon_5', 'canyon_8'],
      ['canyon_3', 'canyon_6', 'canyon_9']
    ];

    ast.push(...terrainSlotFiles.flat(2).map(tsf => {
      return ['withAssetPath', 'makePLYAvailableToJS', `\u0022${tsf}.ply\u0022`, ['terrain']];
    }));

    let terrainData = [];

    let terrainCount = 1;
    for (let individualTerrainSlotFiles of terrainSlotFiles) {
      let terrainSlotData = [];
      for (let fileName of individualTerrainSlotFiles) {
        terrainSlotData.push({
          varName: 'Terrain' + terrainCount + 'Compressed',
          viewboxVarName: 'Terrain' + terrainCount + 'Viewbox',
          fileName: fileName + '.ply',
          viewboxFileName: fileName + '_viewbox.ply'
        });
        terrainCount++;
      }
      terrainData.push(terrainSlotData);
    }
    console.log(terrainData);

    for (let terrainDatum of terrainData.flat(1)) {
      ast.push(['=', terrainDatum.varName, [
        'withAssetPath', 'importCompressedPLY', `\u0022${terrainDatum.fileName}\u0022`
      ]]);
    }

    let prefixes = ['x', 'y', 'z', 'r', 'g', 'b'];

    for (let [i, terrainSegmentData] of terrainData.entries()) {
      let terrainSegmentChoiceExpression = ['=', `TerrainSlot${i+1}Choice`,
        ['piecewise', ...terrainSegmentData.map((terrainDatum, j) => {
          let viewboxGetter = [
            'withAssetPath', 'importPLYBounds', `\u0022${terrainDatum.viewboxFileName}\u0022`
          ];
          return [['>', ['isInsideViewbox', 'terrainLoadingViewerPosition', viewboxGetter], '0'], (j+1).toString()]
        }), ['0']]
      ];
      ast.push(terrainSegmentChoiceExpression);
    }

    function getTerrainSegmentChooser(terrainSlotData, prefix, i) {
      return [`${prefix}DecompressTerrainList`, ['piecewise', ...terrainSlotData.map((terrainSegmentData, j) => {
            return [['==', `TerrainSlot${i+1}Choice`, (j+1).toString()], terrainSegmentData.varName];
          }), [['list', '0', '0']]]]
    }

    for (let prefix of prefixes) {
      let vboPropertyAST = ['=', prefix+'VBO',
        ['join', ...(terrainData.map((terrainSlotData, i) => {
          return getTerrainSegmentChooser(terrainSlotData, prefix, i)
        }))]
      ];
      ast.push(vboPropertyAST);
    }
    let vboIndexAST = ['=', 'iVBO',
      ['join', ...(terrainData.map((terrainSlotData, i) => {
        let indexBufferOffsetters = [];
        for (let k = 0; k < i; k++) {
          indexBufferOffsetters.push(
            ['piecewise',
              ...terrainData[k].map((terrainSegmentData, j) => {
                return [['==', `TerrainSlot${k+1}Choice`, (j+1).toString()], ['[]', terrainSegmentData.varName, '1']];
              }),
              ['0']
            ]
          );
        }
        return ['+', getTerrainSegmentChooser(terrainSlotData, 'i', i), ...indexBufferOffsetters];
      }))]
    ];
    ast.push(vboIndexAST);

    return ast;
  ")

  ;(= xTerrainSlot1 (xDecompressTerrainList Terrain1Compressed))
  ;(= yTerrainSlot1 (yDecompressTerrainList Terrain1Compressed))
  ;(= zTerrainSlot1 (zDecompressTerrainList Terrain1Compressed))
  ;(= iTerrainSlot1 (iDecompressTerrainList Terrain1Compressed))
  ;(= rTerrainSlot1 (rDecompressTerrainList Terrain1Compressed))
  ;(= gTerrainSlot1 (gDecompressTerrainList Terrain1Compressed))
  ;(= bTerrainSlot1 (bDecompressTerrainList Terrain1Compressed))

  (defineFindAndReplace perVertexIndexingList
    ((piecewise ((== ([] TerrainCompressed 1) 0) (list)) ((list 0 ... (- ([] TerrainCompressed 1) 1)))))
  )
  (fn xDecompressTerrainList TerrainCompressed (comprehension
    (/ (- (extractMantissaBits
      ([] TerrainCompressed (+ (floor (/ n2 2)) 3))
      (* 26 (mod n2 2))
      26
    ) 33554432) 1024)
    (n2 (perVertexIndexingList))
  ))
  (fn yDecompressTerrainList TerrainCompressed (comprehension
    (/ (- (extractMantissaBits
      ([] TerrainCompressed (+ (floor (/ n2 2)) 3 (TerrainVertexAttribInBufferCount)))
      (* 26 (mod n2 2))
      26
    ) 33554432) 1024)
    (n2 (perVertexIndexingList))
  ))
  (fn zDecompressTerrainList TerrainCompressed (comprehension
    (/ (- (extractMantissaBits
      ([] TerrainCompressed (+ (floor (/ n2 2)) 3 (* 2 (TerrainVertexAttribInBufferCount))))
      (* 26 (mod n2 2))
      26
    ) 33554432) 1024)
    (n2 (perVertexIndexingList))
  ))
  (defineFindAndReplace perIndexIndexingList
    ((piecewise ((== ([] TerrainCompressed 2) 0) (list)) ((list 0 ... (- (* 3 ([] TerrainCompressed 2)) 1)))))
  )
  (fn iDecompressTerrainList TerrainCompressed (comprehension
    (+ (extractMantissaBits
      ([] TerrainCompressed (+ (floor (/ n2 5)) 3 (* 3 (TerrainVertexAttribInBufferCount))))
      (* 10 (mod n2 5))
      10
    ) 1)
    (n2 (perIndexIndexingList))
  ))
  (fn getColorChannelValue nValue listValue
    (* 4 (+
      (extractMantissaBits listValue (* 6 (mod nValue 8)) 6)
    ))
  )
  (defineFindAndReplace perFaceIndexingList
    ((piecewise ((== ([] TerrainCompressed 2) 0) (list)) ((list 0 ... (- ([] TerrainCompressed 2) 1)))))
  )
  (fn rDecompressTerrainList TerrainCompressed (comprehension
    (getColorChannelValue n2
      ([] TerrainCompressed (+
        (floor (/ n2 8)) 3
        (* 3 (TerrainVertexAttribInBufferCount))
        (TerrainIndexInBufferCount)
      ))
    )
    (n2 (perFaceIndexingList))
  ))
  (fn gDecompressTerrainList TerrainCompressed (comprehension
    (getColorChannelValue n2
      ([] TerrainCompressed (+
        (floor (/ n2 8)) 3
        (* 3 (TerrainVertexAttribInBufferCount))
        (TerrainIndexInBufferCount)
        (* 1 (TerrainColorInBufferCount))
      ))
    )
    (n2 (perFaceIndexingList))
  ))
  (fn bDecompressTerrainList TerrainCompressed (comprehension
    (getColorChannelValue n2
      ([] TerrainCompressed (+
        (floor (/ n2 8)) 3
        (* 3 (TerrainVertexAttribInBufferCount))
        (TerrainIndexInBufferCount)
        (* 2 (TerrainColorInBufferCount))
      ))
    )
    (n2 (perFaceIndexingList))
  ))
  (defineFindAndReplace TerrainIBO (iVBO))

  ; world space to view space intermediate
  (= xVBOViewSpaceIntermediate1 (- xVBO xViewPosition))
  (= yVBOViewSpaceIntermediate1 (- yVBO yViewPosition))
  (= zVBOViewSpaceIntermediate1 (- zVBO zViewPosition))


  (= VBOIndexingListLength (floor (/ (length (TerrainIBO)) 3)))
  (= listCompIndexingListForVBO (* 3 (list 1 ... VBOIndexingListLength)))

  (= xVBOViewSpace (+ (* xVBOViewSpaceIntermediate1 xContribToX) (* yVBOViewSpaceIntermediate1 yContribToX) (* zVBOViewSpaceIntermediate1 zContribToX)))
  (= yVBOViewSpace (+ (* xVBOViewSpaceIntermediate1 xContribToY) (* yVBOViewSpaceIntermediate1 yContribToY) (* zVBOViewSpaceIntermediate1 zContribToY)))
  (= zVBOViewSpace (+ (* xVBOViewSpaceIntermediate1 xContribToZ) (* yVBOViewSpaceIntermediate1 yContribToZ) (* zVBOViewSpaceIntermediate1 zContribToZ)))

  (multilayerFn project x y z
    (
      (xProj (/ x z))
      (yProj (/ y z))
      (return (piecewise
        ((> z 0) (point xProj yProj))
        ((* 1000 z (point xProj yProj)))
      ))
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

  ; sky/background
  (displayMe
    (polygon
      (point -4 4)
      (point 4 4)
      (point 4 -4)
      (point -4 -4)
    )
    (colorLatex (rgb 191 247 246))
    (fillOpacity 1)
  )

  (= antiAntialiasOffset 0.002)
  (fn normalize2D pt (/ pt 
    (sqrt (+ 
      (* (.x pt) (.x pt)) 
      (* (.y pt) (.y pt))))))
  (multilayerFn getScreenSpacePolygon point1 point2 point3
    (
      (avg (* 0.3333333333333 (+ point1 point2 point3)))
      (normal1 (normalize2D (- point1 avg)))
      (normal2 (normalize2D (- point2 avg)))
      (normal3 (normalize2D (- point3 avg)))
      (tangent1 (point (.y normal1) (* -1 (.x normal1))))
      (tangent2 (point (.y normal2) (* -1 (.x normal2))))
      (tangent3 (point (.y normal3) (* -1 (.x normal3))))
      (return (polygon
        (- point1 (* antiAntialiasOffset tangent1) (point 0 0))
        (+ point1 (* antiAntialiasOffset tangent1))
        (- point2 (* antiAntialiasOffset tangent2))
        (+ point2 (* antiAntialiasOffset tangent2))
        (- point3 (* antiAntialiasOffset tangent3))
        (+ point3 (* antiAntialiasOffset tangent3))
      ))
    )
  )

  ; Display terrain VBO
  (displayMe
    ([] (comprehension
      (getScreenSpacePolygon
        ([] VBOScreenSpace ([] (TerrainIBO) (+ n3 1)))
        ([] VBOScreenSpace ([] (TerrainIBO) (+ n3 2)))
        ([] VBOScreenSpace ([] (TerrainIBO) (+ n3 3)))
      )
      (n3 (- listCompIndexingListForVBO 3))
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

  (= lensFlareNotOccluded 1)

  (= sunEnabled 1)
  (= shouldOccludeLensFlare 0)
)


(folder ((title "Checkpoints"))
  
)

(folder ((title "Player & Physics"))
  ; canonical player state
  (staticVec3 PlayerPosition 0 0 -1)
  (staticVec3 PrevPlayerPosition 0 0 -1)
  (staticVec3 PlayerVelocity 0 0 0)
  (= playerSpeed (sqrt
    (magnitudeSquared (x3 PlayerVelocity) (y3 PlayerVelocity) (z3 PlayerVelocity)
  )))

  (staticVec3Copy ViewPosition PlayerPosition)

  (= xPlayerRotation -1.5)
  (= yPlayerRotation -0.1)
  (= xViewRotation xPlayerRotation)
  (= yViewRotation yPlayerRotation)

  (defineFindAndReplace contactingGround valueIfContactingGround valueIfNotContactingGround
    ((piecewise ((< nearestTriangleCollision ppcOffsetMag) valueIfContactingGround) (valueIfNotContactingGround)))
  )

  (= forceAgainstWingMag
    ;; (* -7 (staticDot
    ;;   (staticVec3Spread PlayerVelocity) (yContribToXReverse) (yContribToYReverse) (yContribToZReverse)
    ;; ))
    0
  )
  (= steeringForceMag
    (contactingGround (* -7 (staticDot
      (x3 PlayerVelocity) (y3 PlayerVelocity) (z3 PlayerVelocity) (xContribToXReverse) (xContribToYReverse) (xContribToZReverse)
    )) 0.000001)
  )
  (= normalForceMag (+ 0.01 (* -4 (staticDot
      ([] triangleCollisionNormal 1)
      ([] triangleCollisionNormal 2)
      ([] triangleCollisionNormal 3)
      (staticVec3Spread PlayerVelocity)
    )))
  )
  (= normalForce (contactingGround (* normalForceMag triangleCollisionNormal) (list 0 0 0)));(piecewise ((< nearestTriangleCollision ppcOffsetMag) ) ((list 0 0 0))))
  (= xForceOnPlayer
    (+
      ([] normalForce 1)
      (* forceAgainstWingMag (yContribToXReverse))
      (* steeringForceMag (xContribToXReverse))
    )
  )
  (= yForceOnPlayer
    (+
      ([] normalForce 2)
      (* forceAgainstWingMag (yContribToYReverse))
      (* steeringForceMag (xContribToYReverse))
      -0.75
    )
  )
  (= zForceOnPlayer
    (+
      ([] normalForce 3)
      (* forceAgainstWingMag (yContribToZReverse))
      (* steeringForceMag (xContribToZReverse))
    )
  )

  ;; (= playerPositionForCollisions (list 0 0 0))
  ;; (= previousPlayerPositionForCollisions (list 0 0 0))
  (= terrainLoadingViewerPosition (list 0 0 0))
  (staticVec3 PlayerPositionLensFlareCollisions 0 0 0)
  (staticVec3 PrevPlayerPositionLensFlareCollisions 0 0 0)
  (staticVec3 PlayerPositionFrequentCollisions 0 0 0)
  (staticVec3 PrevPlayerPositionFrequentCollisions 0 0 0)
  (= ppcOffsetMag (magnitude
    (staticVec3Spread PlayerVelocity)
  ))
  ;; (staticVec3 PlayerCollisionRaycastVector
  ;;   (/ (- (x3 PlayerPosition) (x3 PrevPlayerPosition)) ppcOffsetMag)
  ;;   (/ (- (y3 PlayerPosition) (y3 PrevPlayerPosition)) ppcOffsetMag)
  ;;   (/ (- (z3 PlayerPosition) (z3 PrevPlayerPosition)) ppcOffsetMag)
  ;; )
  (= (x3 PlayerCollisionRaycastVector) (/ (x3 PlayerVelocity) ppcOffsetMag))
  (= (y3 PlayerCollisionRaycastVector) (/ (y3 PlayerVelocity) ppcOffsetMag))
  (= (z3 PlayerCollisionRaycastVector) (/ (z3 PlayerVelocity) ppcOffsetMag))
  ;; (= triangleCollisions (
  ;;   mullerTrumbore
  ;;   (staticVec3Spread PrevPlayerPositionLensFlareCollisions)
  ;;   (staticVec3Spread)
  ;; ))
  (= triangleCollisions
    (comprehension
      (mullerTrumbore
        (staticVec3Spread PrevPlayerPosition)
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
  (= velocityFactorLimiter (piecewise 
    ((== nearestTriangleCollision nearestTriangleCollision) (min 1 (/ nearestTriangleCollision ppcOffsetMag))) 
    (1)
  ))
  (= closestTriangleIndex (* 3 ([] ([] (list 1 ... (length triangleCollisions)) (== triangleCollisions nearestTriangleCollision)) 1)))
  (multilayerFn getNormal vert1 vert2 vert3
    (
      (edge1 (- vert2 vert1))
      (edge2 (- vert3 vert1))
      (normal (list
        (xStaticCross ([] edge1 1) ([] edge1 2) ([] edge1 3) ([] edge2 1) ([] edge2 2) ([] edge2 3))
        (yStaticCross ([] edge1 1) ([] edge1 2) ([] edge1 3) ([] edge2 1) ([] edge2 2) ([] edge2 3))
        (zStaticCross ([] edge1 1) ([] edge1 2) ([] edge1 3) ([] edge2 1) ([] edge2 2) ([] edge2 3))
      ))
      (return (/ normal (magnitude ([] normal 1) ([] normal 2) ([] normal 3))))
    )
  )
  (= triangleCollisionNormal  (getNormal 
    (list 
      ([] xVBO ([] iVBO (+ closestTriangleIndex -2)))
      ([] yVBO ([] iVBO (+ closestTriangleIndex -2)))
      ([] zVBO ([] iVBO (+ closestTriangleIndex -2)))
    )
    (list 
      ([] xVBO ([] iVBO (+ closestTriangleIndex -1)))
      ([] yVBO ([] iVBO (+ closestTriangleIndex -1)))
      ([] zVBO ([] iVBO (+ closestTriangleIndex -1)))
    )
    (list 
      ([] xVBO ([] iVBO (+ closestTriangleIndex -0)))
      ([] yVBO ([] iVBO (+ closestTriangleIndex -0)))
      ([] zVBO ([] iVBO (+ closestTriangleIndex -0)))
    )
  ))
)

(folder ((title "Controls"))
  (= phoneModeEnabled 0)
  (defineFindAndReplace ifInGame doIfInGame doIfNotInGame
    ((piecewise ((== gameState GAMESTATE_GAME) doIfInGame) (doIfNotInGame)))
  )
  (= joystickSensitivity (piecewise ((== phoneModeEnabled 1) 2.25) (1.5)))
  (= joystickSensitivityPower (piecewise ((== phoneModeEnabled 1) 1.4) (1.0)))
  (= pcJoystickCenterOffset (piecewise ((== phoneModeEnabled 1) (point 0.15 -2.0)) ((point 0 0))))
  (displayMe
    pcJoystickCenterOffset
    (colorLatex (rgb 0 0 0))
    (pointOpacity (ifInGame (piecewise ((== phoneModeEnabled 1) 0.35) (0)) 0))
    (pointSize 250)
  )
  (= PALETTE_RED (rgb 255 158 158))
  (displayMe
    pcControlJoystick
    (colorLatex PALETTE_RED)
    (pointSize (piecewise ((== phoneModeEnabled 1) 125) (25)))
    (pointOpacity (ifInGame 1 0))
  )
  (displayMe
    (= pcControlJoystick (point 0 0))
    (colorLatex PALETTE_RED)
    (pointOpacity (ifInGame 1 0))
  )
  (= pcJoystickDeltaRotation (* joystickSensitivity (- pcControlJoystick pcJoystickCenterOffset)))
  (= joystickDeltaRotation (point
    (* (min (^ (abs (.x pcJoystickDeltaRotation)) joystickSensitivityPower) 0.875) (sign (.x pcJoystickDeltaRotation)))
    (* (min (^ (abs (.y pcJoystickDeltaRotation)) joystickSensitivityPower) 0.875) (sign (.y pcJoystickDeltaRotation)))
  ))
  (displayMe
    (polygon pcJoystickCenterOffset pcControlJoystick)
    (colorLatex PALETTE_RED)
    (lineOpacity (ifInGame 1 0))
  )
  (displayMe
    (polygon (point 0 0) (- pcControlJoystick pcJoystickCenterOffset))
    (colorLatex PALETTE_RED)
    (lineOpacity (ifInGame 1 0))
  )
)

(folder ((title "UI Menus"))

)

(folder ((title "Main Game Loop"))
  (= GAMESTATE_MAIN_MENU 0)
  (= GAMESTATE_GAME 1)
  (= GAMESTATE_CRASH 2)
  (= GAMESTATE_CHECKPOINT_MENU 3)
  (= GAMESTATE_SETTINGS_MENU 4)
  (= GAMESTATE_START_GAME_1 5)
  (= GAMESTATE_START_GAME_2 6)

  (= gameState GAMESTATE_GAME)

  (= frameCount 0)

  (= levelTimeElapsed 0)

  (= physicsTimestep 0)

  (= timestep 0)

  (fn gameLoop deltaTime
    (,
      (-> timestep deltaTime)
      (piecewise
        (
          (== gameState GAMESTATE_GAME)
          (,
            (-> xPlayerRotation (- xPlayerRotation (* timestep (.x joystickDeltaRotation))))
            (-> yPlayerRotation (+ yPlayerRotation (* timestep (.y joystickDeltaRotation))))
            (-> averageDeltaTime (+ (* averageDeltaTime 0) (* (* deltaTime 1000) 1)))
            (-> (x3 PlayerVelocity) (+ (* (^ 0.9997 timestep) (x3 PlayerVelocity)) (* timestep (x3 ForceOnPlayer))))
            (-> (y3 PlayerVelocity) (+ (* (^ 0.9997 timestep) (y3 PlayerVelocity)) (* timestep (y3 ForceOnPlayer))))
            (-> (z3 PlayerVelocity) (+ (* (^ 0.9997 timestep) (z3 PlayerVelocity)) (* timestep (z3 ForceOnPlayer))))
            (-> (x3 PlayerPosition) (+ (x3 PlayerPosition) (* 1 timestep (x3 PlayerVelocity))))
            (-> (y3 PlayerPosition) (+ (y3 PlayerPosition) (* 1 timestep (y3 PlayerVelocity))))
            (-> (z3 PlayerPosition) (+ (z3 PlayerPosition) (* 1 timestep (z3 PlayerVelocity))))
            (-> (x3 PrevPlayerPosition) (x3 PlayerPosition))
            (-> (y3 PrevPlayerPosition) (y3 PlayerPosition))
            (-> (z3 PrevPlayerPosition) (z3 PlayerPosition))
            ;; (piecewise (
            ;;   (< nearestTriangleCollision ppcOffsetMag)
            ;;   (-> gameState GAMESTATE_CRASH)
            ;; ))
            ;; (piecewise
            ;;   ((== (mod frameCount 4) 0)
            ;;     (,          
            ;;       (-> xPlayerPositionFrequentCollisions xPlayerPosition)
            ;;       (-> yPlayerPositionFrequentCollisions yPlayerPosition)
            ;;       (-> zPlayerPositionFrequentCollisions zPlayerPosition)
            ;;       (-> xPrevPlayerPositionFrequentCollisions xPlayerPositionFrequentCollisions)
            ;;       (-> yPrevPlayerPositionFrequentCollisions yPlayerPositionFrequentCollisions)
            ;;       (-> zPrevPlayerPositionFrequentCollisions zPlayerPositionFrequentCollisions)
            ;;     )
            ;;   )
            ;; )
          )
        )
      )
      (-> frameCount (+ frameCount 1))
      
      (piecewise
        ((== (mod frameCount 25) 0)
          (,
            (-> terrainLoadingViewerPosition
              (list xPlayerPosition yPlayerPosition zPlayerPosition)
            )
          )
        )
      )
    )
  )   
)

(ticker (gameLoop (/ dt 1000)))
(= averageDeltaTime 0)


(= NaN 0)