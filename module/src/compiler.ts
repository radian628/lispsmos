import { 
  LISPsmosFailure, Maybe, ASTNode, getFailureMaybe, 
  makeInternalASTNode, success, ASTInternalNode, CodeLocation,
  ASTMap, Compiler, MacroFunction, ResourceImporter,
  CompilerOptions
} from "./common.js";
import { lex, parse } from "./lexer-and-parser.js";
import { State } from "./state.js";

function hasChildren(astNode: ASTNode) {
  return Array.isArray(astNode.content);
}

function copyCodeLocation(codeLoc: CodeLocation): CodeLocation {
  return Object.assign({}, codeLoc);
}

type ASTMapFunction = (astNode: ASTNode, i: number, arr?: ASTInternalNode[]) => Promise<ASTNode[]>;
async function mapASTNode(astNode: ASTInternalNode, fn: ASTMapFunction): Promise<ASTInternalNode> {
  let newContent = astNode.content.map(fn);
  let resolvedNewContent = (await Promise.all(newContent)).flat(1);
  return Object.assign(copyCodeLocation(astNode), {
    content: resolvedNewContent,
    tokenType: astNode.tokenType,
    nodeType: astNode.nodeType
  });
}

function unpack<T>(maybeValue: Maybe<T>): T {
  if (!maybeValue.success) {
    let failure = maybeValue.data as LISPsmosFailure;
    throw new Error(`Lines ${failure.startLineNo}-${failure.endLineNo}; Cols ${failure.startColNo}-${failure.endColNo}; LISPsmos ${failure.category.toUpperCase()} ERROR: ${failure.reason}`);
  }
  return maybeValue.data as T;
}


async function preprocess(ast: ASTNode, compiler: Compiler): Promise<Maybe<ASTNode[]>> {
  if (ast.nodeType == "internal") {
    //console.log(ast);
    let headNode = ast.content[0];
    if (headNode.nodeType == "internal") {
      return getFailureMaybe(ast, "syntax", "Expression must start with some sort of operation, not a list!");
    }
    let macro = compiler.macros.get(headNode.content);
    let maybeNewAST: Maybe<ASTNode[]> = success([ast]);
    let newAST: ASTNode[] = [ast];
    if (macro) {
      maybeNewAST = await macro(ast, compiler);
      newAST = unpack(maybeNewAST);
      return success((await Promise.all(newAST.map(newASTChild => preprocess(newASTChild, compiler)))).map(e => unpack(e)).flat(1));
    } else {
      return success([await mapASTNode(ast, async (astChild, index): Promise<ASTNode[]> => {
        return unpack(await preprocess(astChild, compiler));
      })]);

      
    }
    // newAST = await Promise.all(newAST.map(async newASTNode => {
    //   if (newASTNode.nodeType == "internal") {
    //     await mapASTNode(newASTNode, async (astChild, index) => {
    //       if (astChild.nodeType == "internal") {
    //         return unpack(await preprocess(astChild, compiler));
    //       }
    //       return astChild;
    //     });
    //   }
    // }))
    //return success([newAST]);
  } else {
    return success([ast]);
  }
}


const defaultOptions: CompilerOptions = {
  allowInlineJS: false,
  import: (query: string) => {
    throw new Error(`Cannot import '${query}': No import function specified in compiler options!`);
  },
  commentsAsNotes: false
};

export async function compile(str: string, options?: CompilerOptions) {
  if (!options) {
    options = defaultOptions
  }
  Object.entries(defaultOptions).forEach(([optName, optValue]) => {
    if (!options.hasOwnProperty(optName)) {
      //@ts-ignore
      options[optName] = optValue; //type-safe b/c both of these are CompilerOptions
    } 
  });
  let macroState = new Map<string, any>();
  
  let expressionIndex = 1;

  let compiler: Compiler = {
    getMacroState(macroName: string) {
      if (this.macroState.has(macroName)) {
        return macroState.get(macroName);
      }
      throw new Error(`Macro state for macro '${macroName}' not found.`);
    },
    variables: new Map<string, ASTNode>(),
    functions: new Map<string, ASTNode>(),
    macros: new Map<string, MacroFunction>(),
    calcState: {
      version: 9,
      graph: {
        viewport: {
          xmin: -10, xmax: 10, ymin: -10, ymax: 10
        }
      },
      expressions: {
        list: []
      }
    },
    import: options.import,
    options,
    getNewExpressionIndex() {
      return (expressionIndex++).toString();
    }
  };
  compiler.macros.set("inlineJS", async (ast: ASTInternalNode, c: Compiler): Promise<Maybe<ASTNode[]>> => {
    try {
      let functionNameNode = ast.content[1];
      if (!(functionNameNode.nodeType == "leaf" && functionNameNode.tokenType == "identifier")) {
        throw new Error("Inline JS macro name must be an identifier!");
      }
      let functionName = functionNameNode.content;
      let functionBodyNode = ast.content[2];
      if (functionBodyNode.nodeType == "leaf" && functionBodyNode.tokenType == "string_literal") {
        let macroFn = new Function("ast", "compiler", functionBodyNode.content);
        c.macros.set(functionName, async (ast2: ASTInternalNode, c2: Compiler): Promise<Maybe<ASTNode[]>> => {
          let ret;
          try {
            ret = macroFn(ast2, c2);
          } catch (err) {
            return getFailureMaybe(ast, "macro", `Failed to run inlineJS macro '${ast2.content[0].content as string}' due to the following: ${err.message}.`);
          }
          return ret;
        });
      } else {
        throw new Error(`Inline JS macro '${functionName}' body must be a string!`);
      }
    } catch (err) {
      return getFailureMaybe(ast, "macro", `Failed to create inlineJS macro: ${err.message}.`);
    }
    return success([]);
  });

  //lex
  let maybeLexedCode = lex(str);
  let lexedCode = unpack(maybeLexedCode);

  //parse
  let maybeParsedCode = parse(lexedCode);
  let parsedCode = unpack(maybeParsedCode);

  //preprocess
  let preprocessedAST = unpack(await preprocess(parsedCode, compiler));
  


  return compiler.calcState;
  //return JSON.stringify(preprocessedAST);
};