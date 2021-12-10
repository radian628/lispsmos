
(evalMacro withAssetPath
  "
  let url = '\u0022http://localhost:8080/desmos-plane/assets/' + args[2].slice(1, args[2].length-1) + '\u0022';
  console.log(url);
  return [[args[1], url, args[3]]];
  "
)
(evalMacro withRootPath
  "
  let url = '\u0022http://localhost:8080/desmos-plane/' + args[2].slice(1, args[2].length-1) + '\u0022';
  console.log(url);
  return [[args[1], url, args[3]]];
  "
)