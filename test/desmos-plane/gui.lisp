
(= MenuStateGame 0)
(= MenuStateMain 1)
(= MenuStateCrash 2)
(= MenuStateCheckpoints 3)
(= MenuStateStartGame 4)

(defineFindAndReplace UIButton name pt1 pt2 text action textColor
  ((displayMe
    (= (concatTokens name Button) (polygon pt1 (point (.x pt1) (.y pt2)) pt2 (point (.x pt2) (.y pt1))))
    (colorLatex (rgb 0 0 0))
    (fillOpacity 0.5)
    (lines false)
    (clickableInfo action)
  )
  (displayMe 
    (= (concatTokens name ButtonText) (point (/ (+ (.x pt1) (.x pt2)) 2) (/ (+ (.y pt1) (.y pt2)) 2)))
    (colorLatex textColor)
    (label text)
    (pointOpacity 1)
    (labelSize 2.5)
    (hidden true)
    (showLabel true)
    (suppressTextOutline true)
  ))
)

(folder ((title "Crash Overlay"))
  (displayMe
    (= crashOverlay (polygon (point -10 (+ crashMenuDisplayOffset -10)) (point -10 (+ crashMenuDisplayOffset 10)) (point 10 (+ crashMenuDisplayOffset 10)) (point 10 (+ crashMenuDisplayOffset -10))))
    (colorLatex (rgb 255 0 0))
  )
  (displayMe 
    (= crashText (point 0 (+ crashMenuDisplayOffset 0.3)))
    (colorLatex (rgb 255 255 255))
    (label "You Crashed!")
    (labelSize 5)
    (hidden true)
    (showLabel true)
    (suppressTextOutline true)
  )

  (= crashMenuDisplayOffset (piecewise ((== menuState MenuStateCrash) 0) (100)))
  (UIButton tryAgainButton (point -0.6 (+ crashMenuDisplayOffset -0.3)) (point 0.6 (+ crashMenuDisplayOffset -0.6)) "Try Again" startGame (rgb 255 255 255))
  (UIButton returnToMainMenuButton (point -0.6 (+ crashMenuDisplayOffset -0.7)) (point 0.6 (+ crashMenuDisplayOffset -1.0)) "Main Menu" (-> menuState MenuStateMain) (rgb 255 255 255))
)

(folder ((title "Main Menu"))
  (= mainMenuDisplayOffset (piecewise ((== menuState MenuStateMain) 0) (100)))
  (displayMe 
    (= mainMenuText (point 0 (+ mainMenuDisplayOffset 0.6)))
    (colorLatex (rgb 0 0 0))
    (label "Desmos Plane!")
    (labelSize 5)
    (hidden true)
    (showLabel true)
    (suppressTextOutline true)
  )

  (= phoneMode 0)
  (UIButton playButton (point -0.6 (+ mainMenuDisplayOffset -0.1)) (point 0.6 (+ mainMenuDisplayOffset -0.4)) "Play" startGame (rgb 255 255 255))
  (UIButton startAtCheckpointButton (point -0.6 (+ mainMenuDisplayOffset -0.5)) (point 0.6 (+ mainMenuDisplayOffset -0.8)) "Start at Checkpoint" (-> menuState MenuStateCheckpoints) (rgb 255 255 255))
  (UIButton phoneModeButton (point -0.6 (+ mainMenuDisplayOffset -0.9)) (point 0.6 (+ mainMenuDisplayOffset -1.2)) "Phone Mode" (-> phoneMode (- 1 phoneMode))
    (piecewise ((== phoneMode 0) (rgb 255 0 0)) ((rgb 0 255 0)))
  )
)

(fn square x1 y1 x2 y2
  (polygon (point x1 y1) (point x1 y2) (point x2 y2) (point x2 y1))
)
(fn squareFromCornerAndSize x y w h (square x y (+ x w) (+ y h)))

(folder ((title "Checkpoint Selector"))
  (= checkpointCount 3)
  (= checkpointSelectorDisplayOffset (piecewise ((== menuState MenuStateCheckpoints) 0) (100)))
  (displayMe 
    (= checkpointSelectorText (point 0 (+ checkpointSelectorDisplayOffset 0.7)))
    (colorLatex (rgb 0 0 0))
    (label "Select Checkpoint:")
    (labelSize 2.5)
    (hidden true)
    (showLabel true)
    (suppressTextOutline true)
  )
  
  (displayMe 
    (comprehension 
      (squareFromCornerAndSize (+ (* (mod n 12) 0.2) -1.0) (+ (* (floor (/ n 12)) -0.2) 0.1 checkpointSelectorDisplayOffset) 0.16 0.16)
      (n (list 0 ... (- checkpointCount 1)))
    )
    (colorLatex (rgb 0 0 0))
    (fillOpacity 0.5)
    (lines false)
    (clickableInfo (piecewise ((== ([] checkpointsVisited index) 1) (,
      (setActiveCheckpoint index)
      (-> menuState MenuStateStartGame)
    ))))
  )

  ; Star icons
  (fn zigzag x (sec (abs (- (mod x 2) 1))))
  (displayMe
    (+ 
      (* 0.015 (zigzag (* t 10))
        (point
          (sin (* 2 3.14159265358979323 t))
          (cos (* 2 3.14159265358979323 t))
        )
      )
      (point 
        (* (mod (floor (/ t 1)) 12) 0.2)
        (* (floor (/ t 12)) -0.2)
      )
      (point -0.97 0.225)
      (piecewise ((== ([] starsFound (ceil t)) 0) (point (/ 0 0) 0)) ((point 0 0)))
    )
    (parametricDomain
      (min 0)
      (max (piecewise ((== menuState MenuStateCheckpoints) checkpointCount) (0)))
    )
    (lines false)
    (fill true)
    (fillOpacity 1)
    (colorLatex (rgb 255 192 0))
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
      (piecewise ((== ([] checkpointsVisited (ceil t)) 1) (point (/ 0 0) 0)) ((point 0 0)))
    )
    (parametricDomain
      (min 0)
      (max (piecewise ((== menuState MenuStateCheckpoints) checkpointCount) (0)))
    )
    (lines false)
    (fill true)
    (fillOpacity 1)
    (colorLatex (rgb 192 192 192))
  )

  ;(UIButton startAtBeginningButton (point -1.6 (+ checkpointSelectorDisplayOffset 0.6)) (point -1.3 (+ checkpointSelectorDisplayOffset 0.3)) "Start" (-> menuState MenuStateMain))

  (UIButton backToMenuButton (point -1.8 (+ checkpointSelectorDisplayOffset 0.8)) (point -1.4 (+ checkpointSelectorDisplayOffset 0.4)) "Back" (-> menuState MenuStateMain))
)