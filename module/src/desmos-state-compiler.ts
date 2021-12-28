import { ASTNode, Compiler } from "./common";

export function compileLatexExpression(ast: ASTNode, compiler: Compiler) {
  if (ast.nodeType == "leaf") {
    switch (ast.tokenType) {
      case "comment":
        if (compiler.options.commentsAsNotes && ast.nodeType == "leaf") {
          compiler.calcState.expressions.list.push({
            type: "text",
            text: ast.content,
            id: compiler.getNewExpressionIndex()
          });
        }
        break;
      case "identifier":
        break;
      case "parenthesis":
        break;
      case "string_literal":
        break;
      case "whitespace":
        break;
    }
  }
}