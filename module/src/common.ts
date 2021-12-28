import { State } from "./state.js"

export interface TokenType {
  pattern: RegExp,
  name: TokenTypeName
}
export type TokenTypeName = "string_literal" | "comment" | "parenthesis" | "whitespace" | "identifier";
export const tokenTypes: TokenType[] = [
  { pattern: /\"[\w\W]*?\"/y, name: "string_literal" },
  { pattern: /\;[\w\W]*?$/ym, name: "comment" },
  { pattern: /\(\)/y, name: "parenthesis" },
  { pattern: /\s+/y, name: "whitespace" },
  { pattern: /[^\s]+/y, name: "identifier" }
];

export interface CodeLocation {
  startLineNo: number,
  endLineNo: number,
  startColNo: number,
  endColNo: number
}

export interface Token extends CodeLocation {
  content: string,
  tokenType: TokenTypeName
};

export interface ASTInternalNode extends CodeLocation {
  content: Array<ASTNode>
  tokenType: TokenTypeName
  nodeType: "internal"
}

export interface ASTLeafNode extends CodeLocation {
  content: string
  tokenType: TokenTypeName
  nodeType: "leaf"
}

export type ASTNode = ASTInternalNode | ASTLeafNode;

export type ErrorCategory = "syntax" | "macro" | "semantics";

export interface LISPsmosFailure extends CodeLocation {
  reason: string,
  category: ErrorCategory,
  isFailure: any
}

export interface Maybe<T> {
  data: T | LISPsmosFailure,
  success: boolean
}

export function success<T>(data: T): Maybe<T> {
  return { data, success: true };
}
export function failure<T>(data: LISPsmosFailure): Maybe<T>{
  return { data, success: false };
}

export function makeInternalASTNode(startLineNo: number, endLineNo: number, startColNo: number, endColNo: number, content: ASTNode[], tokenType: TokenTypeName): ASTNode {
  return {
    startLineNo, endLineNo, startColNo, endColNo, content, tokenType, nodeType: "internal"
  }
}

export function getLispsmosFailure(location: CodeLocation, category: ErrorCategory, reason: string): LISPsmosFailure {
  return Object.assign({
    category, reason, isFailure: true
  }, location);
}
export function getFailureMaybe<T>(location: CodeLocation, category: ErrorCategory, reason: string): Maybe<T> {
  return failure(getLispsmosFailure(location, category, reason));
}

export type ASTMap = Map<string, ASTNode>;
export type MacroFunction = (ast: ASTInternalNode, compiler: Compiler) => Promise<Maybe<ASTNode[]>>;

export interface CompilerOptions {
  allowInlineJS: boolean,
  commentsAsNotes: boolean,
  import: ResourceImporter
};

export type ResourceImporter = (query: string) => Promise<string | ArrayBuffer | undefined>;
export interface Compiler {
  getMacroState(macroName: string): any,
  variables: ASTMap,
  functions: ASTMap,
  macros: Map<string, MacroFunction>,
  calcState: State,
  import: ResourceImporter,
  options: CompilerOptions,
  getNewExpressionIndex(): string
}