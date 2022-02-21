import { compiler, utilityMacros, compilerUtils } from "lispsmos";

export default function (c: compiler.LispsmosCompiler) {
  c.registerMacro("execIf", (ast, compiler) => {
    let condition = ast[1];
    let indexOfSummation = ast[2];
    let value = ast[3];
    let conditionPiecewise = ["piecewise",
      [condition, "0"],
      ["-1"]
    ];
    return [["sum", indexOfSummation, "0", conditionPiecewise, value]];
  })
}