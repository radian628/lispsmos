  (= triangleOffsetEpsilon 0.005)
  (fn threeDToTwoD points i triCenter
      (+ 
        ([] points i)
        (* triangleOffsetEpsilon (pointSigns (- ([] points i) triCenter)))
      )
  )
  (fn getPolygonToDraw points indices n triCenter
    (polygon
      (threeDToTwoD points ([] indices (+ n 1)) triCenter)
      (threeDToTwoD points ([] indices (+ n 2)) triCenter)
      (threeDToTwoD points ([] indices (+ n 3)) triCenter)
    )
  )
  (fn drawIndexedIntermediate points indices triangleCenters
    (comprehension ;(
      ;polygon 
      ;; (+ 
      ;;   ([] points ([] indices (+ n 1))) 
      ;;   (* (normalize (- ([] points ([] indices (+ n 1))) ([] triangleCenters (+ 1 (floor (/ n 3)))))) 0.01)
      ;; ) 
      ;; (+ 
      ;;   ([] points ([] indices (+ n 2))) 
      ;;   (* (normalize (- ([] points ([] indices (+ n 2))) ([] triangleCenters (+ 1 (floor (/ n 3)))))) 0.01)
      ;; ) 
      ;; (+ 
      ;;   ([] points ([] indices (+ n 3))) 
      ;;   (* (normalize (- ([] points ([] indices (+ n 3))) ([] triangleCenters (+ 1 (floor (/ n 3)))))) 0.01)
      ;; ) 
      ;; (+ 
      ;;   ([] points ([] indices (+ n 1)))
      ;;   (* triangleOffsetEpsilon (pointSigns (- ([] points ([] indices (+ n 1))) ([] triangleCenters (+ 1 (floor (/ n 3)))))))
      ;; )
      ;; (+ 
      ;;   ([] points ([] indices (+ n 2)))
      ;;   (* triangleOffsetEpsilon (pointSigns (- ([] points ([] indices (+ n 2))) ([] triangleCenters (+ 1 (floor (/ n 3)))))))
      ;; )
      ;; (+ 
      ;;   ([] points ([] indices (+ n 3)))
      ;;   (* triangleOffsetEpsilon (pointSigns (- ([] points ([] indices (+ n 3))) ([] triangleCenters (+ 1 (floor (/ n 3)))))))
      ;; )
      (getPolygonToDraw points indices n ([] triangleCenters (+ 1 (floor (/ n 3)))))
      ;; (threeDToTwoD points ([] indices (+ n 1)) ([] triangleCenters (+ 1 (floor (/ n 3)))))
      ;; (threeDToTwoD points ([] indices (+ n 2)) ([] triangleCenters (+ 1 (floor (/ n 3)))))
      ;; (threeDToTwoD points ([] indices (+ n 3)) ([] triangleCenters (+ 1 (floor (/ n 3)))))
     (n (* 3 (list 0 ... (/ (floor (length indices)) 3)))))
  )
  (fn drawIndexed points indices
    (drawIndexedIntermediate points indices (getTriangleAverages points indices))
  )