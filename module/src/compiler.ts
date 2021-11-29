import { ExpressionCompiler } from "./expression-compiler.js"
import { getTokenType, token, tokenTypes, extractStringFromLiteral,
DesmosState, ParametricDomain, DesmosExpression, ASTNode } from "./compiler-utils.js";

let defaultMacroRegex = /a^/y;

let macros;


export function stringToTokenStream(str: string): string[][] {
  let index = 0;
  let tokens = [];
  while (index < str.length) {
    let matched = false;
    for (const [tokenName, tokenRegexp] of tokenTypes) {
      tokenRegexp.lastIndex = index;
      //@ts-ignore
      let matches = tokenRegexp[Symbol.match](str);
      if (matches !== null) {
        let match = matches[0];
        tokens.push([tokenName, match]);
        index += match.length;
        matched = true;
        break;
      }
    }
    if (!matched) {
      throw new Error(`Lexing Failed: SyntaxError starting at the following character: ${str.slice(index, Math.min(str.length,index+100))}`);
    }
  }
  return tokens;
}





export function tokenStreamToAST(tokenStream: string[][]) {
  return _tokenStreamToAST(tokenStream.filter(e => e[0] != "whitespace").map(e => e[1]));
}

function _tokenStreamToAST(tokenStream: string[]) {
  let astStack: Array<ASTNode>[] = [[]];
  for (let tokenValue of tokenStream) {
    let tokenType = getTokenType(tokenValue);
    switch (tokenType) {
    case "parenthesis":
      switch (tokenValue) {
      case "(":
        let newList: ASTNode = [];
        astStack[astStack.length-1].push(newList);
        astStack.push(newList);
        break;
      case ")":
        astStack.pop();
        break;
      }
    case "whitespace":
      break;
    default: astStack[astStack.length-1].push(tokenValue);
      break;
    }
  }
  return astStack[0];
}









export type MacroFunc = (ast: ASTNode[], compiler: LispsmosCompiler) => ASTNode[];

export class LispsmosCompiler {
  macros: Map<string, MacroFunc>;
  macroState: any;
  shouldReapplyMacros: boolean;
  expressionCompiler: ExpressionCompiler;
  currentExpressionID: number;
  currentFolderID: number;
  desmosState: DesmosState;
  ast: ASTNode;
  events: {
    init: Function[];
  }

  constructor () {
    this.macros = new Map();
    this.events = {
      init: []
    };
  }

  compile(src: string): DesmosState {
    this.macroState = {};
    this.compileAST(tokenStreamToAST(stringToTokenStream(src)));
    console.log(this.desmosState);
    return this.desmosState;
  }

  registerMacro(macroName: string, macroFn: MacroFunc): void {
    if (this.macros.get(macroName)) {
      throw new Error(`LISPsmos Error: Macro ${macroName} is already defined!`);
    }
    this.macros.set(macroName, macroFn);
  }

  registerEvent(eventName: "init", handler: Function): void {
    this.events[eventName].push(handler);
  }

  compileAST(ast: ASTNode) {
    //setup
    this.ast = ast;
    this.currentExpressionID = 0;
    this.currentFolderID = undefined;
    this.desmosState = {
      "version": 9,
      "randomSeed": "f8731634d5d57a05dabd714121ac9b91",
      "graph": {
        "viewport": {
          "xmin": -10,
          "ymin": -10,
          "xmax": 10,
          "ymax": 10
        }
      },
      "expressions": {
        "list": [
        ]
      }
    };

    //preprocessing
    this.shouldReapplyMacros = true;
    while (this.shouldReapplyMacros) {
      this.shouldReapplyMacros = false;
      this.ast = this.applyMacros(this.ast);
    }

    //create expression compiler
    this.expressionCompiler = new ExpressionCompiler();

    this.astNodeToDesmosState(this.ast);
    return this.desmosState;
  }

  applyMacros(ast: ASTNode): ASTNode {
    return this.applyMacrosInternal(ast);
  }
  
