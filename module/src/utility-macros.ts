//import { astToDesmosExpressions } from "./compiler";
import { LispsmosCompiler, MacroFunc, stringToTokenStream, tokenStreamToAST } from "./compiler.js";
import { ASTNode, getTokenType } from "./compiler-utils.js"
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
  console.log(result);
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
  c.registerEvent("init", (compiler) => {
    compiler.macroState.utility = { assets: {} };
  })

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
      let findAndReplaceResult = findAndReplace((replaceStrings as string[]), replacements, replaceBody);
      return findAndReplaceResult as Array<ASTNode>;
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
    let functionToEval = new Function("args", "compiler", extractStringFromLiteral(ast[2]));
    compiler.registerMacro(ast[1], (ast2, compiler2): Array<ASTNode> => {
      return functionToEval(ast2, compiler2);
    });
    return [];
  });

  c.registerMacro("inlineJS", (ast, compiler): ASTNode[] => {
    if (Array.isArray(ast[1])) {
      throw new Error("LISPsmos Error: Inline JavaScript macro must be given a string!");
    }
    let functionToEval = new Function("compiler", extractStringFromLiteral(ast[1]));
    return functionToEval(compiler);
  });

  
  c.registerResourceGatherer("include", async (ast: ASTNode, compiler: LispsmosCompiler) => {
    let importString = ast[1];
    if (Array.isArray(importString)) {
      throw new Error(`LISPsmos Error: Cannot import a list!`);
    }
    importString = extractStringFromLiteral(importString);
    let file = await compiler.import(importString);
    compiler.macroState.utility.assets[importString] = file;
    return;
  });
  c.registerResourceGatherer("importAsString", async (ast: ASTNode, compiler: LispsmosCompiler) => {
    let importString = ast[1];
    if (Array.isArray(importString)) {
      throw new Error(`LISPsmos Error: Cannot import a list!`);
    }
    importString = extractStringFromLiteral(importString);
    let file = await compiler.import(importString);
    compiler.macroState.utility.assets[importString] = file;
    return;
  });
  c.registerMacro("include", (ast: ASTNode, compiler: LispsmosCompiler): ASTNode[] => {
    let importString = ast[1];
    if (Array.isArray(importString)) {
      throw new Error(`LISPsmos Error: Cannot import a list!`);
    }
    importString = extractStringFromLiteral(importString);
    let importAttempt = compiler.macroState.utility.assets[importString].payload;
    if (typeof importAttempt != "string") {
      throw new Error(`LISPsmos Error: Cannot include '${importString}'- the file received was not a string. Received type '${typeof importAttempt}'`)
    }
    console.log(importAttempt);
    
    let importedAST;

    try {
      importedAST = tokenStreamToAST(stringToTokenStream(importAttempt));
    } catch (err) {
      throw new Error(`LISPsmos Error: Failed to import '${importString}'' because '${err.message}'`);
    }
    
    return importedAST;
  });
  c.registerMacro("importAsString", (ast: ASTNode, compiler: LispsmosCompiler): ASTNode[] => {
    let importString = ast[1];
    if (Array.isArray(importString)) {
      throw new Error(`LISPsmos Error: Cannot import a list!`);
    }
    importString = extractStringFromLiteral(importString);
    let importAttempt = compiler.macroState.utility.assets[importString].payload;
    if (typeof importAttempt != "string") {
      throw new Error(`LISPsmos Error: Cannot include '${importString}'- the file received was not a string. Received type '${typeof importAttempt}'`)
    }

    return ["\"" + importAttempt + "\""];
  });

  c.registerMacro("multilayerFn", createMultilayerFunction);
}

function getIntermediateDependencies(nodeToTest: ASTNode, possibleIntermediates: Map<string, IntermediateState>, dependencies: Set<string>) {
  if (Array.isArray(nodeToTest)) {
    nodeToTest.forEach(astChild => {
      getIntermediateDependencies(astChild, possibleIntermediates, dependencies);
    });
  } else {
    if (possibleIntermediates.has(nodeToTest)) {
      dependencies.add(nodeToTest);
    }
  }
}

