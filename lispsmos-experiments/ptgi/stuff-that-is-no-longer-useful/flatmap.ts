import { compiler, utilityMacros, compilerUtils } from "lispsmos";

import { ensureArray, ensureSymbol, removeQuotes, noScientific, findAndReplaceAST } from "../src/common.js";

export default function (c: compiler.LispsmosCompiler) {
  c.registerMacro("makeFlatmap", (ast, c) => {
    let flatmapName = ensureSymbol(ast[1], "Flatmap function name cannot be a list!");
    let listArgs = ensureArray(ast[2], `Flatmap argument list must be a list, not '${ast[2]}'`);
    let firstList = listArgs[0];
    let indexOfSummation = ensureSymbol(ast[3], "Index of summation must not be a list!");
    let iterations = Number(ast[4]);
    let fnBody = ast[5];
    
    let outputAST = [];

    let halfListLengthExpr = ["floor", ["/", ["length", firstList], "2"]];

    for (let i = 0; i < iterations; i++) {
      let flatmapFunctionName = (i == 0) ? flatmapName : (flatmapName + i.toString());
      let nextFlatmapFunctionName = flatmapName + (i+1).toString();
      //let fixedFnBody = findAndReplaceAST(fnBody, indexOfSummation, indexOfSummation + i);
      if (i != iterations - 1) {
        outputAST.push([
          "fn", flatmapFunctionName, ...listArgs,
          ["piecewise",
            [
              [">", ["length", firstList], "1"],
              ["execIf", [">", ["length", firstList], "1"], indexOfSummation+i,
                ["join",
                  ["+", [nextFlatmapFunctionName,
                    ...listArgs.map(listName => {
                      return ["+", ["[]", listName, "1", "...", halfListLengthExpr], indexOfSummation+i];
                    })
                  ], indexOfSummation+i],
                  [nextFlatmapFunctionName,
                    ...listArgs.map(listName => {
                      return ["+", ["[]", listName, ["+", halfListLengthExpr, "1"], "..."], indexOfSummation+i];
                    })
                  ]
                ]
              ]
            ],
            [
              findAndReplaceAST(fnBody, indexOfSummation, "0")
            ]
          ]
        ]);
      } else {outputAST.push([
        "fn", flatmapFunctionName, ...listArgs, findAndReplaceAST(fnBody, indexOfSummation, "0")
      ]);
      }
    }

    return outputAST;
  });
}