  applyMacrosInternal(ast: ASTNode): ASTNode {
    if (Array.isArray(ast)) {
      switch (typeof ast[0]) {
        case "string":
          if (typeof this.macros.get(ast[0]) == "function") {
            console.log("Ran macro " + ast[0]);
            this.shouldReapplyMacros = true;
            return this.macros.get(ast[0])(ast, this);
          } else {
            let newAST: ASTNode = [];
            for (let astChild of ast) {
              newAST = newAST.concat(this.applyMacrosInternal(astChild));
            }
            return [newAST];
          }
        case "object":
          let newAST: ASTNode = [];
          for (let astChild of ast) {
            newAST = newAST.concat(this.applyMacrosInternal(astChild));
          }
          return [newAST];
      }
    } else {
      return ast;
    }
  }

  astNodeToDesmosState(astNode: ASTNode) {
    if (Array.isArray(astNode)) {
        switch (typeof astNode[0]) {
          case "string":
            switch (astNode[0]) {
              case "displayMe":
                this.desmosState.expressions.list.push(this.astNodeToDisplayedExpression(astNode))
                break;
              case "ticker":
                this.desmosState.expressions.ticker = {
                  handlerLatex: this.expressionCompiler.astNodeToDesmosExpressions(astNode[1]), open: true
                };
                break;
              case "viewport":
                if (astNode.length != 5) {
                  throw new Error("LISPsmos Error: Viewport bounds must be specified as four numbers!");
                }
                if (!astNode.slice(1).every(v => (typeof v == "string"))) {
                  throw new Error("LISPsmos Error: Viewport bounds must be strings!");
                }
                let astNodeStr = (astNode as string[]);
                this.desmosState.graph.viewport = {
                  xmin: parseFloat(astNodeStr[1]),
                  xmax: parseFloat(astNodeStr[2]),
                  ymin: parseFloat(astNodeStr[3]),
                  ymax: parseFloat(astNodeStr[4]),
                }
                break;
              case "folder":
                this.astNodeToFolder(astNode);
                break;
              default:
                let defaultExpression: DesmosExpression = {
                  "hidden": true,
                  "type": "expression",
                  "id": (this.currentExpressionID++).toString(),
                  "color": "#000000",
                  "latex": this.expressionCompiler.astNodeToDesmosExpressions(astNode)
                };
                if (this.currentFolderID !== undefined) {
                  defaultExpression.folderId = this.currentFolderID.toString();
                }
                this.desmosState.expressions.list.push(defaultExpression);
                break;
            }
            //outStr += astListToDesmosExpressions(astNode);
            break;
          case "object":
            for (let astChildNode of astNode) {
              this.astNodeToDesmosState(astChildNode);
            }
            break;
        }
    } else {
        throw new Error("No top level primitives (i might have screwed up the implementation for this).")
        //outStr += astPrimitiveToDesmos(astNode);
    }
    //return outObj;
  }

  astNodeToFolder(astNode: Array<ASTNode>) {
    if (this.currentFolderID != undefined) throw new Error("No nested folders!");

    let folderState: DesmosExpression = {
      type: "folder",
      id: (this.currentExpressionID++).toString(),
      collapsed: true
    };

    if (!Array.isArray(astNode[1])) {
      throw new Error("Folder settings must be a list!");
    }
    for (let astChild of astNode[1]) {
      switch (astChild[0]) {
        case "title":
          if (Array.isArray(astChild[1])) {
            throw new Error("Folder title must be a string!");
          }
          folderState.title = extractStringFromLiteral(astChild[1]);
          break;
        case "expanded":
          folderState.collapsed = false;
          break;
        default:
          throw new Error(`LISPsmos Error: Unknown folder setting ${astChild[0]}`)
      }
    }
    
    this.currentFolderID = parseInt(folderState.id);
    this.desmosState.expressions.list.push(folderState);
    for (let astChild of astNode.slice(2)) {
      this.astNodeToDesmosState(astChild);
    }
    this.currentFolderID = undefined;
  }