type IntermediateState = {
  body: ASTNode;
  name: string;
  dependencies: Set<string>;
  firstUse: number;
  lastUse: number;
  bodyDefined: boolean
}
let createMultilayerFunction = (ast: ASTNode, compiler: LispsmosCompiler): ASTNode[] => {
  if (!Array.isArray(ast)) {
    throw new Error("LISPsmos Error: This should not be happening.")
  }
  let fnName = ast[1];
  if (Array.isArray(fnName)) {
    throw new Error(`LISPsmos Error: Multilayer function name must be string!`);
  }   
  let fnArgs = ast.slice(2, ast.length - 1);
  if (fnArgs.some(arg => Array.isArray(arg))) {
    throw new Error(`LISPsmos Error: Multilayer function args must be strings!`);
  }

  let fnBody = ast[ast.length - 1];
  if (!Array.isArray(fnBody)) {
    throw new Error(`LISPsmos Error: Multilayer function body must be a list of expressions!`);
  }
  let intermediates = new Map<string, IntermediateState>();
  for (let arg of fnArgs) {
    intermediates.set(arg as string, {
      body: arg,
      name: arg as string,
      dependencies: new Set<string>(),
      firstUse: 0,
      lastUse: undefined,
      bodyDefined: true
    })
  }

  let intermediateOrdering: string[] = [];
  fnBody.forEach((expr, i) => {
    let intermediateName = expr[0];
    let intermediateBody = expr[1];
    if (Array.isArray(intermediateName)) {
      throw new Error(`LISPsmos Error: Intermediate variable name cannot be a list!`);
    }
    if (getTokenType(intermediateName) != "variable") {
      throw new Error(`LISPsmos Error: Intermediate variable name cannot be '${intermediateName},' as '${intermediateName}' is a reserved word!`);
    }
    if (intermediates.get(intermediateName)) {
      throw new Error(`LISPsmos Error: Intermediate variables are immutable! Cannot reuse intermediate variable '${intermediateName}'!`);
    }
    if (!intermediateBody) {
      throw new Error(`LISPsmos Error: No intermediate variable body found for '${intermediateName}'.'`)
    }

    intermediateOrdering.push(intermediateName);
    let dependencies = new Set<string>();
    getIntermediateDependencies(intermediateBody, intermediates, dependencies);
    intermediates.set(intermediateName, {
      body: intermediateBody,
      dependencies: dependencies,
      firstUse: undefined,
      lastUse: undefined,
      name: intermediateName,
      bodyDefined: false
    });
  });

  let intermediateFunctionLocationIndices: Number[] = [0];

  intermediateOrdering.forEach((intermediateName, index) => {
    let intermediateInfo = intermediates.get(intermediateName);
    for (let dependency of intermediateInfo.dependencies) {
      let dependencyInfo = intermediates.get(dependency);
      if (dependencyInfo.firstUse === undefined) {
        dependencyInfo.firstUse = index;
        if (intermediateFunctionLocationIndices.indexOf(index) == -1) {
          intermediateFunctionLocationIndices.push(index);
        }
      }
      dependencyInfo.lastUse = index;
    }
  });

  let intermediateFunctionState: IntermediateState[][] = [];

  intermediateFunctionLocationIndices.forEach((locIndex, i) => {
    let intermediatesUsedInThisFunction = [];
    for (let intermediate of intermediates.values()) {
      if (intermediate.firstUse <= locIndex && locIndex <= intermediate.lastUse) {
        intermediatesUsedInThisFunction.push(intermediate);
      }
    }
    intermediateFunctionState.push(intermediatesUsedInThisFunction);
  });

  let intermediateFunctions: ASTNode[] = [];

  intermediateFunctionState.forEach((intermediatesUsedInThisFunction, i) => {
    let intermediateFunctionIndex = intermediateFunctionLocationIndices[i];
    let intermediateFunctionName = (i == 0) ? fnName : (fnName + "LISPSMOSIntermediate" + i);
    let nextFnName = (fnName + "LISPSMOSIntermediate" + (i+1)); 
    if (i == intermediateFunctionState.length - 1) {
      intermediateFunctions.push([
        "fn",
        intermediateFunctionName,
        ...(intermediatesUsedInThisFunction.map(iuitf => iuitf.name)),
        intermediates.get(intermediateOrdering[intermediateOrdering.length - 1]).body
        //intermediatesUsedInThisFunction.map(iuitf => iuitf.body)
      ])
    } else {
      intermediateFunctions.push([
        "fn",
        intermediateFunctionName,
        ...(intermediatesUsedInThisFunction.map(iuitf => iuitf.name)),
        [
          nextFnName,
          ...intermediateFunctionState[i+1].map(iuitf => {
            if (iuitf.bodyDefined) {
              return iuitf.name;
            } else {
              iuitf.bodyDefined = true;
              return iuitf.body;
            }
          })
        ]
        //intermediatesUsedInThisFunction.map(iuitf => iuitf.body)
      ])
    }
  });

  
  console.log(intermediates)
  console.log(intermediateOrdering)
  console.log(intermediateFunctionLocationIndices)
  console.log(intermediateFunctionState)
  console.log(intermediateFunctions);
  return intermediateFunctions;
}