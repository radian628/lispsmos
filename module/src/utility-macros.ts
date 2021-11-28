//import { astToDesmosExpressions } from "./compiler";
import { LispsmosCompiler, MacroFunc } from "./compiler.js";
import { ASTNode } from "./compiler-utils.js"
import {extractStringFromLiteral } from "./compiler-utils.js";

type ASTMapping = {
  [src: string]: ASTNode;
}

function findAndReplace(stringsToReplace: string[], thingsToReplaceThemWith: ASTNode[], astToReplace: ASTNode) {
  let replaceSrc: ASTMapping = {};
  //console.log(thingsToReplaceThemWith);
  for (let i = 0; i < stringsToReplace.length; i++) {
    replaceSrc[stringsToReplace[i]] = thingsToReplaceThemWith[i];
  }
  let result = _findAndReplace(replaceSrc, astToReplace);
  //console.log(result);
  return result;
}

function _findAndReplace(replaceSrc: ASTMapping, astToReplace: ASTNode): ASTNode {
  let newAST = [];
  switch (typeof astToReplace) {
    case "object":
      for (let astChild of astToReplace) {
        newAST.push(_findAndReplace(replaceSrc, astChild));
      }
      return newAST;
    case "string":
      let replacement = replaceSrc[astToReplace]; 
      if (replacement === undefined) {
        return astToReplace;
      } else {
        return replacement;
      }   
  }
}

export function register (c: LispsmosCompiler) {
  c.registerMacro("defineFindAndReplace", (ast, compiler): Array<ASTNode> => {
    //let ms = compiler.macroState;
    //if (!ms.utility) ms.utility = {};
    //let msu = ms.utility;
    //if (!msu.findAndReplace) msu.findAndReplace = {}; 
    //let findAndReplaceMacros = msu.findAndReplace;
    let stringToReplace = ast[1];
    if (typeof stringToReplace != "string") throw new Error("Find and replace macro name must be a single primitive value.");
    let replaceStrings = ast.slice(2, ast.length - 1);
    if (!replaceStrings.every(replacement => (typeof replacement == "string"))) {
      throw new Error(`LISPsmos Error: Find-and-replace macros can only replace strings!`);
    }
    let replaceBody = ast[ast.length - 1];
    // findAndReplaceMacros[ast[1]] = {
    //   replaceStrings: ast.slice(2, ast.length - 1),
    //   replaceBody: ast[ast.length - 1]
    // };
    compiler.registerMacro(stringToReplace, (ast2, compiler2): Array<ASTNode> => {
      let replacements = ast2.slice(1);
      let findAndReplaceResult = [findAndReplace((replaceStrings as string[]), replacements, replaceBody)];
      return findAndReplaceResult;
    });
    return [];
  });

  c.registerMacro("concatTokens", (ast, compiler): Array<ASTNode> => {
    let outToken = "";
    for (let astChild of ast.slice(1)) {
      outToken += astChild;
    }
    //console.log(astList, outToken);
    return [outToken];
  });

  c.registerMacro("evalMacro", (ast, compiler): Array<ASTNode> => {
    if (Array.isArray(ast[2])) {
      throw new Error("LISPsmos Error: evalMacro may only be used on a string!");
    }
    if (Array.isArray(ast[1])) {
      throw new Error("LISPsmos Error: evalMacro name may only be used on a string!");
    }
    let functionToEval = new Function("args", extractStringFromLiteral(ast[2]));
    compiler.registerMacro(ast[1], (ast2, compiler2): Array<ASTNode> => {
      return functionToEval(ast2);
    });
    return [];
  });
}

// export let macros = {
//   // pointwise: (ast, compiler) => {
//   //   return astToDesmosExpressions([
//   //     "point",
//   //     [ast[1]].concat(ast.slice(2).map(e => [".x", e])),
//   //     [ast[1]].concat(ast.slice(2).map(e => [".y", e]))
//   //   ]);
//   // },
//   // defineFindAndReplace: (ast: Array<ASTNode>, compiler: LispsmosCompiler): Array<ASTNode> => {
//   // },
//   // findAndReplace: (ast, compiler) => {
//   //   //console.log(astList);
//   // // },
//   // concatTokens: (ast, compiler) => {
//   //   let outToken = "";
//   //   for (let astChild of astList.slice(1)) {
//   //     outToken += astChild;
//   //   }
//   //   //console.log(astList, outToken);
//   //   return [outToken];
//   // },
//   evalJS: (ast, compiler) => {
//     let jsToEvaluate = astList[1];
//     return new Function(extractStringFromLiteral(jsToEvaluate));
//   }
// }