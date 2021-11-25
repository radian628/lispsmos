(procedureConfig
  (desmosEntryPoint main)
  (pointerStack ps)
  (programCounter pc)
)

(fn chaosGameIter data 
  (join
    (/ (+ (list
      ([] points (+ 1 (* 3 ([] randoms ([] data 4)))))
      ([] points (+ 2 (* 3 ([] randoms ([] data 4)))))
      ([] points (+ 3 (* 3 ([] randoms ([] data 4)))))
    ) ([] data 1 ... 3)) 2)
    (+ ([] data 4) 1)
  )
)

(fn chaosGameIter10 data (
  compose 10 chaosGameIter data 
))

(= i 0)
(= randoms (floor (* 4 (random 10))))
(= points (list -1 -1 5 1 -1 5 -1 1 5 -1 -1 6))
(= currentPoint (list 0.5 0.5 5.5))
(= display (list))
(= displayCache (list))
(procedure main
  (while (> 2 1)
    (,
      (-> randoms (floor (* 4 (random 10))))
      (-> currentPoint (chaosGameIter10 (list 0.5 0.5 5.5 1)))
      (-> displayCache (join displayCache (list (point 
        (/ ([] currentPoint 1) ([] currentPoint 3))
        (/ ([] currentPoint 2) ([] currentPoint 3))
      ))))
      (-> i (+ i 1))
    )
    (if (> i 50)
      (,
        (-> i 0)
        (-> display (join display displayCache))
        (-> displayCache (list))
      )
    )
    (-> i i)
  )
)