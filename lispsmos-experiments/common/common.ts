import { compilerUtils } from "lispsmos";

export function ensureArray(value: compilerUtils.ASTNode, msg: string): Array<compilerUtils.ASTNode> {
  if (!Array.isArray(value)) {
    throw msg;
  }
  return value;
}
export function ensureSymbol(value: compilerUtils.ASTNode, msg: string): string {
  if (Array.isArray(value)) {
    throw msg;
  }
  return value;
}

export function removeQuotes(str: string) {
  if (str.charAt(0) == "\"" && str.charAt(str.length - 1) == "\"") return str.slice(1, -1);
  return str;
}
export function noScientific(x: number) {
  return x.toLocaleString("fullwide", { useGrouping: false });
}

export function findAndReplaceAST(original: compilerUtils.ASTNode, find: string, replace: compilerUtils.ASTNode): compilerUtils.ASTNode {
  if (Array.isArray(original)) {
    return original.map(child => findAndReplaceAST(child, find, replace));
  } else {
    return (original == find) ? replace : original;
  }
}