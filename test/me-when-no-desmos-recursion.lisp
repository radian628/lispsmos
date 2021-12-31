(evalMacro meWhenNoDesmosRecursion "
  console.log(`EEEEEEEEEEEE`);
  let fnToRecurse = args[1];
  let iterationCount = Number(args[2]);
  let exprList = [];
  for (let i = 0; i < iterationCount; i++) {
    let currentFnName = fnToRecurse + 'composed' + i;
    let lastFnName = fnToRecurse + ((i == 0) ? '' : ('composed' + (i - 1)));
    exprList.push([
      'fn', currentFnName, 'x', [lastFnName, [lastFnName, 'x']]
    ]);

    let currentRecursionFnName = fnToRecurse + 'recursed' + i;
    if (i == iterationCount - 1) {
      currentRecursionFnName = fnToRecurse + 'ComposedNTimes';
    }
    let lastRecursionFnName = fnToRecurse + ('recursed' + (i - 1));
    if (i == 0) {
      exprList.push([
        'fn', currentRecursionFnName, 'x', 'n', ['piecewise',
          [['>=', ['mod', 'n', Math.pow(2, i+1).toString()], Math.pow(2, i).toString()], [lastFnName, 'x']], ['x']]
      ]);
    } else {
      exprList.push([
        'fn', currentRecursionFnName, 'x', 'n', [lastRecursionFnName, ['piecewise',
          [['>=', ['mod', 'n', Math.pow(2, i+1).toString()], Math.pow(2, i).toString()], [lastFnName, 'x']], ['x']
        ], 'n']
      ]);
    }
  }
  console.log(exprList);
  return exprList;

")

(fn f x (* 1.01 x))
(folder ((title "me when YES desmos recursion ;)"))
  (meWhenNoDesmosRecursion f 10)
)
(displayMe
  (fComposedNTimes 1 (floor x))
)