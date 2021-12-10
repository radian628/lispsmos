
(evalMacro withAssetPath
  "
  let url = '\u0022http://localhost:8080/desmos-plane-2/assets/' + args[2].slice(1, args[2].length-1) + '\u0022';
  console.log(url);
  return [[args[1], url, args[3]]];
  "
)
(evalMacro withRootPath
  "
  let url = '\u0022http://localhost:8080/desmos-plane-2/' + args[2].slice(1, args[2].length-1) + '\u0022';
  console.log(url);
  return [[args[1], url, args[3]]];
  "
)
(defineFindAndReplace PLYGet fileVar elementType propertyType
  ((concatTokens fileVar ELEM elementType PROP propertyType))
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