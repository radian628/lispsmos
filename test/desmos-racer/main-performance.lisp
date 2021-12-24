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

  ;;; (= roll (* -0.05 (.x joystickDeltaRotation)))
  ;; (multilayerFn project x y z
  ;;   (
  ;;     (xProj (/ x z))
  ;;     (yProj (/ y z))
  ;;     (xRolled (- (* xProj (cos roll)) (* yProj (sin roll))))
  ;;     (yRolled (+ (* xProj (sin roll)) (* yProj (cos roll))))
  ;;     (return (piecewise
  ;;       ((> z 0) (point xRolled yRolled))
  ;;       ((* 1000 z (point xRolled yRolled)))
  ;;     ))
  ;;   )
  ;; )

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

  ;; ; sun
  ;; (= unrotatedSunPos (getKeyValueStore sunPosition))
  ;; (= sunPos 
  ;;   (project 
  ;;     (+ (* ([] unrotatedSunPos 1) xContribToX) (* ([] unrotatedSunPos 2) yContribToX) (* ([] unrotatedSunPos 3) zContribToX))
  ;;     (+ (* ([] unrotatedSunPos 1) xContribToY) (* ([] unrotatedSunPos 2) yContribToY) (* ([] unrotatedSunPos 3) zContribToY))
  ;;     (+ (* ([] unrotatedSunPos 1) xContribToZ) (* ([] unrotatedSunPos 2) yContribToZ) (* ([] unrotatedSunPos 3) zContribToZ))
  ;;   )
  ;; )

  ;; (defineFindAndReplace sunCircle opacity size
  ;;   ((displayMe
  ;;     (+ sunPos (* (point (cos t) (sin t)) (/ size (abs (+ xContribToZ yContribToZ (* -1 zContribToZ))))))
  ;;     (parametricDomain
  ;;       (min 0)
  ;;       (max 6.29)
  ;;     )
  ;;     (colorLatex (rgb 255 251 133))
  ;;     (fillOpacity opacity)
  ;;     (lines false)
  ;;     (fill true)
  ;;   ))
  ;; )
  ;; (sunCircle 1 0.15)
  ;; (sunCircle 0.5 0.3)
  ;; (sunCircle 0.25 0.6)

  ;; (defineFindAndReplace CLOUD_COUNT ((* 30 cloudsEnabled)))
  ;; (defineFindAndReplace POINTS_PER_CLOUD ((* 15 cloudsEnabled)))

  ;; (= settingsCloudsEnabled 1)
  ;; (= cloudsEnabled (*
  ;;   settingsCloudsEnabled
  ;;   (piecewise ((== gameState GAMESTATE_GAME) 1) (0))
  ;; ))

  ;; (= xCloudCenters (+ -128 (* 256 (random (CLOUD_COUNT) 5))))
  ;; (= yCloudCenters (+ 32 (* 16 (random (CLOUD_COUNT) 6))))
  ;; (= zCloudCenters (+ -128 (* 256 (random (CLOUD_COUNT) 7))))
  ;; (= xCloudOffsets (+ -8 (* 16 (random (* (CLOUD_COUNT) (POINTS_PER_CLOUD))))))
  ;; (= yCloudOffsets (+ -4 (* 8 (random (* (CLOUD_COUNT) (POINTS_PER_CLOUD))))))
  ;; (= zCloudOffsets (+ -6 (* 12 (random (* (CLOUD_COUNT) (POINTS_PER_CLOUD))))))

  ;; (= xCloudPoints (comprehension
  ;;   (+ ([] xCloudCenters centerCounter) ([] xCloudOffsets (+ (* (- centerCounter 1) (POINTS_PER_CLOUD)) pointCounter)))
  ;;   (centerCounter (list 1 ... (CLOUD_COUNT)))
  ;;   (pointCounter (list 1 ... (POINTS_PER_CLOUD)))
  ;; ))
  ;; (= yCloudPoints (comprehension
  ;;   (+ ([] yCloudCenters centerCounter) ([] yCloudOffsets (+ (* (- centerCounter 1) (POINTS_PER_CLOUD)) pointCounter)))
  ;;   (centerCounter (list 1 ... (CLOUD_COUNT)))
  ;;   (pointCounter (list 1 ... (POINTS_PER_CLOUD)))
  ;; ))
  ;; (= zCloudPoints (comprehension
  ;;   (+ ([] zCloudCenters centerCounter) ([] zCloudOffsets (+ (* (- centerCounter 1) (POINTS_PER_CLOUD)) pointCounter)))
  ;;   (centerCounter (list 1 ... (CLOUD_COUNT)))
  ;;   (pointCounter (list 1 ... (POINTS_PER_CLOUD)))
  ;; ))
  ;; (= cloudSizes (+ 1700 (* 1700 (random (* (CLOUD_COUNT) (POINTS_PER_CLOUD)) 8))))

  ;; (= xCloudPoints2 (- (mod (- xCloudPoints xViewPosition -128) 256) 128))
  ;; (= yCloudPoints2 (- yCloudPoints yViewPosition))
  ;; (= zCloudPoints2 (- (mod (- zCloudPoints zViewPosition -128) 256) 128))

  ;; (= xCloudPointsViewSpace (+ (* xCloudPoints2 xContribToX) (* yCloudPoints2 yContribToX) (* zCloudPoints2 zContribToX)))
  ;; (= yCloudPointsViewSpace (+ (* xCloudPoints2 xContribToY) (* yCloudPoints2 yContribToY) (* zCloudPoints2 zContribToY)))
  ;; (= zCloudPointsViewSpace (+ (* xCloudPoints2 xContribToZ) (* yCloudPoints2 yContribToZ) (* zCloudPoints2 zContribToZ)))

  ;; (displayMe
  ;;   (project xCloudPointsViewSpace yCloudPointsViewSpace zCloudPointsViewSpace)
  ;;   (colorLatex (rgb 255 255 255))
  ;;   (pointOpacity 1)
  ;;   (pointSize (/ cloudSizes zCloudPointsViewSpace))
  ;; )

  ;; (displayMe
  ;;   (simpleProject 
  ;;     (+ xContribToX yContribToX zContribToX)
  ;;     (+ xContribToY yContribToY zContribToY)
  ;;     (+ xContribToZ yContribToZ zContribToZ)
  ;;   )
  ;;   (colorLatex (rgb 255 255 200))
  ;;   (pointOpacity 0.5)
  ;;   (pointSize (/ 250 (abs (+ xContribToZ yContribToZ zContribToZ))))
  ;; )
  ;; (displayMe
  ;;   (simpleProject 
  ;;     (+ xContribToX yContribToX zContribToX)
  ;;     (+ xContribToY yContribToY zContribToY)
  ;;     (+ xContribToZ yContribToZ zContribToZ)
  ;;   )
  ;;   (colorLatex (rgb 255 255 200))
  ;;   (pointOpacity 0.25)
  ;;   (pointSize (/ 500 (abs (+ xContribToZ yContribToZ zContribToZ))))
  ;; )
  ;; (fn indexedMean property indices
  ;;   (comprehension (
  ;;     (* (+
  ;;       ([] property ([] indices (+ n -2))) 
  ;;       ([] property ([] indices (+ n -1)))
  ;;       ([] property ([] indices (+ n 0)))
  ;;     ) 0.3333333333333)
  ;;   )
  ;;   (n (* 3 (list 1 ... (/ (floor (length indices)) 3)))))
  ;; )
  ;; (= VBOScreenSpaceAvgs (indexedMean VBOScreenSpace (TerrainIBO)))

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
      ;; (polygon
      ;;   ([] VBOScreenSpace ([] (TerrainIBO) (+ n3 1)))
      ;;   ([] VBOScreenSpace ([] (TerrainIBO) (+ n3 2)))
      ;;   ([] VBOScreenSpace ([] (TerrainIBO) (+ n3 3)))
      ;; )
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



  ;; (= lensFlareSizes (list 0.5 0.7 1.2 0.2 0.4 0.6))
  ;; (= lensFlareOffsets (list 0.3 0.5 0.6 1.1 1.4 1.7))
  ;; (= lensFlareNotOccluded 1)
  ;; (displayMe
  ;;   (+ (- sunPos (* sunPos lensFlareOffsets)) (piecewise ((== lensFlareNotOccluded 1) (point 0 0)) (point 9999 9999)))
  ;;   (colorLatex (rgb 238 178 93))
  ;;   (pointOpacity 0.3)
  ;;   (pointSize (* 100 lensFlareSizes))
  ;; )

  ;; (= sunVector (normalizeList (list 3 9 -3)))
  ;; (= lensFlareTriangleCollisions
  ;;   (comprehension
  ;;     (mullerTrumbore
  ;;       (staticVec3Spread PlayerPositionCollisions)
  ;;       ([] sunVector 1) ([] sunVector 2) ([] sunVector 3)

  ;;       ([] xVBO ([] (TerrainIBO) (+ n 1)))
  ;;       ([] yVBO ([] (TerrainIBO) (+ n 1)))
  ;;       ([] zVBO ([] (TerrainIBO) (+ n 1)))

  ;;       ([] xVBO ([] (TerrainIBO) (+ n 2)))
  ;;       ([] yVBO ([] (TerrainIBO) (+ n 2)))
  ;;       ([] zVBO ([] (TerrainIBO) (+ n 2)))

  ;;       ([] xVBO ([] (TerrainIBO) (+ n 3)))
  ;;       ([] yVBO ([] (TerrainIBO) (+ n 3)))
  ;;       ([] zVBO ([] (TerrainIBO) (+ n 3)))
  ;;     )
  ;;   (n (- ([] listCompIndexingListForVBO
  ;;     (+ (floor (* (/ (length listCompIndexingListForVBO) 10) (mod frameCount 10))) 1)
  ;;     ...
  ;;     (floor (* (/ (length listCompIndexingListForVBO) 10) (+ (mod frameCount 10) 1)))
  ;;   ) 3)))
  ;; )
  ;; (= lensFlareOcclusionChecker (length ([] lensFlareTriangleCollisions (> lensFlareTriangleCollisions 0))))
  (= shouldOccludeLensFlare 0)
)

