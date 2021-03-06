
; Define XYZ values
(defineFindAndReplace defineXYZ inputVarName xVals yVals zVals
    (
        (= (concatTokens x inputVarName) xVals)
        (= (concatTokens y inputVarName) yVals)
        (= (concatTokens z inputVarName) zVals)
    )
)
; Define rotated version of lists
(defineFindAndReplace getRotated inputVarName outputVarName amounts
    (
        (= (concatTokens x outputVarName) (xRotateAboutYAxis (concatTokens x inputVarName) (concatTokens y inputVarName) (concatTokens z inputVarName) amounts))
        (= (concatTokens z inputVarName LISPSMOSIntermediate) (zRotateAboutYAxis (concatTokens x inputVarName) (concatTokens y inputVarName) (concatTokens z inputVarName) amounts))
        (= (concatTokens y outputVarName) (yRotateAboutXAxis (concatTokens x outputVarName) (concatTokens y inputVarName) (concatTokens z inputVarName LISPSMOSIntermediate) amounts))
        (= (concatTokens z outputVarName) (zRotateAboutXAxis (concatTokens x outputVarName) (concatTokens y inputVarName) (concatTokens z inputVarName LISPSMOSIntermediate) amounts))
    )
)

; 3D Component Interface
(defineFindAndReplace x3 v
  ((concatTokens x v))
)
(defineFindAndReplace y3 v
  ((concatTokens y v))
)
(defineFindAndReplace z3 v
  ((concatTokens z v))
)

; translating vertex buffers
(defineFindAndReplace getTranslated inputVar outputVar x y z
  ((defineXYZ outputVar
    (+ (x3 inputVar) x)
    (+ (y3 inputVar) y)
    (+ (z3 inputVar) z)
  ))
)

;; (defineFindAndReplace join3D name src1 src2
;;   (defineXYZ name
;;     (join (x3 src1) (x3 src2))
;;     (join (y3 src1) (y3 src2))
;;     (join (z3 src1) (z3 src2))
;;   )
;; )

(evalMacro join3D "
  return [['defineXYZ', args[1],
    ['join'].concat(args.slice(2).map(arg => 'x'+arg)),
    ['join'].concat(args.slice(2).map(arg => 'y'+arg)),
    ['join'].concat(args.slice(2).map(arg => 'z'+arg)),
  ]];
")
(defineFindAndReplace alias3D inputVar outputVar
  (
    (= (x3 outputVar) (x3 inputVar))
    (= (y3 outputVar) (y3 inputVar))
    (= (z3 outputVar) (z3 inputVar))
  )
)

(defineFindAndReplace averagePLYPos plyName
  ((list
    (mean (PLYGet plyName vertex x))
    (mean (PLYGet plyName vertex y))
    (mean (PLYGet plyName vertex z))
  ))
)