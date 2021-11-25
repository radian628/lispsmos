; Configure procedural/action code
(procedureConfig
  (desmosEntryPoint main)
  (pointerStack ps)
  (programCounter pc)
)

; Define ticker function
(ticker (main))

; Obsolete functions for truncation
(folder ((title "Obsolete stuff."))
  (fn trunc1000 n (/ (floor (* n 1000)) 1000))
  (fn trunc1000p p (point (trunc1000 (.x p)) (trunc1000 (.y p))))
)

(folder ((title "Constants"))
  (= POINTCOUNT 20)
)

(folder ((title "Util Functions"))
  (fn magSq pt (+ (^ (.x pt) 2) (^ (.y pt) 2)))
  (fn distSq pt1 pt2 (magSq (- pt1 pt2)))
  (fn dist pt1 pt2 (^ (distSq pt1 pt2) 0.5))
  (fn getGravityVector pt1 pt2
    (piecewise
      ((= (.x pt1) (.x pt2)) (point 0 0))
      ((/ (- pt2 pt1) (^ (distSq pt1 pt2) 1.5)))
    )
  )
  (fn calcAccel pos mass
    (* 0.00007 (point
      (sum n 1 POINTCOUNT (.x (getGravityVector pos ([] pointPos n))))
      (sum n 1 POINTCOUNT (.y (getGravityVector pos ([] pointPos n))))
    ) (sum n 1 POINTCOUNT ([] masses n)) (/ 1 mass))
  )
)

; Data for the points
(folder ((title "Bulk Data (TM)"))
  (= pointPos (* 30 (point (random POINTCOUNT 14) (random POINTCOUNT 25))))
  (= pointVel (* 0.001 (- (point (random POINTCOUNT 43) (random POINTCOUNT 4)) (point 0.5 0.5))))
  (= masses (+ 1.0 (* 25.0 (^ (random POINTCOUNT 7) 9))))
  (= pointMask (join 1 (* 0 (list 1 ... 99))) )
)

; All the displayable points.
;; (folder ((title "Display"))
;;   (displayMe
;;     (= pointDisp (+ pointPos (* pointVel time)))
;;     (color red)
;;     (pointSize (* 25 (^ masses (/ 1 3))))
;;     (pointStyle CIRCLE)
;;     (pointOpacity 0.5)
;;   )
;; )

(folder ((title "Display"))
  (= radii (* 0.5 (^ masses (/ 1 3))))
  (= circleList (
    comprehension (point (cos n) (sin n)) (n (* (list 1 ... 20) (/ 6.28318531 20)))
  ))
  (displayMe
    ;; (= pointDisp (+ pointPos (point
    ;;   (* radii (cos (* t 6.29)))
    ;;   (* radii (sin (* t 6.29)))
    ;; )))
    (comprehension (polygon (+ (* circleList ([] radii n2)) ([] pointPos n2))
      ;; (+ (point (* 1 ([] radii n)) (* -1 ([] radii n))) ([] pointPos n))
      ;; (+ (point (* -1 ([] radii n)) (* -1 ([] radii n))) ([] pointPos n))
      ;; (+ (point (* -1 ([] radii n)) (* 1 ([] radii n))) ([] pointPos n))
      ;; (+ (point (* 1 ([] radii n)) (* 1 ([] radii n))) ([] pointPos n))
      ;; ()
    ) (n2 (list 1 ... POINTCOUNT)))
  )
)

; Folder for ticker stuff
(folder ((title "Ticker Stuff"))
  (= time 0)
  (= update pointPos)
  (= stepCount 0)
)

; Procedure!
(procedure main
  (while (> 2 1)
    (,
      (-> time 0)
      (-> pointPos (+ pointPos pointVel))
      (-> pointVel (+ pointVel (calcAccel pointPos masses)))
    )
  )
)