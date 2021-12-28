//
import { 
  Token, LISPsmosFailure, ASTNode, CodeLocation, 
  ErrorCategory, tokenTypes, TokenTypeName, makeInternalASTNode, 
  getLispsmosFailure, Maybe, getFailureMaybe, failure, success 
} from "./common.js"

export function lex(str: string): Maybe<Token[]> {
  let lineNumber = 1;
  let colNumber = 1;
  let index = 0;
  let tokens: Token[] = [];
  while (index < str.length) {
    let matched = false;
    for (const { pattern, name } of tokenTypes) {
      pattern.lastIndex = index;
      let matches = pattern[Symbol.match](str);
      if (matches !== null) {
        let match = matches[0];

        let newlines = (/\n/g)[Symbol.match](match);
        if (newlines == null) newlines = [];

        let endColNumber: number = colNumber + match.length;

        if (newlines.length != 0) {
          endColNumber = (/\n[^\n]*$/g)[Symbol.match](match).length - 1;
        }

        tokens.push({
          startLineNo: lineNumber,
          endLineNo: lineNumber + newlines.length,
          startColNo: colNumber,
          endColNo: endColNumber,
          content: match,
          tokenType: name
        });

        index += match.length;
        lineNumber += newlines.length;
        colNumber = endColNumber;

        matched = true;
        break;
      }
    }
    if (!matched) {
      return failure<Token[]>({
        category: "syntax",
        reason: "Tokenization failed!",
        startLineNo: lineNumber,
        startColNo: colNumber,
        endLineNo: lineNumber,
        endColNo: colNumber + 1,
        isFailure: true
      });
    }
  }
  return success(tokens);
}

function astLeafNodeFromToken(token: Token): ASTNode {
  return {
    startColNo: token.startColNo,
    endColNo: token.endColNo,
    startLineNo: token.startLineNo,
    endLineNo: token.endLineNo,
    content: token.content,
    tokenType: token.tokenType,
    nodeType: "leaf"
  };
}
function astInternalNodeFromToken(token: Token): ASTNode {
  return {
    startColNo: token.startColNo,
    endColNo: token.endColNo,
    startLineNo: token.startLineNo,
    endLineNo: token.endLineNo,
    content: [],
    tokenType: token.tokenType,
    nodeType: "internal"
  };
}

export function parse(tokens: Token[]): Maybe<ASTNode> {
  let ast = makeInternalASTNode(1, 1, 1, 1, [], "parenthesis");
  let astStack: ASTNode[] = [ast];
  for (const token of tokens) {
    switch (token.tokenType) {
      case "parenthesis":
        if (token.content == "(") {
          let astChild = astInternalNodeFromToken(token);
          astChild.content = [];
          astStack.push(astChild);
          ast = astChild;
        } else if (token.content == ")") {
          if (astStack.length == 1) {
            return getFailureMaybe(token, "syntax", "Too many closing parentheses, or not enough opening parentheses!");
          }
          ast = astStack.pop();
        }
      default:
        // if (!ast) {
        //   return getLispsmosFailure(token, "syntax", "Program must start with '('!")
        // }
        if (Array.isArray(ast.content)) {
          ast.content.push(astLeafNodeFromToken(token));
        }
    }
  }
  if (astStack.length > 1) {
    return getFailureMaybe(tokens[tokens.length - 1], "syntax", "Not enough closing parentheses, or too many opening parentheses!");
  }
  return success(astStack[0]);
}