  astNodeToDisplayedExpression(astNode: Array<ASTNode>) {
    let defaultExpression: DesmosExpression = {
      "type": "expression",
      "id": (this.currentExpressionID++).toString(),
      "color": "#000000",
      "latex": this.expressionCompiler.astNodeToDesmosExpressions(astNode[1]),
    }
    if (this.currentFolderID !== undefined) {
      defaultExpression.folderId = this.currentFolderID.toString();
    }
    for (let astChild of astNode.slice(2)) {
      switch (astChild[0]) {
        case "lineOpacity":
        case "lineWidth":
        case "pointOpacity":
        case "pointSize":
        case "colorLatex":
        case "fillOpacity":
          defaultExpression[astChild[0]] = this.expressionCompiler.astNodeToDesmosExpressions(astChild[1]);
          break;
        case "lineStyle":
        case "pointStyle":
        case "color":
          if (typeof astChild[1] != "string") {
            throw new Error(`LISPsmos Error: Expression display property ${astChild[0]} must be a string!`);
          }
          defaultExpression[astChild[0]] = astChild[1];
          break;
        case "parametricDomain":
          if (!Array.isArray(astChild)) {
            throw new Error(`LISPsmos Error: Parametric domain must be a list, as it can contain multiple values.`)
          }
          defaultExpression.parametricDomain = this.getParametricJSON(astChild);
          break;
        case "clickableInfo":
          defaultExpression.clickableInfo = {
            enabled: true,
            latex: this.expressionCompiler.astNodeToDesmosExpressions(astChild[1])
          };
          break;
        case "fill":
        case "lines":
          defaultExpression[astChild[0]] = (astChild[1] == "true");
          break;
        default:
          throw new Error(`LISPsmos Error: Unknown displayed expression property '${astChild[0]}'`);
      }
    }
    return defaultExpression;
  }

  getParametricJSON(astList: Array<ASTNode>) {
    let parametricJSON: ParametricDomain = { min: "0", max: "1" };
    for (let parametricSetting of astList.slice(1)) {
      switch (parametricSetting[0]) {
        case "min":
        case "max":
          parametricJSON[parametricSetting[0]] = this.expressionCompiler.astNodeToDesmosExpressions(parametricSetting[1]);
          break;
        default:
          throw new Error("Unidentified parametric setting: " + parametricSetting[0]);
      }
    }
    return parametricJSON;
  }
};

// export function astToDesmosExpressions(ast: ASTNode) {
//   let exprId = 0;
//   let desmosState: DesmosState = {
//   "version": 9,
//   "randomSeed": "f8731634d5d57a05dabd714121ac9b91",
//   "graph": {
//     "viewport": {
//       "xmin": -10,
//       "ymin": -10,
//       "xmax": 10,
//       "ymax": 10
//     }
//   },
//   "expressions": {
//     "list": [
//     ]
//   }
//   };
  
//   let currentFolder: number = undefined;
//   macros = macrosDefined;
//   if (!macrosDefined) macros = {};
//   let globalAST: ASTNode = [];
//   let globalHelperState: LispsmosGlobalState = {};
//   globalHelperState.macros = macros;
//   globalHelperState.globalExpressions = globalAST;

//   globalHelperState.reapplyMacros = true;
//   while (globalHelperState.reapplyMacros) {
//     globalHelperState.reapplyMacros = false;
//     ast = applyMacros(ast, macros, globalHelperState);
//   }

//   let expressionCompiler = new ExpressionCompiler(globalHelperState);

//   globalHelperState.expressionCompiler = expressionCompiler;
//   {
//     let compiledExprs = astNodeToDesmosState(ast);
//     let compiledGlobalState = astNodeToDesmosState(globalAST);
//     return JSON.stringify(desmosState);

//   }
// }

// export function transpileLisp(str, macros) {
//   return astToDesmosExpressions(tokenStreamToAST(stringToTokenStream(str)), macros);
// }

export function parse(str: string): ASTNode {
  return tokenStreamToAST(stringToTokenStream(str));
}