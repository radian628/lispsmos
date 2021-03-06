import { builtins } from "./builtins.js";

export let tokenTypes: [string, RegExp][] = [
  ["string_literal", /\"[\w\W]*?\"/y],
  ["whitespace", /\;[\w\W]*?$/ym],
  ["parenthesis", /[\(\)]/y],
  ["number", /\-*[0-9]*\.[0-9]+/y],
  ["number", /\-*[0-9]+/y],
  ["range", /\.\.\./y],
  ["operator", /(\-\>|\+|\-|\*|\/|\^|\>\=|\<\=|\>|\<|\=\=|\=|\,)/y],
  ["keyword", /(piecewise|point|list|\.x|\.y|\[\]|fn|sum|prod|sqrt|compose|comprehension)(?![0-9]|[a-z]|[A-Z])/y],
  ["other", /(dt|index)(?![0-9]|[a-z]|[A-Z])/y],
  ["macro", /a^/y],
  ["builtin", new RegExp(`(${builtins.map(builtin => `${builtin}(?!\\w)`).join("|")})`,"y")],
  ["variable", /([a-z]|[A-Z]|\_)([0-9]|[a-z]|[A-Z]|\_)*/y],
  ["whitespace", /\s+/y]
]

export function extractStringFromLiteral(str: string) {
  if (getTokenType(str) == "string_literal") {
    return str.slice(1, str.length - 1);
  }
}

export function token(str: string) {
  return str;
}

export function getTokenType(str: string) {
  for (const [tokenName, tokenRegexp] of tokenTypes) {
    tokenRegexp.lastIndex = 0;
    //@ts-ignore
    let matches = tokenRegexp[Symbol.match](str);
    if (matches !== null) {
      return tokenName;
      break;
    }
  }
  throw new Error("No token match found for " + str);
}

export type ASTNode = Array<ASTNode> | string;

export type ParametricDomain = {
  min: string,
  max: string
}

export type DesmosExpression = {
  hidden?: boolean,
  folderId?: string,
  type: "expression" | "folder" | "image",
  id: string,
  color?: string,
  latex?: string,
  title?: string,
  collapsed?: boolean,

  //display properties
  colorLatex?: string,
  lineOpacity?: string,
  lineWidth?: string,
  pointOpacity?: string,
  fillOpacity?: string,
  pointSize?: string,
  lineStyle?: string,
  pointStyle?: string,
  parametricDomain?: ParametricDomain,
  clickableInfo?: {
    enabled: boolean,
    latex: string
  },
  fill?: boolean,
  lines?: boolean

  //image properties
  center?: string,
  draggable?: boolean,
  foreground?: boolean,
  width?: string,
  height?: string,
  image_url?: string,
  name?: string

  //label
  showLabel?: boolean,
  label?: string,
  labelOrientation?: string,
  labelSize?: string
  suppressTextOutline?: boolean
};

export type DesmosState = {
  version: number,
  randomSeed: string,
  graph: {
    viewport: {
      xmin: number,
      ymin: number,
      xmax: number,
      ymax: number
    }
  },
  expressions: {
    list: DesmosExpression[]
    ticker?: {
      handlerLatex: string,
      open: boolean
    }
  }
};
