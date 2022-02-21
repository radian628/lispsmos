import { LispsmosCompiler } from "./compiler.js";
import { ASTNode } from "./compiler-utils.js";
import { parse } from "./compiler.js";

function doProceduralWrapping(msp: any, astNode: ASTNode, counterExpr?: ASTNode) {
  let config = msp.config;
  let action;
  if (!counterExpr) {
    counterExpr = parse(
      `-> ${config.programCounter} (+ ${config.programCounter} 1)`
    );
  }
  if (counterExpr.length != 0) {
    action = [",", astNode, counterExpr];
  } else {
    action = astNode;
  }
  return [[
    ["=", config.programCounter, msp.counter.toString()],
    action,
  ]];
}




//TODO: FIX WHILE LOOPS
function whileLoopToAST(astList: Array<ASTNode>, msp: any) {
  // let config = globalState.procedure.config;
  // let stepsContainer = [];

  // let counterStart = globalState.procedure.counter;
  // globalState.procedure.counter++;
  // for (let astChild of astList.slice(2, astList.length - 1)) {
  //   stepsContainer.push(...getProceduralExpressionAST(astChild, globalState));
  //   globalState.procedure.counter++;
  // }

  // let counterEnd = globalState.procedure.counter;

  // globalState.procedure.counter = counterStart;
  // stepsContainer = getProceduralExpressionAST(
  //   [
  //     "piecewise",
  //     [
  //       astList[1],
  //       parse(`-> ${config.programCounter} (+ ${config.programCounter} 1)`),
  //     ],
  //     [["->", config.programCounter, (counterEnd + 1).toString()]],
  //   ],
  //   globalState,
  //   []
  // ).concat(stepsContainer);
  // globalState.procedure.counter = counterEnd;

  // let endCounterAction = ["->", config.programCounter, counterStart.toString()];
  // stepsContainer.push(
  //   ...getProceduralExpressionAST(
  //     astList[astList.length - 1],
  //     globalState,
  //     endCounterAction
  //   )
  // );
  // return stepsContainer;

  let config = msp.config;
  let stepsContainer: ASTNode = [];

  let firstInstruction = astList[2];
  if (!Array.isArray(firstInstruction)) {
    throw new Error("LISPsmos Error: Procedural instruction must be a list!");
  }

  let isFirstInstructionWrapped = isWrappingHandledByChildren(firstInstruction);

  let counterStart = msp.counter;
  //add first child if handled separately
  if (isFirstInstructionWrapped) {
    msp.counter++;
    stepsContainer.push(...getProceduralExpressionAST(firstInstruction, msp));
  }

  // handle while loop body
  msp.counter++;
  for (let astChild of astList.slice(3, astList.length-1)) {
    if (!Array.isArray(astChild)) {
      throw new Error("LISPsmos Error: Procedural instruction must be a list!");
    }
    let transformedAST = getProceduralExpressionAST(astChild, msp);
    if (!isWrappingHandledByChildren(astChild)) {
      transformedAST = doProceduralWrapping(msp, transformedAST);
    }
    stepsContainer.push(...transformedAST);
    msp.counter++;
  }

  //handle jump instruction at beginning of while loop
  let counterEnd = msp.counter - 1;
  let jumpInstructions = [];
  if (!isFirstInstructionWrapped) {
    // if the first instruction is a primitive, merge the two together
    msp.counter = counterStart;
    jumpInstructions = doProceduralWrapping(
      msp,
      [
        "piecewise",
        [
          astList[1],
          [
            ",",
            astList[2],
            parse(`-> ${config.programCounter} (+ ${config.programCounter} 1)`),
          ],
        ],
        [["->", config.programCounter, (counterEnd + 1).toString()]],
      ],
      []
    );
    msp.counter = counterEnd;
  } else {
    //if the first instruction is not a primitive, handle the two separately
    msp.counter = counterStart;
    let actualJumpInstruction = doProceduralWrapping(msp, [
      "piecewise",
      [
        astList[1],
        parse(`-> ${config.programCounter} (+ ${config.programCounter} 1)`),
      ],
      [["->", config.programCounter, (counterEnd + 1).toString()]]
    ], []);
    jumpInstructions = [
      ...actualJumpInstruction
    ];
    msp.counter = counterEnd;
  }
  //add the beginning jump instruction
  stepsContainer = jumpInstructions.concat(stepsContainer);

  //end jump instruction
  let lastInstruction = astList[astList.length - 1];
  if (!Array.isArray(lastInstruction)) {
    throw new Error("LISPsmos Error: Procedural instruction must be a list!");
  }
  
  let isLastInstructionWrapped = isWrappingHandledByChildren(lastInstruction);
  let conditionalJump = [[
    astList[1],
    parse(`-> ${config.programCounter} ${counterStart}`)
  ],
  ["->", config.programCounter, ["+", config.programCounter, "1"]]]
  if (isLastInstructionWrapped) {
    //if last instruction is a compound instruction, handle separately
    msp.counter++;
    if (firstInstruction != lastInstruction) {
      stepsContainer.push(...getProceduralExpressionAST(lastInstruction, msp));
      msp.counter++;
    }
    stepsContainer = stepsContainer.concat(doProceduralWrapping(msp, [
      "piecewise",
      ...conditionalJump
    ], []));
  } else {
    //if last instruction is not, combine.
    
    msp.counter++; 
    stepsContainer = stepsContainer.concat(doProceduralWrapping(msp, (firstInstruction != lastInstruction) ? [
      ",",
      lastInstruction,
      [
        "piecewise",
        ...conditionalJump
      ]
    ] : [
      "piecewise",
      ...conditionalJump
    ], []));
  }

  return stepsContainer;
}






