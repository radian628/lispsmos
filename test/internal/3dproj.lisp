; Configure procedural/action code
(procedureConfig
  (desmosEntryPoint main)
  (pointerStack ps)
  (programCounter pc)
)

;; (ticker (main))
(defineFindAndReplace inc v (-> v (+ v 1)))

(defineFindAndReplace triplicate v expr
  (
    (= (concatTokens v 1) expr)
    (= (concatTokens v 2) expr)
    (= (concatTokens v 3) expr)
  )
)

;; (= xPosRotated1 ( - (* xPos (cos (.x rotation))) (* zPos (sin (.x rotation)))))
;; (= yPosRotated1 yPos)
;; (= zPosRotated1 ( + (* xPos (sin (.x rotation))) (* zPos (cos (.x rotation)))))
(folder ((title "3D Projection"))
  (displayMe
    (= rotationView (point 0 0))
  )
  (= rotation rotationView)
  (fn project3D x y z (piecewise ((> z 0) (point (/ x z) (/ y z))) ((point (/ 0 0) (/ 0 0)))))
  (fn project3DTranslated x y z (project3D (+ x 0) (+ y 0) (+ z 6)))
  (fn xRotateAboutYAxis x y z (- (* x (cos (.x rotation))) (* z (sin (.x rotation)))))
  (fn zRotateAboutYAxis x y z (+ (* x (sin (.x rotation))) (* z (cos (.x rotation)))))
  (fn yRotateAboutXAxis x y z (- (* y (cos (.y rotation))) (* z (sin (.y rotation)))))
  (fn zRotateAboutXAxis x y z (+ (* y (sin (.y rotation))) (* z (cos (.y rotation)))))
)

(folder ((title "Path"))
  (= xPath (list -2 2 2 2))
  (= yPath (list -2 -2 2 2))
  (= zPath (list -2 -2 -2 2))

  (= xPathRotated (xRotateAboutYAxis xPath yPath zPath))
  (= zPathRotatedIntermediate (zRotateAboutYAxis xPath yPath zPath))
  (= yPathRotated (yRotateAboutXAxis xPathRotated yPath zPathRotatedIntermediate))
  (= zPathRotated (zRotateAboutXAxis xPathRotated yPath zPathRotatedIntermediate))
  (= pathProjected (join (project3DTranslated xPathRotated yPathRotated zPathRotated) (point (/ 0 0) (/ 0 0))))
  (displayMe  
    (polygon pathProjected)
    (fill false)
  )
)

(= a 0)
(inc a)
(triplicate b 5)

(folder ((title "Towers"))

)