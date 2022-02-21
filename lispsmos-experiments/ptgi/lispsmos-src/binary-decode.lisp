(defineFindAndReplace binStoreAmt x ((floor (/ 52 x))))

(defineFindAndReplace binaryDecodeSection src srcAbsOffset srcOffset elemCount bitCount bitOffset signOffset
  (
    (comprehension
      (/ (- (mod 
        (floor (/ ([] src 
          (+ 
            1
            srcAbsOffset
            (ceil (/ srcOffset (binStoreAmt bitCount)))
            (floor (/ i (binStoreAmt bitCount)))
          )
        ) (^ 2 (* bitCount (mod i (binStoreAmt bitCount))))))
        (^ 2 bitCount)
      ) (^ 2 signOffset)) (^ 2 bitOffset))
      (i (- (list 1 ... elemCount) 1))
    )
  )
)

(binaryDecodeSection obj 2 0 ([] obj 1) 26 10 25)
(binaryDecodeSection obj 2 ([] obj 1) ([] obj 1) 26 10 25)
(binaryDecodeSection obj 2 (* 2 ([] obj 1)) ([] obj 1) 26 10 25)