function ifStatementToAST(astList: Array<ASTNode>, msp: any) {
  let config = msp.config;
  let stepsContainer = [];
  let firstInstruction = astList[2];

  if (!Array.isArray(firstInstruction)) {
    throw new Error("LISPsmos Error: Procedural instruction must be a list!");
  }

  let isFirstInstructionWrapped = isWrappingHandledByChildren(firstInstruction);

  let counterStart = msp.counter;
  //add first child if handled separately
  if (isFirstInstructionWrapped) {
    msp.counter++;
    stepsContainer.push(...getProceduralExpressionAST(firstInstruction, msp));
  }

  // handle if statement body
  msp.counter++;
  for (let astChild of astList.slice(3, astList.length)) {
    if (!Array.isArray(astChild)) {
      throw new Error("LISPsmos Error: Procedural instruction must be a list!");
    }
    let transformedAST = getProceduralExpressionAST(astChild, msp);
    if (!isWrappingHandledByChildren(astChild)) {
      transformedAST = doProceduralWrapping(msp, transformedAST);
    }
    stepsContainer.push(...transformedAST);
    msp.counter++;
  }

  //handle jump instruction at beginning of if statement
  let counterEnd = msp.counter - 1;
  let jumpInstructions = [];
  if (!isFirstInstructionWrapped) {
    // if the first instruction is a primitive, merge the two together
    msp.counter = counterStart;
    jumpInstructions = doProceduralWrapping(
      msp,
      [
        "piecewise",
        [
          astList[1],
          [
            ",",
            astList[2],
            parse(`-> ${config.programCounter} (+ ${config.programCounter} 1)`),
          ],
        ],
        [["->", config.programCounter, (counterEnd + 1).toString()]],
      ],
      []
    );
    msp.counter = counterEnd;
  } else {
    //if the first instruction is not a primitive, handle the two separately
    msp.counter = counterStart;
    let actualJumpInstruction = doProceduralWrapping(msp, [
      "piecewise",
      [
        astList[1],
        parse(`-> ${config.programCounter} (+ ${config.programCounter} 1)`),
      ],
      [["->", config.programCounter, (counterEnd + 1).toString()]]
    ], []);
    jumpInstructions = [
      ...actualJumpInstruction
    ];
    msp.counter = counterEnd;
  }

  stepsContainer = jumpInstructions.concat(stepsContainer);

  return stepsContainer;
}





// function procedureCallToAST(astList, globalState) {
//   let config = globalState.procedure.config;
//   let procPtr = globalState.procedure.procedures[astList[1]];
//   if (typeof procPtr.pointer != "number") {
//     throw new Error(`Unidentified procedure ${astList[1]}`);
//   }
//   let returnAST = getProceduralExpressionAST(
//     [
//       ",",
//       ["->", config.programCounter, procPtr.pointer.toString()],
//       parse(
//         `-> ${config.pointerStack} (join ${config.pointerStack} (list (+ ${config.programCounter} 1)))`
//       ),
//     ],
//     globalState,
//     []
//   );
//   return returnAST;
// }




function getProceduralExpressionAST(astList: Array<ASTNode>, msp: any): Array<ASTNode> {
  let config = msp.config;
  //let counterAction = parse(`-> ${config.programCounter} (+ ${config.programCounter} 1)`)//["->", "lispsmosCounter", ["+", "lispsmosCounter", "1"]];
  switch (astList[0]) {
    case "while":
      return whileLoopToAST(astList, msp);
    case "if":
      return ifStatementToAST(astList, msp);
    // case "callprocedure":
    //   return procedureCallToAST(astList, msp);
    default:
      return astList;
  }
}

