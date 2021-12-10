(folder ((title "Graphics Library"))
  ; Ray-triangle intersection for collision detection
  (= rtiEpsilon 0.001)
  (fn isDefined testValue defaultValue
    (piecewise
      ((== testValue testValue) testValue)
      (defaultValue)
    )
  )
  (fn rayTriangleIntersectionIntermediate4 det u v t
    (piecewise
      ((< det rtiEpsilon) -1)
      ((< t 0) -1)
      ((< u 0) -1)
      ((< v 0) -1)
      ((> (+ u v) 1) -1)
      ((isDefined t -1))
    )
  )

  (fn rayTriangleIntersectionIntermediate3 rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2 E1 E2 N det invdet AO DAO
    (rayTriangleIntersectionIntermediate4
      det
      (* (dotVec3 E2 DAO) invdet)
      (* -1 (* (dotVec3 E1 DAO) invdet))
      (* (dotVec3 AO N) invdet)
    )
  )
  (fn rayTriangleIntersectionIntermediate2 rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2 E1 E2 N det invdet
    (rayTriangleIntersectionIntermediate3 rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2 E1 E2 N det invdet
      (- rayOrigin (list x0 y0 z0))
      (cross (- rayOrigin (list x0 y0 z0)) rayVector)
    )
  )
  (fn rayTriangleIntersectionIntermediate1 rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2 E1 E2
    (rayTriangleIntersectionIntermediate2 rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2 E1 E2
      (cross E1 E2)
      (* -1 (dotVec3 rayVector (cross E1 E2)))
      (/ 1 (* -1 (dotVec3 rayVector (cross E1 E2))))
    )
  )
  (fn rayTriangleIntersection rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2
    (rayTriangleIntersectionIntermediate1 rayOrigin rayVector x0 y0 z0 x1 y1 z1 x2 y2 z2 
      (list (- x1 x0) (- y1 y0) (- z1 z0))
      (list (- x2 x0) (- y2 y0) (- z2 z0))
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
  ;;; index list (n (* 3 (list 0 ... (/ (floor (length indices)) 3))))
  (= CachedIndexLookup (n (* 3 (list 0 ... (/ (floor (length indices)) 3)))))
  ; cull faces if needed
  (fn windingOrderContribution p1 p2 (* (- (.x p2) (.x p1)) (+ (.y p2) (.y p1))))
  (fn getSingleCullingInformationIntermediate1 z1 z2 z3 pt1 pt2 pt3 farPlane
    (piecewise
      ((>
        (mean z1 z2 z3)
        farPlane
      ) -1)
      ((> 
        (max z1 z2 z3)
        0
        )
        (+
          (windingOrderContribution pt1 pt2)
          (windingOrderContribution pt2 pt3)
          (windingOrderContribution pt3 pt1)
        )
      )
      (-1)
    )
  )
  (fn getSingleCullingInformation points zValues i1 i2 i3 farPlane
    (getSingleCullingInformationIntermediate1 
      ([] zValues i1)
      ([] zValues i2)
      ([] zValues i3)
      ([] points i1)
      ([] points i2)
      ([] points i3)
      farPlane
    )
  )
  (fn getCullingInformation points zValues indices ordering farPlane
    (comprehension 
      (getSingleCullingInformationIntermediate1
        ([] zValues ([] indices (+ n 1)))
        ([] zValues ([] indices (+ n 2)))
        ([] zValues ([] indices (+ n 3)))
        ([] points ([] indices (+ n 1)))
        ([] points ([] indices (+ n 2)))
        ([] points ([] indices (+ n 3)))
        farPlane
      )

      ;; (getSingleCullingInformation
      ;;  points zValues
      ;;   ([] indices (+ n 1))
      ;;   ([] indices (+ n 2))
      ;;   ([] indices (+ n 3))
      ;;   farPlane
      ;; )

      ;; (piecewise
      ;;   ((>
      ;;     (mean
      ;;       ([] zValues ([] indices (+ n 1)))
      ;;       ([] zValues ([] indices (+ n 2)))
      ;;       ([] zValues ([] indices (+ n 3)))
      ;;     )
      ;;     farPlane
      ;;   ) -1)
      ;;   ((> 
      ;;     (max
      ;;       ([] zValues ([] indices (+ n 1)))
      ;;       ([] zValues ([] indices (+ n 2)))
      ;;       ([] zValues ([] indices (+ n 3)))
      ;;     )
      ;;     0
      ;;     )
      ;;     (+
      ;;       (windingOrderContribution ([] points ([] indices (+ n 1))) ([] points ([] indices (+ n 2))))
      ;;       (windingOrderContribution ([] points ([] indices (+ n 2))) ([] points ([] indices (+ n 3))))
      ;;       (windingOrderContribution ([] points ([] indices (+ n 3))) ([] points ([] indices (+ n 1))))
      ;;     )
      ;;   )
      ;;   (-1)
      ;; )
      (n (* 3 ([] (list 0 ... (/ (floor (length indices)) 3)) (join ordering 0))))
    )
  )
  ; Indexed Triangles
  (fn pointSigns pt
    (point (sign (.x pt)) (sign (.y pt)))
  )
  (= triangleOffsetEpsilon 0.005)
  (fn threeDToTwoD points i 
      ;(+ 
        ([] points i)
        ;(* triangleOffsetEpsilon (pointSigns (- ([] points i) triCenter)))
      ;)
  )
  (fn getPolygonToDraw points indices n 
    (polygon
      (threeDToTwoD points ([] indices (+ n 1)) )
      (threeDToTwoD points ([] indices (+ n 2)) )
      (threeDToTwoD points ([] indices (+ n 3)) )
    )
  )
  (fn drawIndexedIntermediate points indices 
    (comprehension
      (getPolygonToDraw points indices n )
     (n (* 3 (list 0 ... (/ (floor (length indices)) 3)))))
  )
  (fn drawIndexed points indices
    (drawIndexedIntermediate points indices)
  )
  ;; (fn getTriangleDepth x y z
  ;;   (* (+
  ;;     (mag3DSq ([] xs ([] indices (+ n 1))) ([] ys ([] indices (+ n 1))) ([] zs ([] indices (+ n 1))))
  ;;     (mag3DSq ([] xs ([] indices (+ n 2))) ([] ys ([] indices (+ n 2))) ([] zs ([] indices (+ n 2))))
  ;;     (mag3DSq ([] xs ([] indices (+ n 3))) ([] ys ([] indices (+ n 3))) ([] zs ([] indices (+ n 3))))
  ;;   ) 0.333333333)
  ;; )
  (fn getIndexedDepths xs ys zs indices
    (comprehension (
      (* (+
        (mag3DSq ([] xs ([] indices (+ n 1))) ([] ys ([] indices (+ n 1))) ([] zs ([] indices (+ n 1))))
        (mag3DSq ([] xs ([] indices (+ n 2))) ([] ys ([] indices (+ n 2))) ([] zs ([] indices (+ n 2))))
        (mag3DSq ([] xs ([] indices (+ n 3))) ([] ys ([] indices (+ n 3))) ([] zs ([] indices (+ n 3))))
      ) 0.33333333333)
    )
    (n (* 3 (list 0 ... (/ (floor (length indices)) 3)))))
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
        ([] property ([] indices (+ n -2))) 
        ([] property ([] indices (+ n -1)))
        ([] property ([] indices (+ n 0)))
      )
    )
    (n (* 3 (list 1 ... (/ (floor (length indices)) 3)))))
  )
  (defineFindAndReplace getFaceColors plyName (
  (= (PLYGet plyName face red) (indexedMean (PLYGet plyName vertex red) (PLYGet plyName face vertexunderscoreindices)))
  (= (PLYGet plyName face green) (indexedMean (PLYGet plyName vertex green) (PLYGet plyName face vertexunderscoreindices)))
  (= (PLYGet plyName face blue) (indexedMean (PLYGet plyName vertex blue) (PLYGet plyName face vertexunderscoreindices)))
  ))
)