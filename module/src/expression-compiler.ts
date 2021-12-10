
import { getTokenType, token, tokenTypes, extractStringFromLiteral, ASTNode } from "./compiler-utils.js";

export class ExpressionCompiler {
  constructor () {

  }

  astPrimitiveToDesmos(astPrimitive: string) {
    let type = getTokenType(astPrimitive);
    switch (type) {
    case "variable":
      let parsedVarName = astPrimitive.replace(/\_/g, "LISPSMOSUNDERSCORE");
      return (parsedVarName.length == 1) ? parsedVarName : `${parsedVarName.charAt(0)}_{${parsedVarName.slice(1)}}`;
    case "other":
      return `\\operatorname{${astPrimitive}}`;
    default:
      return astPrimitive;
    }
  }

  astNodeToDesmosExpressions(astNode: ASTNode) {
    let outStr = "";
    switch (typeof astNode) {
      case "object":
        switch (typeof astNode[0]) {
          case "object":
            console.log(astNode);
            for (let astChildNode of astNode) {
              outStr += this.astNodeToDesmosExpressions(astChildNode) + "\n";
            }
            break;
          case "string":
            outStr += this.astListToDesmosExpressions(astNode);
            break;
        }
        break;
      case "string":
        outStr += this.astPrimitiveToDesmos(astNode);
        break;
    }
    return outStr;
  }

  naryOperatorToDesmosExpressions(astList: Array<ASTNode>, noParens?: boolean) {
    let op = astList[0];
    if (op == "==") op = "=";
    if (op == "->") op = "\\to ";
    if (op == ">=") op = "\\ge ";
    if (op == "<=") op = "\\le ";
    let outArr = [];
    for (let astNode of astList.slice(1)) {
      outArr.push(this.astNodeToDesmosExpressions(astNode));
    }
    return `${noParens ? "" : "\\left("}${outArr.join(op as string)}${noParens ? "" : "\\right)"}`;
  }

  binaryOperatorToDesmosExpressions(astList: Array<ASTNode>, noParens?: boolean) {
    if (astList.length == 3) {
      return this.naryOperatorToDesmosExpressions(astList, noParens);
    } else {
      throw new Error(`LISPsmos Error: Binary operations can only accept two arguments. Offending AST section: ${JSON.stringify(astList)}`);
    }
  }

  fracToDesmosExpressions(astList: Array<ASTNode>) {
    let operandsExceptLast = astList.slice(2);
    let firstOperand = astList[1];
    //let operandsExceptLast = operandsExceptLast.reverse();
    let str = this.astNodeToDesmosExpressions(firstOperand);
    for (let operand of operandsExceptLast) {
      str = `\\frac{${str}}{${this.astNodeToDesmosExpressions(operand)}}`;
    }
    return str;
  }

  exponentToDesmosExpressions(astList: Array<ASTNode>) {
    let operandsExceptLast = astList.slice(2);
    let firstOperand = astList[1];
    //let operandsExceptLast = operandsExceptLast.reverse();
    let str = this.astNodeToDesmosExpressions(firstOperand);
    for (let operand of operandsExceptLast) {
      str = `${str}^{${this.astNodeToDesmosExpressions(operand)}}`;
    }
    return str;
  }

  piecewiseToDesmosExpressions(astList: Array<ASTNode>) {
    let conditions = [];
    for (let condition of astList.slice(1)) {
      if (condition.length == 2) {
        if (!Array.isArray(condition[0])) {
          throw new Error(`LISPsmos Error: Piecewise condition must be a list. Received '${condition[0]}'`)
        }
        let predicate = this.naryOperatorToDesmosExpressions(condition[0], true);
        let result = this.astNodeToDesmosExpressions(condition[1])
        conditions.push(`${predicate}:${result}`);
      } else if (condition.length == 1) {
        conditions.push(this.astNodeToDesmosExpressions(condition[0]));
      }
    }
    return `\\left\\{${conditions.join(",")}\\right\\}`;
  }

  pointToDesmosExpressions(astList: Array<ASTNode>) {
    return `\\left(${this.astNodeToDesmosExpressions(astList[1])},${this.astNodeToDesmosExpressions(astList[2])}\\right)`;
  }

  listToDesmosExpressions(astList: Array<ASTNode>) {
    return `\\left[${this.commaSeparatedList(astList.slice(1))}\\right]`
  }

  postfixToDesmosExpressions(astList: Array<ASTNode>) {
    return `${this.astNodeToDesmosExpressions(astList[1])}${this.astNodeToDesmosExpressions(astList[0])}`
  }

  listIndexAccessToDesmosExpression(astList: Array<ASTNode>) {
    let listName = this.astNodeToDesmosExpressions(astList[1]);
    return `${listName}\\left[${astList.slice(2).map(this.astNodeToDesmosExpressions.bind(this)).join("")}\\right]`
  }