function isWrappingHandledByChildren(astList: Array<ASTNode>) {
  switch (astList[0]) {
    case "while":
    case "if":
    case "callprocedure":
      return true;
  }
  return false;
}

type ProceduralConfig = {
  entryPoint: string,
  desmosEntryPoint: string,
  programCounter: string,
  pointerStack: string
};

type ProceduralState = {
  config: ProceduralConfig,
  root: Array<ASTNode>
}

function getDefaultConfig(): ProceduralConfig {
  return {
    entryPoint: "main",
    desmosEntryPoint: "lispsmosMain",
    programCounter: "lispsmosCounter",
    pointerStack: "lispsmosPointerStack",
  };
}

export function register(c: LispsmosCompiler) {
  c.registerMacro("procedureConfig", (ast, compiler): Array<ASTNode> => {
    if (compiler.macroState.procedure) {
      throw new Error(
        "LISPsmos Error: procedureConfig must be placed before any procedures!"
      );
    } else {
      compiler.macroState.procedure = {};
    }
    let msp = compiler.macroState.procedure;
    let config = getDefaultConfig();
    msp.config = config;
    for (let setting of ast.slice(1)) {
      if (!Array.isArray(setting)) {
        throw new Error(`LISPsmos Error: Procedure Macro Error: Setting must be a list!`);
      }
      let settingName = setting[0];
      if (Array.isArray(settingName)) {
        throw new Error(`LISPsmos Error: Procedure config setting name cannot be a list!`);
      }
      switch (settingName) {
        case "entryPoint":
        case "desmosEntryPoint":
        case "programCounter":
        case "pointerStack":
          let settingValue = setting[1];
          if (Array.isArray(settingValue)) {
            throw new Error(`LISPsmos Error: Procedure config setting ${settingValue} cannot have list value!`);
          }
          config[settingName] = settingValue;
          break;
        default:
          throw new Error(
            `LISPsmos Error: Unidentified procedure configuration setting: ${setting[0]}`
          );
      }
    }
    return [];
  });
  c.registerMacro("procedure", (ast, compiler): Array<ASTNode> => {
    //init global state for entry point (main) if haven't already

    let ms = compiler.macroState;
    if (!ms.procedure) ms.procedure = {};
    let msp = compiler.macroState.procedure;
    if (!msp.config)
    msp.config = getDefaultConfig();
    if (!msp.root) {
      let root: Array<ASTNode> = [];
      let procedurePiecewiseRoot: ASTNode = [];
      root.push(procedurePiecewiseRoot);

      msp.root = root;
      //astGlobal.push(root); TODO: fix this
      let procPiecewise = ["piecewise"];
      msp.piecewise = procPiecewise;
      msp.counter = 0;
      msp.procedures = {};
      procedurePiecewiseRoot.push(
        "fn",
        msp.config.desmosEntryPoint,
        procPiecewise
      );
    }
    if (!msp.returnPointerStack) {
      let returnPointerStack = parse(
        `(= ${msp.config.pointerStack} (list -1))`
      );
      msp.root.push(returnPointerStack);
      msp.returnPointerStack = returnPointerStack;
    }

    let procedureName = ast[1];
    if (Array.isArray(procedureName)) {
      throw new Error("LISPsmos Error: Procedure name cannot be list!");
    }

    let returnValue = [];
    if (procedureName == msp.config.entryPoint) {
      returnValue = msp.root;
      msp.root.push([
        "=",
        msp.config.programCounter,
        msp.counter.toString(),
      ]);
    }
    msp.procedures[procedureName] = {
      pointer: msp.counter,
    };
    let config = msp.config;

    //actually do the thing
    let piecewise = msp.piecewise;
    for (let astChild of ast.slice(2)) {
      if (!Array.isArray(astChild)) {
        throw new Error("Procedure statement cannot be top level string");
      }
      if (isWrappingHandledByChildren(astChild)) {
        let proceduralExpr = getProceduralExpressionAST(astChild, msp);
        piecewise.push(...proceduralExpr);
      } else {
        piecewise.push(...doProceduralWrapping(msp, astChild));
      }
      msp.counter++;
    }
    
    //callstack pop
    let callstackPopper = doProceduralWrapping(msp, 
      parse(`, (-> ${config.programCounter} ([] ${config.pointerStack} (length ${config.pointerStack}))) 
    (-> ${config.pointerStack} ([] ${config.pointerStack} 1 ... (- (length ${config.pointerStack}) 1)))`), []
    )
    piecewise.push(...callstackPopper);
    msp.counter++;
    return returnValue;
  });
}