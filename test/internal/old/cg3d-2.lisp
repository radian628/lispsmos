(procedureConfig
  (desmosEntryPoint main)
  (pointerStack ps)
  (programCounter pc)
)

(ticker (main))

(fn chaosGameIter x choices rands 
  (/ (+ 
    ([] choices (+ 1 rands))
    x
  ) 2)
)

(= i 0)
(= xPos (+ 0 (* 0 (list 1 ... 9000))))
(= yPos (+ 0 (* 0 (list 1 ... 9000))))
(= zPos (+ 5.5 (* 0 (list 1 ... 9000))))
(= xPosRotated1 ( - (* xPos (cos (.x rotation))) (* zPos (sin (.x rotation)))))
(= yPosRotated1 yPos)
(= zPosRotated1 ( + (* xPos (sin (.x rotation))) (* zPos (cos (.x rotation)))))
(= xPosRotated xPosRotated1)
(= yPosRotated ( - (* yPosRotated1 (cos (.y rotation))) (* zPosRotated1 (sin (.y rotation)))))
(= zPosRotated ( + (* yPosRotated1 (sin (.y rotation))) (* zPosRotated1 (cos (.y rotation)))))
(= randoms (floor (* 4 (random 9000))))
(= xPoints (list -1 1 -1 -1))
(= yPoints (list -1 -1 1 -1))
(= zPoints (list -1 -1 -1 1))
(displayMe 
  (= display (point (/ xPosRotated (+ zPosRotated 5)) (/ yPosRotated (+ zPosRotated 5))))
  (pointOpacity 0.3)
)
(= rotation (* rotationController 30))
(displayMe 
  (= rotationController (point 0 0))
  (color (rgb 255 0 0))
)
(procedure main
  (while (< i 10)
    (-> randoms (floor (* 4 (random 9000))))
    (-> xPos (chaosGameIter xPos xPoints randoms))
    (-> yPos (chaosGameIter yPos yPoints randoms))
    (-> zPos (chaosGameIter zPos zPoints randoms))
    (-> i (+ i 1))
  )
)