  sumProdToDesmosExpression(astList: Array<ASTNode>) {
    let operatorName = astList[0];
    let boundVar = this.astNodeToDesmosExpressions(astList[1]);
    let lowerBound = this.astNodeToDesmosExpressions(astList[2]);
    let upperBound = this.astNodeToDesmosExpressions(astList[3]);
    let body = this.astNodeToDesmosExpressions(astList[4]);
    return `\\${operatorName}_{${boundVar}=${lowerBound}}^{${upperBound}}\\left(${body}\\right)`;
  }

  curlyBraceUnaryOperatorToDesmosExpression(astList: Array<ASTNode>) {
    let operatorName = astList[0];
    let operandName = this.astNodeToDesmosExpressions(astList[1]);
    return `\\${operatorName}{${operandName}}`;
  }

  composeDesmosFunction(astList: Array<ASTNode>) {
    let composeCount: number;
    try {
      composeCount = parseInt(astList[1] as string);
    } catch {
      throw new Error("LISPsmos Error: Invalid composition count.");
    }
    let paramsASTList = astList.slice(3);
    let newAST: Array<ASTNode> = [];
    let originalAST = newAST;
    for (let i = 0; i < composeCount; i++) {
      let astChild = [];
      astChild.push(astList[2]);
      newAST.push(astChild);
      newAST = astChild;
    }
    newAST.push(paramsASTList[0]);
    return this.astNodeToDesmosExpressions(originalAST);
  }

  listComprehensionToDesmosExpression(astList: Array<ASTNode>) {
    let loopedStatement = this.astNodeToDesmosExpressions(astList[1]);
    let iterators = [];
    for (let iteratorVar of astList.slice(2)) {
      iterators.push(["=", iteratorVar[0], iteratorVar[1]]);
    }
    let allIterators = this.commaSeparatedList(iterators);
    return `\\left[${loopedStatement}\\operatorname{for}${allIterators}\\right]`;
  }

  commaSeparatedList(astList: Array<ASTNode>) {
    let outArr = [];
    for (let astNode of astList) {
      outArr.push(this.astNodeToDesmosExpressions(astNode));
    }
    return outArr.join(",");
  }

  builtinToDesmosExpressions(astList: Array<ASTNode>) {
    return `\\operatorname{${astList[0]}}\\left(${this.commaSeparatedList(astList.slice(1))}\\right)`;
  }
  fnCallToDesmosExpressions(astList: Array<ASTNode>) {
    return `${this.astNodeToDesmosExpressions(astList[0])}\\left(${this.commaSeparatedList(astList.slice(1))}\\right)`;
  }

  functionToDesmosExpression(astList: Array<ASTNode>) {
    let fnBody = this.astNodeToDesmosExpressions(astList[astList.length - 1]);
    let fnName = this.astNodeToDesmosExpressions(astList[1]);
    let fnArgs = this.commaSeparatedList(astList.slice(2, astList.length - 1));
    return `${fnName}\\left(${fnArgs}\\right)=${fnBody}`;
  }

  astListToDesmosExpressions(astList: Array<ASTNode>) {
    if (Array.isArray(astList[0])) {
      throw new Error("LISPsmos Error: String must be in first position of this list!");
    }
    let firstListElemType = getTokenType(astList[0]);
    switch (firstListElemType) {
    case "operator":
      switch (astList[0]) {
      case "+":
      case "-":
      case "*":
      case ",":
        return this.naryOperatorToDesmosExpressions(astList);
      case ">":
      case "<":
      case ">=":
      case "<=":
        return this.naryOperatorToDesmosExpressions(astList, true);
      case "==":
      case "->":
        return this.binaryOperatorToDesmosExpressions(astList, true);
      case "/":
        return this.fracToDesmosExpressions(astList);
      case "^":
        return this.exponentToDesmosExpressions(astList);
      case "=":
        return this.binaryOperatorToDesmosExpressions(astList, true);
      }
      break;
    case "keyword":
      switch (astList[0]) {
      case "piecewise":
        return this.piecewiseToDesmosExpressions(astList);
      case "point":
        return this.pointToDesmosExpressions(astList);
      case "list":
        return this.listToDesmosExpressions(astList);
      case ".x":
      case ".y":
        return this.postfixToDesmosExpressions(astList);
      case "[]":
        return this.listIndexAccessToDesmosExpression(astList);
      case "fn":
        return this.functionToDesmosExpression(astList);
      case "sum":
      case "prod":
        return this.sumProdToDesmosExpression(astList);
      case "sqrt":
        return this.curlyBraceUnaryOperatorToDesmosExpression(astList);
      case "compose":
        return this.composeDesmosFunction(astList);
      case "comprehension":
        return this.listComprehensionToDesmosExpression(astList);
      }
    case "builtin":
      return this.builtinToDesmosExpressions(astList);
    case "variable":
      return this.fnCallToDesmosExpressions(astList);
    }
  }
}