(folder ((title "Grass"))
)

; bottleneck?
(folder ((title "Checkpoints"))
  (staticVec3 StartPlayerPosition 0 0 -1)
  (staticVec3 StartPlayerVelocity 0 0 0)
  (= xStartPlayerRotation -1.5)
  (= yStartPlayerRotation -0.1)
  (= unlockedCheckpoints (list 1 1 1))
  (= bronzeThresholds (list 66 70 70))
  (= silverThresholds (list 58 65 63))
  (= goldThresholds (list 52 60 56))
  (= personalBests (list 999 999 999))
  (= currentCheckpoint 1)
  (fn startGame (,
    (-> (x3 PlayerPosition) (x3 StartPlayerPosition))
    (-> (y3 PlayerPosition) (y3 StartPlayerPosition))
    (-> (z3 PlayerPosition) (z3 StartPlayerPosition))
    (-> (x3 PlayerPositionCollisions) (x3 StartPlayerPosition))
    (-> (y3 PlayerPositionCollisions) (y3 StartPlayerPosition))
    (-> (z3 PlayerPositionCollisions) (z3 StartPlayerPosition))
    (-> (x3 PrevPlayerPositionCollisions) (x3 StartPlayerPosition))
    (-> (y3 PrevPlayerPositionCollisions) (y3 StartPlayerPosition))
    (-> (z3 PrevPlayerPositionCollisions) (z3 StartPlayerPosition))
    (-> (x3 PlayerPositionFrequentCollisions) (x3 StartPlayerPosition))
    (-> (y3 PlayerPositionFrequentCollisions) (y3 StartPlayerPosition))
    (-> (z3 PlayerPositionFrequentCollisions) (z3 StartPlayerPosition))
    (-> (x3 PrevPlayerPositionFrequentCollisions) (x3 StartPlayerPosition))
    (-> (y3 PrevPlayerPositionFrequentCollisions) (y3 StartPlayerPosition))
    (-> (z3 PrevPlayerPositionFrequentCollisions) (z3 StartPlayerPosition))
    (-> (x3 PlayerVelocity) (x3 StartPlayerVelocity))
    (-> (y3 PlayerVelocity) (y3 StartPlayerVelocity))
    (-> (z3 PlayerVelocity) (z3 StartPlayerVelocity))
    (-> xPlayerRotation xStartPlayerRotation)
    (-> yPlayerRotation yStartPlayerRotation)
    (-> gameState GAMESTATE_GAME)
    (-> pcControlJoystick pcJoystickCenterOffset)
    (-> levelTimeElapsed 0)
    (-> didGameJustStart 1)
    (-> currentlySetCheckpoint 0)
  ));

  ;(makePLYAvailableToJS "checkpoint_1")
  (preprocessIf IMPORT_HELPERS_LOADED
    ((inlineJS "
      let checkpointFileStems = [
        'checkpoint_1',
        'checkpoint_2',
        'checkpoint_3'
      ];
      compiler.macroState.desmosPlane.counter = 0;
      compiler.macroState.desmosPlane.checkpointFileStems = checkpointFileStems;
      compiler.macroState.desmosPlane.checkpointFileNames = checkpointFileStems.map(fileStem => {
          return {
            locationFileName: fileStem + '_location.ply',
            velocityFileName: fileStem + '_velocity.ply',
            colliderFileName: fileStem + '_collider.ply'
          };
        });
      compiler.macroState.desmosPlane.fileURLs = compiler.macroState.desmosPlane.checkpointFileNames.map(fileNames => {
        return Object.values(fileNames).map(fileName => {
          return compiler.macroState.desmosPlane.assetPath + fileName;
        });
      }).flat(1);
      return [];
    ")
    (inlineJS "
      compiler.macroState.desmosPlane.counter++;
      console.log(compiler.macroState.desmosPlane.fileURLs, compiler.macroState.graphics.parsedPLYs);
      if (compiler.macroState.desmosPlane.counter > 10 || compiler.macroState.desmosPlane.fileURLs.every(url => {
        console.log(url, compiler.macroState.graphics.parsedPLYs[url])
        return compiler.macroState.graphics.parsedPLYs[url];
      })) {
        compiler.macroState.utility.preprocessorFlags.add('ARE_CHECKPOINT_PLYS_LOADED');
        return [];
      } else {
        return [args];
      }
      //return [];
    ")
    (inlineJS "
      return compiler.macroState.desmosPlane.checkpointFileNames.map(fileNames => {
        return Object.values(fileNames).map(fileName => {
          return ['withAssetPath', 'makePLYAvailableToJS', `\u0022${fileName}\u0022`];
        });
      }).flat(1);
    "))
  )
  (preprocessIf ARE_CHECKPOINT_PLYS_LOADED
    ((inlineJS "
      let checkpointFileStems = compiler.macroState.desmosPlane.checkpointFileStems;

      let checkpointData = compiler.macroState.desmosPlane.checkpointFileNames;


      //console.log(compiler.macroState.graphics.parsedPLYs);

      let checkpointChooser = ['=', 'insideCheckpointViewbox', ['piecewise',
        ...checkpointData.map((datum, i) => {
          return [
            ['>', ['isInsideViewbox', 'terrainLoadingViewerPosition', ['withAssetPath', 'importPLYBounds', `\u0022${datum.colliderFileName}\u0022`]], '0'],
            (i+1).toString()
          ];
        }),
        ['0']
      ]];

      function meanStr(arr) {
        return arr.reduce((acc, cur) => acc + parseFloat(cur), 0) / arr.length;
      }

      let parsedPLYs = compiler.macroState.graphics.parsedPLYs;
      let assetPath = compiler.macroState.desmosPlane.assetPath;
      console.log(JSON.stringify(parsedPLYs));
      let startPosProperties = ['x', 'y', 'z'].map((propertyName) => {
        return ['=', propertyName + 'CheckpointStartPlayerPosition',
          ['piecewise',
            ...checkpointData.map((checkpointDatum, i) => {
              let checkpointPLYName = assetPath + checkpointDatum.locationFileName;
              console.log(checkpointPLYName, parsedPLYs[checkpointPLYName]);
              let meanCoord = meanStr(parsedPLYs[checkpointPLYName].raw.get('vertex').data[propertyName]);
              return [['==', 'currentCheckpoint', (i+1).toString()], meanCoord.toString()]
            })
          ]
        ]
      });

      let startVelProperties = ['x', 'y', 'z'].map((propertyName) => {
        return ['=', propertyName + 'CheckpointStartPlayerVelocity',
          ['piecewise',
            ...checkpointData.map((checkpointDatum, i) => {
              let checkpointPLYName = assetPath + checkpointDatum.locationFileName;
              let checkpointPLYVelocityName = assetPath + checkpointDatum.velocityFileName;
              let meanCoord =
              meanStr(parsedPLYs[checkpointPLYVelocityName].raw.get('vertex').data[propertyName]) -
              meanStr(parsedPLYs[checkpointPLYName].raw.get('vertex').data[propertyName]);
              return [['==', 'currentCheckpoint', (i+1).toString()], meanCoord.toString()]
            })
          ]
        ]
      });

      let startRotationXProperty = ['=', 'xCheckpointStartPlayerRotation',
        ['piecewise',
          ...checkpointData.map((checkpointDatum, i) => {
            let checkpointPLYName = assetPath + checkpointDatum.locationFileName;
            let checkpointPLYVelocityName = assetPath + checkpointDatum.velocityFileName;
            let pos2data = parsedPLYs[checkpointPLYVelocityName].raw.get('vertex').data;
            let pos1data = parsedPLYs[checkpointPLYName].raw.get('vertex').data;
            let xAvg = meanStr(pos2data.x) - meanStr(pos1data.x);
            let zAvg = meanStr(pos2data.z) - meanStr(pos1data.z);
            let coord = -Math.atan2(xAvg, zAvg);
            return [['==', 'currentCheckpoint', (i+1).toString()], coord.toString()]
          })
        ]
      ]

      let startRotationYProperty = ['=', 'yCheckpointStartPlayerRotation',
        ['piecewise',
          ...checkpointData.map((checkpointDatum, i) => {
            let checkpointPLYName = assetPath + checkpointDatum.locationFileName;
            let checkpointPLYVelocityName = assetPath + checkpointDatum.velocityFileName;
            let pos2data = parsedPLYs[checkpointPLYVelocityName].raw.get('vertex').data;
            let pos1data = parsedPLYs[checkpointPLYName].raw.get('vertex').data;
            let xAvg = meanStr(pos2data.x) - meanStr(pos1data.x);
            let yAvg = meanStr(pos2data.y) - meanStr(pos1data.y);
            let zAvg = meanStr(pos2data.z) - meanStr(pos1data.z);
            let coord = Math.atan2(yAvg, Math.hypot(xAvg, yAvg));
            return [['==', 'currentCheckpoint', (i+1).toString()], coord.toString()]
          })
        ]
      ]

      return [checkpointChooser, ...startPosProperties, ...startVelProperties, startRotationXProperty, startRotationYProperty];
    "))
  )
  (fn replaceSingleListElem L i replacement
    (comprehension (piecewise ((== n i) replacement) (([] L n))) (n (list 1 ... (length L))))
  )
  (= unlockedCheckpointsWithNewCheckpoint (replaceSingleListElem unlockedCheckpoints currentCheckpoint 1))
  (= withNewPersonalBest (replaceSingleListElem 
    personalBests 
    (- currentCheckpoint 1)
    (min levelTimeElapsed ([] personalBests (- currentCheckpoint 1)))
  ))
  (= didGameJustStart 1)
  (= currentlySetCheckpoint 0)
  (fn setActiveCheckpoint
    (,
      (-> (x3 StartPlayerPosition) (x3 CheckpointStartPlayerPosition))
      (-> (y3 StartPlayerPosition) (y3 CheckpointStartPlayerPosition))
      (-> (z3 StartPlayerPosition) (z3 CheckpointStartPlayerPosition))
      (-> (x3 StartPlayerVelocity) (x3 CheckpointStartPlayerVelocity))
      (-> (y3 StartPlayerVelocity) (y3 CheckpointStartPlayerVelocity))
      (-> (z3 StartPlayerVelocity) (z3 CheckpointStartPlayerVelocity))
      (-> xStartPlayerRotation xCheckpointStartPlayerRotation)
      (-> yStartPlayerRotation yCheckpointStartPlayerRotation)
      (-> checkpointOverlayTimeRemaining 3)
      (-> unlockedCheckpoints unlockedCheckpointsWithNewCheckpoint)
      (-> levelTimeElapsed 0)
      (piecewise ((== didGameJustStart 0) (,
        (-> personalBests withNewPersonalBest)
        (piecewise ((> ([] personalBests (- currentCheckpoint 1)) levelTimeElapsed)
          (-> newPBOverlayTimeRemaining 6))
        )
      )))
      (-> didGameJustStart 0)
      (-> currentlySetCheckpoint currentCheckpoint)
    )
  )
  (= shouldSetActiveCheckpoint 0)
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
  (= terrainLoadingViewerPosition (list 0 0 0))
  (staticVec3 PlayerPositionCollisions 0 0 0)
  (staticVec3 PrevPlayerPositionCollisions 0 0 0)
  (staticVec3 PlayerPositionFrequentCollisions 0 0 0)
  (staticVec3 PrevPlayerPositionFrequentCollisions 0 0 0)
  (= ppcOffsetMag (distance
    (staticVec3Spread PlayerPositionFrequentCollisions)
    (staticVec3Spread PrevPlayerPositionFrequentCollisions)
  ))
  (staticVec3 PlayerCollisionRaycastVector
    (/ (- (x3 PlayerPositionFrequentCollisions) (x3 PrevPlayerPositionFrequentCollisions)) ppcOffsetMag)
    (/ (- (y3 PlayerPositionFrequentCollisions) (y3 PrevPlayerPositionFrequentCollisions)) ppcOffsetMag)
    (/ (- (z3 PlayerPositionFrequentCollisions) (z3 PrevPlayerPositionFrequentCollisions)) ppcOffsetMag)
  )
  ;; (= triangleCollisions (
  ;;   mullerTrumbore
  ;;   (staticVec3Spread PrevPlayerPositionCollisions)
  ;;   (staticVec3Spread)
  ;; ))
  (= triangleCollisions
    (comprehension
      (mullerTrumbore
        (staticVec3Spread PrevPlayerPositionFrequentCollisions)
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
    (n (- ([] listCompIndexingListForVBO
      (+ (floor (* (/ (length listCompIndexingListForVBO) 10) (mod frameCount 10))) 1)
      ...
      (floor (* (/ (length listCompIndexingListForVBO) 10) (+ (mod frameCount 10) 1)))
    ) 3)))
  )
  (= nearestTriangleCollision (min ([] triangleCollisions (> triangleCollisions 0))))

  ;; (defineFindAndReplace singlePlanePhysicsStep Pos1 Vel1 Pos2 Vel2 timestep
  ;;   (
  ;;     (= (x3 Pos2) (+ (x3 Pos1) (* (x3 Vel1) timestep)))
  ;;     (= (y3 Pos2) (+ (y3 Pos1) (* (y3 Vel1) timestep)))
  ;;     (= (z3 Pos2) (+ (z3 Pos1) (* (z3 Vel1) timestep)))
  ;;     (= (x3 Vel2) (+ (* (x3 Vel1) (^ 0.9997 timestep)) (* timestep (x3 ForceOnPlayer))))
  ;;     (= (y3 Vel2) (+ (* (y3 Vel1) (^ 0.9997 timestep)) (* timestep (y3 ForceOnPlayer))))
  ;;     (= (z3 Vel2) (+ (* (z3 Vel1) (^ 0.9997 timestep)) (* timestep (z3 ForceOnPlayer))))
  ;;   )
  ;; )

  ;(singlePlanePhysicsStep PlayerPosition PlayerVelocity PlayerPositionStep1 PlayerVelocityStep1 physicsTimestep)
  ;(singlePlanePhysicsStep PlayerPositionStep1 PlayerVelocityStep1 PlayerPositionStep2 PlayerVelocityStep2 physicsTimestep)
  ;(singlePlanePhysicsStep PlayerPositionStep2 PlayerVelocityStep2 PlayerPositionStep3 PlayerVelocityStep3 physicsTimestep)
)

(folder ((title "Controls"))
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

; another possible bottleneck (not sure how though)?
(folder ((title "UI Menus"))
  (defineFindAndReplace pcPhone pcOption phoneOption ((piecewise ((== phoneModeEnabled 1) phoneOption) (pcOption))))
  (defineFindAndReplace showPointPredicate position predicate ((piecewise (predicate position) ((point 1000 1000)))))
  (defineFindAndReplace makeUITextColor macroName color
    ((defineFindAndReplace macroName text predicate position opacity size
      (
        (displayMe
          (+ position (piecewise (predicate (point 0 0)) ((point 1000 1000))))
          (label text)
          (showLabel true)
          (hidden true)
          (colorLatex color)
          (suppressTextOutline true)
          (labelSize (pcPhone size (* 0.5 size)))
          (pointOpacity opacity)
        )
      )
    ))
  )
  (makeUITextColor UIText (rgb 255 255 255))
  (makeUITextColor UITextBlack (rgb 0 0 0))
  (makeUITextColor UITextRed (rgb 255 0 0))
  (makeUITextColor UITextGreen (rgb 0 255 0))
  (defineFindAndReplace UIButton text predicate position1 position2 textSize onclick
    (
      (displayMe
        (polygon
          (+ (list position1
          (point (.x position1) (.y position2))
          position2
          (point (.x position2) (.y position1))) (piecewise (predicate (point 0 0)) ((point 1000 1000))))
        )
        (colorLatex (rgb 0 0 0))
        (fillOpacity 0.5)
        (lines false)
        (clickableInfo onclick)
      )
      (UIText text predicate (/ (+ position1 position2) 2) 1 textSize)
    )
  )
  (defineFindAndReplace UIButtonToggle text predicate position1 position2 textSize toggleVarName default
    (
      (displayMe
        (polygon
          (+ (list position1
          (point (.x position1) (.y position2))
          position2
          (point (.x position2) (.y position1))) (piecewise (predicate (point 0 0)) ((point 1000 1000))))
        )
        (colorLatex (rgb 0 0 0))
        (fillOpacity 0.5)
        (lines false)
        (clickableInfo (-> toggleVarName (- 1 toggleVarName)))
      )
      (UITextRed text (== (piecewise (predicate (piecewise ((== toggleVarName 0) 1) (0))) (0)) 1) (/ (+ position1 position2) 2) 1 textSize)
      (UITextGreen text (== (piecewise (predicate (piecewise ((== toggleVarName 1) 1) (0))) (0)) 1) (/ (+ position1 position2) 2) 1 textSize)
    )
  )

  ;;ingame
  (fn getMilliseconds time
    (mod time 1)
  )
  (fn getSeconds time
    (mod (floor time) 60)
  )
  (fn getMinutes time
    (floor (/ time 60))
  )

  (= personalBest ([] personalBests currentCheckpoint))
  (displayMe
    (+ (showPointPredicate (point -1.7 (pcPhone -0.0 -1.3)) (== gameState GAMESTATE_GAME)) (piecewise ((== personalBest 999) (point 9999 9999)) ((point 0 0))))
    (colorLatex (rgb 200 200 200))
    (pointOpacity 1)
    (label "Personal Best: ${p_{ersonalBest}}s")
    (showLabel true)
    (hidden true)
    (suppressTextOutline true)
    (labelSize (pcPhone 2 1))
    (labelOrientation right)
  )

  (displayMe
    (showPointPredicate (point -1.7 (pcPhone -0.2 -1.5)) (== gameState GAMESTATE_GAME))
    (colorLatex (rgb 255 255 255))
    (pointOpacity 1)
    (label "Time: ${l_{evelTimeElapsed}}s")
    (showLabel true)
    (hidden true)
    (suppressTextOutline true)
    (labelSize (pcPhone 2 1))
    (labelOrientation right)
  )

  ;(= bronzeMilliseconds (getMilliseconds ([] bronzeThresholds currentCheckpoint)))
  ;(= bronzeSeconds (getSeconds ([] bronzeThresholds currentCheckpoint)))
  ;(= bronzeMinutes (getMinutes ([] bronzeThresholds currentCheckpoint)))
  (= bronzeThreshold ([] bronzeThresholds currentCheckpoint))
  (displayMe
    (showPointPredicate (point -1.7 (pcPhone -0.4 -1.7)) (== gameState GAMESTATE_GAME))
    (colorLatex (rgb 197 173 137))
    (pointOpacity 1)
    (label "Bronze: ${b_{ronzeThreshold}}s")
    (showLabel true)
    (hidden true)
    (suppressTextOutline true)
    (labelSize (pcPhone 2 1))
    (labelOrientation right)
  )

  ;(= silverMilliseconds (getMilliseconds ([] silverThresholds currentCheckpoint)))
  ;(= silverSeconds (getSeconds ([] silverThresholds currentCheckpoint)))
  ;(= silverMinutes (getMinutes ([] silverThresholds currentCheckpoint)))
  (= silverThreshold ([] silverThresholds currentCheckpoint))
  (displayMe
    (showPointPredicate (point -1.7 (pcPhone -0.6 -1.9)) (== gameState GAMESTATE_GAME))
    (colorLatex (rgb 222 222 222))
    (pointOpacity 1)
    (label "Silver: ${s_{ilverThreshold}}s")
    (showLabel true)
    (hidden true)
    (suppressTextOutline true)
    (labelSize (pcPhone 2 1))
    (labelOrientation right)
  )

  ;(= goldMilliseconds (getMilliseconds ([] goldThresholds currentCheckpoint)))
  ;(= goldSeconds (getSeconds ([] goldThresholds currentCheckpoint)))
  ;(= goldMinutes (getMinutes ([] goldThresholds currentCheckpoint)))
  (= goldThreshold ([] goldThresholds currentCheckpoint))
  (displayMe
    (showPointPredicate (point -1.7 (pcPhone -0.8 -2.1)) (== gameState GAMESTATE_GAME))
    (colorLatex (rgb 255 195 92))
    (pointOpacity 1)
    (label "Gold: ${g_{oldThreshold}}s")
    (showLabel true)
    (hidden true)
    (suppressTextOutline true)
    (labelSize (pcPhone 2 1))
    (labelOrientation right)
  )


  ;; crash
  (= redCrashOverlayBounds
    (+
      (list
        (point -5 -5)
        (point 5 -5)
        (point 5 5)
        (point -5 5)
      )
      (piecewise ((== gameState GAMESTATE_CRASH) (point 0 0)) ((point (/ 0 0) (/ 0 0))))
    )
  )
  (displayMe
    (polygon redCrashOverlayBounds)
    (colorLatex (rgb 255 0 0))
    (fillOpacity 0.6)
  )
  (UIText "You Crashed!" (== gameState GAMESTATE_CRASH) (point 0 0.6) 1 3)
  (UIButton "Try Again" (== gameState GAMESTATE_CRASH) (point -0.6 -0.15) (point 0.6 0.15) 1 (,
    (startGame)
  ))
  (UIButton "Main Menu" (== gameState GAMESTATE_CRASH) (point -0.6 -0.25) (point 0.6 -0.55) 1 (,
    (-> gameState GAMESTATE_MAIN_MENU)
    (-> pcControlJoystick (point 5 5))
  ))


  ;; main menu
  (UITextBlack "Desmos Plane!" (== gameState GAMESTATE_MAIN_MENU) (point 0 0.9) 1 3)
  (UIButton "Play" (== gameState GAMESTATE_MAIN_MENU) (point -0.6 0.3) (point 0.6 0.6) 1 (,
    (startGame)
  ))
  (UIButton "Settings" (== gameState GAMESTATE_MAIN_MENU) (point -0.6 -0.1) (point 0.6 0.2) 1 (,
    (-> gameState GAMESTATE_SETTINGS_MENU)
  ))
  ;(= phoneModeEnabled 0)
  ;; (UIText "ON" (== (piecewise
  ;;   ((== gameState GAMESTATE_MAIN_MENU) phoneModeEnabled)
  ;; (0)) 1) (point 0.9 -0.35) 1 1.5)
  ;; (UIText "OFF" (== (piecewise
  ;;   ((== gameState GAMESTATE_MAIN_MENU) (- 1 phoneModeEnabled))
  ;; (0)) 1) (point 0.9 -0.35) 1 1.5)
  ;; (UIButton "Phone Mode" (== gameState GAMESTATE_MAIN_MENU) (point -0.6 -0.5) (point 0.6 -0.2) 1 (,
  ;;   (-> phoneModeEnabled (- 1 phoneModeEnabled))
  ;; ))
  (= phoneModeEnabled 0)
  (UIButtonToggle "Phone Mode" (== gameState GAMESTATE_MAIN_MENU) (point -0.6 -0.5) (point 0.6 -0.2) 1 phoneModeEnabled)
  (UIButton "Select Level" (== gameState GAMESTATE_MAIN_MENU) (point -0.6 -0.9) (point 0.6 -0.6) 1 (,
    (-> gameState GAMESTATE_CHECKPOINT_MENU)
  ))

  (= checkpointSelectorDisplayOffset
    (piecewise ((== gameState GAMESTATE_CHECKPOINT_MENU) 0) 1000)
  )
  (fn square x1 y1 x2 y2
    (polygon (point x1 y1) (point x1 y2) (point x2 y2) (point x2 y1))
  )
  (fn squareFromCornerAndSize x y w h (square x y (+ x w) (+ y h)))
  (displayMe
    (comprehension
      (squareFromCornerAndSize (+ (* (mod n 12) 0.2) -1.0) (+ (* (floor (/ n 12)) -0.2) 0.1 checkpointSelectorDisplayOffset) 0.16 0.16)
      (n (list 0 ... (- (length unlockedCheckpoints) 1)))
    )
    (colorLatex (rgb 0 0 0))
    (fillOpacity 0.5)
    (lines false)
    (clickableInfo (piecewise ((== ([] unlockedCheckpoints index) 1) (,
      (-> currentCheckpoint index)
      (-> didGameJustStart 1)
      (-> gameState GAMESTATE_START_GAME_1)
    ))))
  )
  (defineFindAndReplace starIcon t2 predicate
    ((+
      (* 0.012 (zigzag (* t2 10))
        (point
          (sin (* 2 3.14159265358979323 t2))
          (cos (* 2 3.14159265358979323 t2))
        )
      )
      (point
        (* (mod (floor (/ t2 1)) 12) 0.2)
        (* (floor (/ t2 12)) -0.2)
      )
      (point -0.97 0.225)
      (piecewise (predicate (point 0 0)) ((point (/ 0 0) 0)))
    ))
  )

  ; Star icons
  (fn zigzag x (sec (abs (- (mod x 2) 1))))
  (displayMe
    (starIcon t (< ([] personalBests (ceil t)) ([] bronzeThresholds (ceil t))))
    (parametricDomain
      (min 0)
      (max (piecewise ((== gameState GAMESTATE_CHECKPOINT_MENU) (- (length unlockedCheckpoints) 0.0001)) (0)))
    )
    (lines false)
    (fill true)
    (fillOpacity 1)
    (colorLatex (rgb 197 173 137))
  )
  (displayMe
    (+ (starIcon t (< ([] personalBests (ceil t)) ([] silverThresholds (ceil t)))) (point 0.05 0.0))
    (parametricDomain
      (min 0)
      (max (piecewise ((== gameState GAMESTATE_CHECKPOINT_MENU) (- (length unlockedCheckpoints) 0.0001)) (0)))
    )
    (lines false)
    (fill true)
    (fillOpacity 1)
    (colorLatex (rgb 222 222 222))
  )
  (displayMe
    (+ (starIcon t (< ([] personalBests (ceil t)) ([] goldThresholds (ceil t)))) (point 0.1 0.0))
    (parametricDomain
      (min 0)
      (max (piecewise ((== gameState GAMESTATE_CHECKPOINT_MENU) (- (length unlockedCheckpoints) 0.0001)) (0)))
    )
    (lines false)
    (fill true)
    (fillOpacity 1)
    (colorLatex (rgb 255 195 92))
  )

  (fn lockIconBody t
    (* 0.03
      (point
        (*
          (cos (* 8 3.141592653589 t))
          (piecewise
            ((> t 0.75) 0.7)
            ((> t 0.5) 0.5)
            (1)
          )
        )
        (+
          (*
            (sin (* 8 3.141592653589 t))
            (piecewise
              ((> t 0.75) -1.3)
              ((> t 0.5) 1)
              (1)
            )
          )
          (piecewise ((> t 0.75) 0.8) ((> t 0.5) 0.86) (0))
        )
      )
    )
  )

  ;Lock icon body
  (displayMe
    (+
      (point
        (* (mod (floor (/ t 1)) 12) 0.2)
        (* (floor (/ t 12)) -0.2)
      )
      (point -0.92 0.16)
      (lockIconBody (mod t 1))
      (piecewise ((== ([] unlockedCheckpoints (ceil t)) 1) (point (/ 0 0) 0)) ((point 0 0)))
    )
    (parametricDomain
      (min 0)
      (max (piecewise ((== gameState GAMESTATE_CHECKPOINT_MENU) (length unlockedCheckpoints)) (0)))
    )
    (lines false)
    (fill true)
    (fillOpacity 1)
    (colorLatex (rgb 192 192 192))
  )
  (UIText "Select Level" (== gameState GAMESTATE_CHECKPOINT_MENU) (point 0 0.7) 1 3)
  (UIButton "Back" (== gameState GAMESTATE_CHECKPOINT_MENU) (point -1 0.7) (point -0.8 0.5) 1 (,
    (-> gameState GAMESTATE_MAIN_MENU)
  ))

  ;; settings menu
  (UITextBlack "Settings" (== gameState GAMESTATE_SETTINGS_MENU) (point 0 0.9) 1 3)
  ;; (= isGrass)
  ;; (UIButton "Grass" (== gameState GAMESTATE_SETTINGS_MENU) (point -0.6 0.6) (point 0.6 0.4) 0.75 (,
  ;;   (-> gameState GAMESTATE_MAIN_MENU)
  ;; ))
  (= grassEnabled 0)
  (UIButtonToggle "Phone Mode" (== gameState GAMESTATE_SETTINGS_MENU) (point -0.6 0.6) (point 0.6 0.4) 0.75 phoneModeEnabled)
  ;; (UIButtonToggle "Grass" (== gameState GAMESTATE_SETTINGS_MENU) (point -0.6 0.4) (point 0.6 0.2) 0.75 grassEnabled)
  ;; (UIButtonToggle "Clouds" (== gameState GAMESTATE_SETTINGS_MENU) (point -0.6 0.2) (point 0.6 0.0) 0.75 settingsCloudsEnabled)
  (UIButton "Back" (== gameState GAMESTATE_SETTINGS_MENU) (point -1 0.7) (point -0.8 0.5) 1 (,
    (-> gameState GAMESTATE_MAIN_MENU)
  ))

  ;; checkpoint overlay
  (= checkpointOverlayTimeRemaining 0)
  (UIText "Level ${c_{urrentCheckpoint}}" (> checkpointOverlayTimeRemaining 0) (point 0 0) (piecewise
    ((> checkpointOverlayTimeRemaining 2) (- 1 (- checkpointOverlayTimeRemaining 2)))
    ((> checkpointOverlayTimeRemaining 1) 1)
    (checkpointOverlayTimeRemaining)
  ) 3)
  (= newPBOverlayTimeRemaining 0)
  (= prevCheckpoint (- currentCheckpoint 1))
  (= prevCheckpointPB ([] personalBests prevCheckpoint))
  (UIText "New Level ${p_{revCheckpoint}} Personal Best: ${p_{revCheckpointPB}}s!" (> newPBOverlayTimeRemaining 0) (point 0 0.3) (piecewise
    ((> newPBOverlayTimeRemaining 5) (- 1 (- newPBOverlayTimeRemaining 5)))
    ((> newPBOverlayTimeRemaining 1) 1)
    (newPBOverlayTimeRemaining)
  ) 1.5)
)

(folder ((title "Main Game Loop"))
  (= GAMESTATE_MAIN_MENU 0)
  (= GAMESTATE_GAME 1)
  (= GAMESTATE_CRASH 2)
  (= GAMESTATE_CHECKPOINT_MENU 3)
  (= GAMESTATE_SETTINGS_MENU 4)
  (= GAMESTATE_START_GAME_1 5)
  (= GAMESTATE_START_GAME_2 6)

  (= gameState GAMESTATE_MAIN_MENU)

  (= frameCount 0)

  (= levelTimeElapsed 0)

  (= physicsTimestep 0)

  (fn gameLoop deltaTime
    (,
      (piecewise
        ((= gameState GAMESTATE_START_GAME_1) 
          (,
            (setActiveCheckpoint)
            (-> gameState GAMESTATE_START_GAME_2)
          )
        )
        ((= gameState GAMESTATE_START_GAME_2) 
          (,
            (startGame)
          )
        )
        ((= gameState GAMESTATE_GAME)
          (,
            (piecewise
              ((== shouldSetActiveCheckpoint 0)
                (,
                  (-> levelTimeElapsed (+ levelTimeElapsed deltaTime))
                )
              )
            )
            (-> physicsTimestep (/ deltaTime 1))
            (-> xPlayerRotation (- xPlayerRotation (* deltaTime (.x joystickDeltaRotation))))
            (-> yPlayerRotation (+ yPlayerRotation (* deltaTime (.y joystickDeltaRotation))))
            (-> averageDeltaTime (+ (* averageDeltaTime 0) (* (* deltaTime 1000) 1)))
            (-> (x3 PlayerVelocity) (+ (* (^ 0.9997 deltaTime) (x3 PlayerVelocity)) (* deltaTime (x3 ForceOnPlayer))))
            (-> (y3 PlayerVelocity) (+ (* (^ 0.9997 deltaTime) (y3 PlayerVelocity)) (* deltaTime (y3 ForceOnPlayer))))
            (-> (z3 PlayerVelocity) (+ (* (^ 0.9997 deltaTime) (z3 PlayerVelocity)) (* deltaTime (z3 ForceOnPlayer))))
            (-> (x3 PlayerPosition) (+ (x3 PlayerPosition) (* deltaTime (x3 PlayerVelocity))))
            (-> (y3 PlayerPosition) (+ (y3 PlayerPosition) (* deltaTime (y3 PlayerVelocity))))
            (-> (z3 PlayerPosition) (+ (z3 PlayerPosition) (* deltaTime (z3 PlayerVelocity))))
            ;; (-> (x3 PlayerPosition) (x3 PlayerPositionStep1))
            ;; (-> (y3 PlayerPosition) (y3 PlayerPositionStep1))
            ;; (-> (z3 PlayerPosition) (z3 PlayerPositionStep1))
            ;; (-> (x3 PlayerVelocity) (x3 PlayerVelocityStep1))
            ;; (-> (y3 PlayerVelocity) (y3 PlayerVelocityStep1))
            ;; (-> (z3 PlayerVelocity) (z3 PlayerVelocityStep1))
            (piecewise (
              (< nearestTriangleCollision ppcOffsetMag)
              (-> gameState GAMESTATE_CRASH)
            ))
            (piecewise
              ((== (mod frameCount 10) 0)
                (,          
                  (-> xPlayerPositionFrequentCollisions xPlayerPosition)
                  (-> yPlayerPositionFrequentCollisions yPlayerPosition)
                  (-> zPlayerPositionFrequentCollisions zPlayerPosition)
                  (-> xPrevPlayerPositionFrequentCollisions xPlayerPositionFrequentCollisions)
                  (-> yPrevPlayerPositionFrequentCollisions yPlayerPositionFrequentCollisions)
                  (-> zPrevPlayerPositionFrequentCollisions zPlayerPositionFrequentCollisions)
                )
              )
            )
            (piecewise
              ((== (mod frameCount 10) 0)
                (,          
                  (-> xPlayerPositionCollisions xPlayerPosition)
                  (-> yPlayerPositionCollisions yPlayerPosition)
                  (-> zPlayerPositionCollisions zPlayerPosition)
                  (-> xPrevPlayerPositionCollisions xPlayerPositionCollisions)
                  (-> yPrevPlayerPositionCollisions yPlayerPositionCollisions)
                  (-> zPrevPlayerPositionCollisions zPlayerPositionCollisions)
                )
              )
              ((== (mod frameCount 10) 1)
                (piecewise
                  ((> insideCheckpointViewbox 0)
                    (,
                      (-> currentCheckpoint insideCheckpointViewbox)
                      (piecewise ((== currentlySetCheckpoint currentCheckpoint) (-> shouldSetActiveCheckpoint 0))
                        ((,
                          (-> shouldSetActiveCheckpoint 1)
                        ))
                      )
                    )
                  )
                )
              )
              ((== (mod frameCount 10) 2)
                (piecewise
                  ((== shouldSetActiveCheckpoint 1)
                    (,
                      (setActiveCheckpoint)
                      (-> shouldSetActiveCheckpoint 0)
                    )
                  )
                )
              )
            )
            (piecewise
              ((== shouldSetActiveCheckpoint 0)
                (,
                  (piecewise
                    ((> checkpointOverlayTimeRemaining 0) (-> checkpointOverlayTimeRemaining (- checkpointOverlayTimeRemaining deltaTime)))
                  )
                  (piecewise
                    ((> newPBOverlayTimeRemaining 0) (-> newPBOverlayTimeRemaining (- newPBOverlayTimeRemaining deltaTime)))
                  )
                )
              )
            )
          )
        )
        ((= gameState GAMESTATE_MAIN_MENU)
          (,
            (-> xPlayerRotation (+ xPlayerRotation (* deltaTime 0.1)))
            (-> yPlayerRotation 0)
            (-> (x3 PlayerPosition) -50)
            (-> (y3 PlayerPosition) -5)
            (-> (z3 PlayerPosition) 50)
            (-> checkpointOverlayTimeRemaining 0)
          )
        )
      )
      (-> frameCount (+ frameCount 1))
      (piecewise
        ((== (mod frameCount 10) 0)
          (,
            (-> terrainLoadingViewerPosition
              (list xPlayerPosition yPlayerPosition zPlayerPosition)
            )
          )
        )
      )
      ;; (piecewise
      ;;   ((== (mod frameCount 10) 9)
      ;;     (,
      ;;       (-> lensFlareNotOccluded (- 1 (min 1 (+ shouldOccludeLensFlare lensFlareOcclusionChecker))))
      ;;       (-> shouldOccludeLensFlare 0)
      ;;     )
      ;;   )
      ;;   ((-> shouldOccludeLensFlare (min 1 (+ shouldOccludeLensFlare lensFlareOcclusionChecker))))
      ;; )
    )
  )
)

(ticker (gameLoop (/ dt 1000)))
(= averageDeltaTime 0)


(= NaN 0)