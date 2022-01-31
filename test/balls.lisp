(ticker (main))
 (viewport -1 1 -1 1)


(folder ((title "Control"))
  (displayMe
    (= rotationDisplay (point (* 0.2 rx) (* 0.2 ry)))
    (pointOpacity 0)
  )
  (= rx 0)
  (= ry 0)
)

(defineFindAndReplace createBallVelocityAction posVar velVar nextCube wallValue intersection
  (
    (-> velVar 
      (piecewise
        ((== nextCube wallValue) 
          (* velVar
            (list
              (piecewise ((== intersection 1) -1) (1))
              (piecewise ((== intersection 2) -1) (1))
              (piecewise ((== intersection 3) -1) (1))
            )
          )
        )
        ((* velVar (list
          (piecewise
            ((> ([] posVar 1) 10) -1)
            ((< ([] posVar 1) 0) -1)
            (1)
          )
          (piecewise
            ((> ([] posVar 2) 10) -1)
            ((< ([] posVar 2) 0) -1)
            (1)
          )
          (piecewise
            ((> ([] posVar 3) 10) -1)
            ((< ([] posVar 3) 0) -1)
            (1)
          )
        )))
      )
    )
  )
)

(defineFindAndReplace createBallPositionAction posVar velVar nextCube wallValue
  (
    (-> posVar (piecewise
      ((== nextCube wallValue) 
        posVar
      )
      ((list
        (piecewise
          ((> ([] posVar 1) 10) 10)
          ((< ([] posVar 1) 0) 0)
          ((+ ([] posVar 1) (* deltaTime ([] velVar 1))))
        )
        (piecewise
          ((> ([] posVar 2) 10) 10)
          ((< ([] posVar 2) 0) 0)
          ((+ ([] posVar 2) (* deltaTime ([] velVar 2))))
        )
        (piecewise
          ((> ([] posVar 3) 10) 10)
          ((< ([] posVar 3) 0) 0)
          ((+ ([] posVar 3) (* deltaTime ([] velVar 3))))
        )
      ))
    ))
  )
)

