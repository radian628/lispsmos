import { ASTNode, Compiler, getFailureMaybe, getLispsmosFailure, LISPsmosFailure } from "./common";
import {builtins, operators} from "./builtins";

interface ASTValidatorContext {

}

function findASTErrors(ast: ASTNode, compiler: Compiler, context: ASTValidatorContext): LISPsmosFailure | true {
  if (ast.nodeType == "internal") {
    let firstChild = ast.content[0];
    if (firstChild.nodeType != "leaf") {
      return getLispsmosFailure(ast, "semantics", `Unless otherwise specified, the first datum of an expression must be a function, macro or operator, not a list.`);
    }
    let isBuiltin = builtins.indexOf(firstChild.content) != -1;
    let isOperator = operators.indexOf(firstChild.content) != -1;
    let isFunction = Array.from(compiler.functions.keys()).indexOf(firstChild.content) != -1;
    if (!(isBuiltin || isOperator || isFunction)) {
      return getLispsmosFailure(ast, "semantics", "The first datum of an expression must be a function, macro, or operator. None of these was found.");
    }
  }
  return true;
}