(folder ((title "Stuff"))
  (= deltaTime 0.25)
  (fn nthBit x n 
    (mod (floor (/ x (^ 2 n))) 2)
  )

  (fn replaceNthElem L i newItem
    (comprehension (piecewise ((== idx i) newItem) (([] L idx))) (idx (list 1 ... (length L))))
  )

  (fn nthCube n
    (nthBit ([] cubes (floor (+ 1 (/ n 50)))) (mod n 50))  
  )

  (fn setNthCube n newValue
    (piecewise ((== newValue (nthCube n)) (-> cubes cubes))
      ((piecewise
        ((== newValue 0) (-> cubes (replaceNthElem cubes (+ 1 (floor (/ n 50))) 
          (- ([] cubes (+ 1 (floor (/ n 50)))) (^ 2 (mod n 50)))
        )))
        ((== newValue 1) (-> cubes (replaceNthElem cubes (+ 1 (floor (/ n 50))) 
          (+ ([] cubes (+ 1 (floor (/ n 50)))) (^ 2 (mod n 50)))
        )))
      ))
    )
  )

  (fn cubeIndex xyz
    (+
      (min 9 (max 0 (floor ([] xyz 1))))
      (* 10 (min 9 (max 0 (floor ([] xyz 2)))))
      (* 100 (min 9 (max 0 (floor ([] xyz 3)))))
    )
  )

  (= cubes (list (inlineJS "
  
  let samples = new Array(1000).fill(0).map((_, e) => {
    let x = e % 10;
    let y = Math.floor(e / 10) % 10;
    let z = Math.floor(e / 100);
    if (Math.hypot(x-5, y-5, z-5) > 3.25) {
      return 0;
    } else {
      return 1;
    }
  })
  let out = [];
  for (let i = 0; i < 20; i++) {
    let singleSample = 0;
    for (let j = 0; j < 50; j++) {
      let idx = i * 50 + j;
      singleSample += Math.pow(2, j) * samples[idx];
    }
    out.push(singleSample);
  }
  return out.map(e => e.toString());
  ")))

  (= ball1Pos (list 9 9 9))
  (= ball2Pos (list 5 5 5))

  (= ball1Vel (list -0.5 -0.6 0.8))
  (= ball2Vel (* 0.15 (list 0.7 -0.4 -0.5)))

  (= ball1NextCubeIndex (cubeIndex (+ ball1Pos (* deltaTime ball1Vel))))
  (= ball1NextCube (nthCube ball1NextCubeIndex))
  (= ball1PotentialNextIntersections (abs (list
    (/ (piecewise ((< ([] ball1Vel 1) 0) (mod ([] ball1Pos 1) 1)) ((- 1 (mod ([] ball1Pos 1) 1)))) ([] ball1Vel 1))
    (/ (piecewise ((< ([] ball1Vel 2) 0) (mod ([] ball1Pos 2) 1)) ((- 1 (mod ([] ball1Pos 2) 1)))) ([] ball1Vel 2))
    (/ (piecewise ((< ([] ball1Vel 3) 0) (mod ([] ball1Pos 3) 1)) ((- 1 (mod ([] ball1Pos 3) 1)))) ([] ball1Vel 3))
  )))
  (= ball1NextAxisIntersection
    ([] ([] (list 1 2 3) (== ball1PotentialNextIntersections (min ball1PotentialNextIntersections))) 1)
  )


  (= ball2NextCubeIndex (cubeIndex (+ ball2Pos (* deltaTime ball2Vel))))
  (= ball2NextCube (nthCube ball2NextCubeIndex))
  (= ball2PotentialNextIntersections (abs (list
    (/ (piecewise ((< ([] ball2Vel 1) 0) (mod ([] ball2Pos 1) 1)) ((- 1 (mod ([] ball2Pos 1) 1)))) ([] ball2Vel 1))
    (/ (piecewise ((< ([] ball2Vel 2) 0) (mod ([] ball2Pos 2) 1)) ((- 1 (mod ([] ball2Pos 2) 1)))) ([] ball2Vel 2))
    (/ (piecewise ((< ([] ball2Vel 3) 0) (mod ([] ball2Pos 3) 1)) ((- 1 (mod ([] ball2Pos 3) 1)))) ([] ball2Vel 3))
  )))
  (= ball2NextAxisIntersection
    ([] ([] (list 1 2 3) (== ball2PotentialNextIntersections (min ball2PotentialNextIntersections))) 1)
  )

  (fn main (,
    (createBallPositionAction ball1Pos ball1Vel ball1NextCube 1)
    (createBallPositionAction ball2Pos ball2Vel ball2NextCube 0)
    (piecewise 
      ((== ball1NextCube 1) (piecewise ((> (abs (- ball1NextCubeIndex (cubeIndex ball2Pos))) 0)
        (setNthCube ball1NextCubeIndex 0)
      )))
      ((piecewise 
        ((== ball2NextCube 0) (piecewise  ((> (abs (- ball2NextCubeIndex (cubeIndex ball1Pos))) 0)
          (setNthCube ball2NextCubeIndex 1)
        )))
      ))
    )
    ;(-> ball1Pos (+ (min 9.99 (max 0.01 ball1Pos)) (* deltaTime ball1Vel)))
    ;(-> ball2Pos (+ (min 9.99 (max 0.01 ball2Pos)) (* deltaTime ball2Vel)))
    (createBallVelocityAction ball1Pos ball1Vel ball1NextCube 1 ball1NextAxisIntersection)
    (createBallVelocityAction ball2Pos ball2Vel ball2NextCube 0 ball2NextAxisIntersection)
  ))

  (multilayerFn projectOntoScreen xyz
    (
      (xyz1 (- xyz (list 5 5 5)))
      (xyz2 (list 
        (+ (* ([] xyz1 1) (cos rx)) (* ([] xyz1 3) (sin rx)))
        ([] xyz1 2)
        (+ (* -1 ([] xyz1 1) (sin rx)) (* ([] xyz1 3) (cos rx)))
      ))
      (xyz3 (list 
        ([] xyz2 1)
        (+ (* ([] xyz2 2) (cos ry)) (* -1 ([] xyz2 3) (sin ry)))
        (+ (* ([] xyz2 2) (sin ry)) (* ([] xyz2 3) (cos ry)))
      ))
      (return (point (/ (+ -0 ([] xyz3 1)) (+ 15 ([] xyz3 3))) (/ (+ -0 ([] xyz3 2)) (+ 15 ([] xyz3 3)))))
    )
  )
  (multilayerFn getDepth xyz
    (
      (xyz1 (- xyz (list 5 5 5)))
      (xyz2 (list 
        (+ (* ([] xyz1 1) (cos rx)) (* ([] xyz1 3) (sin rx)))
        ([] xyz1 2)
        (+ (* -1 ([] xyz1 1) (sin rx)) (* ([] xyz1 3) (cos rx)))
      ))
      (return 
        (+ (* ([] xyz2 2) (sin ry)) (* ([] xyz2 3) (cos ry)) 15)
      )
    )
  )
)

(folder ((title "Display"))
  (displayMe
    (comprehension
      (projectOntoScreen
        (list
        (mod indices 10)
        (mod (floor (/ indices 10)) 10)
        (floor (/ indices 100))
        )
      )
      (indices ([] (list 0 ... 999) (== (
        comprehension
        (nthBit cubeBitset bitNumber)
        (bitNumber (list 0 ... 49))
        (cubeBitset cubes)
      ) 1)))
    )
    (pointOpacity 0.04)
    (colorLatex (rgb 255 0 0))
  )
  (displayMe
    (list  
      (polygon
        (projectOntoScreen (list 0 0 0))
        (projectOntoScreen (list 0 10 0))
        (projectOntoScreen (list 0 10 10))
        (projectOntoScreen (list 0 0 10))
      )
      (polygon
        (projectOntoScreen (list 10 0 0))
        (projectOntoScreen (list 10 10 0))
        (projectOntoScreen (list 10 10 10))
        (projectOntoScreen (list 10 0 10))
      )
      (polygon
        (projectOntoScreen (list 0 0 0))
        (projectOntoScreen (list 10 0 0))
        (projectOntoScreen (list 10 0 10))
        (projectOntoScreen (list 0 0 10))
      )
      (polygon
        (projectOntoScreen (list 0 10 0))
        (projectOntoScreen (list 10 10 0))
        (projectOntoScreen (list 10 10 10))
        (projectOntoScreen (list 0 10 10))
      )
      (polygon
        (projectOntoScreen (list 0 0 0))
        (projectOntoScreen (list 0 10 0))
        (projectOntoScreen (list 10 10 0))
        (projectOntoScreen (list 10 0 0))
      )
      (polygon
        (projectOntoScreen (list 0 0 10))
        (projectOntoScreen (list 0 10 10))
        (projectOntoScreen (list 10 10 10))
        (projectOntoScreen (list 10 0 10))
      )
    )
    (colorLatex (rgb 0 0 0))
    (fillOpacity 0.1)
    (lineOpacity 0.2)
    ;(lines false)
  )
  (fn indexToCoords idx
    (list
      (mod idx 10)
      (mod (floor (/ idx 10)) 10)
      (floor (/ idx 100))
    )
  )
  (displayMe
    (comprehension
      (piecewise 
        ((== (nthCube i) (nthCube (+ i 1))) (polygon)) ((>= (mod i 10) 9) (polygon)) ((> i 999) (polygon))
        ((polygon 
          (projectOntoScreen (+ (indexToCoords i) (list 1 0 0)))
          (projectOntoScreen (+ (indexToCoords i) (list 1 1 0)))
          (projectOntoScreen (+ (indexToCoords i) (list 1 1 1)))
          (projectOntoScreen (+ (indexToCoords i) (list 1 0 1)))
        )))
      (i (list 1 ... 1000))
    )
    (lines false)
    (colorLatex (rgb 0 0 0))
    (fillOpacity 0.9)
  )
  (displayMe
    (comprehension
      (piecewise 
        ((== (nthCube i) (nthCube (+ i 10))) (polygon)) ((>= (mod (floor (/ i 10)) 10) 9) (polygon)) ((> i 989) (polygon))
        ((polygon 
          (projectOntoScreen (+ (indexToCoords i) (list 1 1 0)))
          (projectOntoScreen (+ (indexToCoords i) (list 0 1 0)))
          (projectOntoScreen (+ (indexToCoords i) (list 0 1 1)))
          (projectOntoScreen (+ (indexToCoords i) (list 1 1 1)))
        )))
      (i (list 1 ... 1000))
    )
    (lines false)
    (colorLatex (rgb 20 20 20))
    (fillOpacity 0.9)
  )
  (displayMe
    (comprehension
      (piecewise 
        ((== (nthCube i) (nthCube (+ i 100))) (polygon)) ((> i 899) (polygon))
        ((polygon 
          (projectOntoScreen (+ (indexToCoords i) (list 1 0 1)))
          (projectOntoScreen (+ (indexToCoords i) (list 0 0 1)))
          (projectOntoScreen (+ (indexToCoords i) (list 0 1 1)))
          (projectOntoScreen (+ (indexToCoords i) (list 1 1 1)))
        )))
      (i (list 1 ... 1000))
    )
    (lines false)
    (colorLatex (rgb 50 50 50))
    (fillOpacity 0.9)
  )
  (displayMe (projectOntoScreen ball1Pos) (pointSize (/ 300 (getDepth ball1Pos))) (colorLatex (rgb 255 255 255)))
  (displayMe (projectOntoScreen ball1Pos) (pointSize (/ 250 (getDepth ball1Pos))))
  (displayMe (projectOntoScreen ball2Pos) (pointSize (/ 250 (getDepth ball2Pos))) (colorLatex (rgb 255 255 255)))
)
 (image 
      "http://localhost:8080/desmos-plane-2/assets/blank-image.jpg"
      (
        (center rotationDisplay)
        (draggable true)
      )
    )