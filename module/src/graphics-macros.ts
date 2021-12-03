//import { astToDesmosExpressions } from "./compiler";
import { LispsmosCompiler, MacroFunc } from "./compiler.js";
import { ASTNode } from "./compiler-utils.js"
import {extractStringFromLiteral } from "./compiler-utils.js";

function parseASCIIPLY(ply: string) {
  //validation
  let plyLines = ply.split("\n").filter(str => !str.startsWith("comment"));
  if (plyLines[0] != "ply") throw new Error("Not a ply file - First line must be 'ply'.");
  if (plyLines[1] != "format ascii 1.0") throw new Error(`Unsupported PLY version/format: ${plyLines[1]}`)
  
  //parse header
  plyLines = plyLines.slice(2);
  type ElementDescriptor = { count: number, properties: string[][], data: { [propName: string]: (string | string[])[]} };
  let elements: Map<string, ElementDescriptor> = new Map();
  let currentElement = undefined;
  let lineIndex = 0;
  for (let line of plyLines) {
    let lineElems = line.split(" ");
    let endLoop = false;
    switch (lineElems[0]) {
      case "element":
        currentElement = lineElems[1];
        elements.set(lineElems[1], { count: parseInt(lineElems[2]), properties: [], data: {} });
        break;
      case "property":
        if (currentElement) {
          elements.get(currentElement).properties.push(lineElems.slice(1));
          elements.get(currentElement).data[lineElems[lineElems.length - 1]] = [];
        } else {
          throw new Error(`Ply property '${lineElems[lineElems.length - 1]}' must apply to some element.`);
        }
        break;
      case "end_header":
        endLoop = true;
        break;
    }
    lineIndex++;
    if (endLoop) {
      break;
    }
  }

  //parse body
  plyLines = plyLines.slice(lineIndex); 
  let currentLine = 0;
  elements.forEach((elem) => {
    for (let i = 0; i < elem.count; i++) {
      let line = plyLines[currentLine].split(" ").reverse();
      currentLine += 1;

      elem.properties.forEach((prop) => {
        let propName = prop[prop.length - 1];
        switch (prop[0]) {
          case "list":
            let newList: string[] = [];
            elem.data[propName].push(newList);
            let arrlen = parseInt(line.pop());
            for (let j = 0; j < arrlen; j++) {
              newList.push(line.pop());
            }
            break;
          default:
            elem.data[propName].push(line.pop());
        }
      });
    }
  });
  return elements;
}

function plyPropEscape(str: string) {
  return str.replace(/\_/g, "underscore");
}

async function getPLYFile(ast: ASTNode, compiler: LispsmosCompiler) {
  let importString = ast[1];
  if (Array.isArray(importString)) {
    throw new Error(`LISPsmos Error: Cannot import a list!`);
  }
  importString = extractStringFromLiteral(importString);
  let plyFile = await compiler.import(importString);
  compiler.macroState.graphics.assets[importString] = plyFile;
  return;
}

function tryLoadPLY(ast: ASTNode, compiler: LispsmosCompiler) {
  let importString = ast[1];
  if (Array.isArray(importString)) {
    throw new Error(`LISPsmos Error: Cannot import a list!`);
  }
  importString = extractStringFromLiteral(importString);
  let importAttempt = compiler.macroState.graphics.assets[importString];
  if (!importAttempt.success) {
    throw new Error(`LISPsmos Error: PLY import failed! Failed to import '${importString}'.`);
  }
  let ply = importAttempt.payload;
  if (typeof ply != "string") {
    throw new Error(`LISPsmos Error: Imported PLY file must be a string! Received type ${typeof ply}.`);
  }

  let parsedPLY;
  try {
    parsedPLY = parseASCIIPLY(ply);
  } catch (err) {
    throw new Error(`LISPsmos Error: PLY parsing failed: '${err.message}'`);
  }
  return parsedPLY;
}

export function register (c: LispsmosCompiler) {
  c.registerEvent("init", (compiler) => {
    compiler.macroState.graphics = {};
    compiler.macroState.graphics.assets = {};
  });
  c.registerResourceGatherer("importPLY", getPLYFile);
  c.registerResourceGatherer("importPLYBounds", getPLYFile);
  c.registerResourceGatherer("importPLYStats", getPLYFile);
  c.registerMacro("importPLY", (ast: ASTNode, compiler: LispsmosCompiler): ASTNode[] => {
    //import PLY file
    let parsedPLY = tryLoadPLY(ast, compiler);

    //setup variables
    let importedPLYName = ast[2];
    if (Array.isArray(importedPLYName)) {
      throw new Error(`LISPsmos Error: PLY variable name cannot be a list!`);
    }
    let outAST: ASTNode[] = [];

    console.log("PARSED PLY FILE:", parsedPLY);
    parsedPLY.forEach((elem, elemName) => {
      Object.entries(elem.data).forEach((properties => {
        let propName = properties[0];
        let propValue = properties[1];
        outAST.push(["=", plyPropEscape(`${importedPLYName}ELEM${elemName}PROP${propName}`), ["list"].concat(propValue.flat())]);
      }));
    });
    console.log(outAST);
    return [outAST];
  });
  c.registerMacro("importPLYBounds", (ast: ASTNode, compiler: LispsmosCompiler): ASTNode[] => {
    //import PLY file
    let parsedPLY = tryLoadPLY(ast, compiler);

    //setup variables
    let importedPLYName = ast[2];
    if (Array.isArray(importedPLYName)) {
      throw new Error(`LISPsmos Error: PLY variable name cannot be a list!`);
    }
    let outAST: ASTNode[] = ["list"];
    let xVerts = (parsedPLY.get("vertex").data.x as string[]).map(str => parseFloat(str));
    let yVerts = (parsedPLY.get("vertex").data.y as string[]).map(str => parseFloat(str));
    let zVerts = (parsedPLY.get("vertex").data.z as string[]).map(str => parseFloat(str));
    outAST.push(Math.min(...xVerts).toString());
    outAST.push(Math.min(...yVerts).toString());
    outAST.push(Math.min(...zVerts).toString());
    outAST.push(Math.max(...xVerts).toString());
    outAST.push(Math.max(...yVerts).toString());
    outAST.push(Math.max(...zVerts).toString());
    return [outAST];
  });
  c.registerMacro("importPLYStats", (ast: ASTNode, compiler: LispsmosCompiler): ASTNode[] => {
    //import PLY file
    let parsedPLY = tryLoadPLY(ast, compiler);

    //setup variables
    let importedPLYName = ast[2];
    if (Array.isArray(importedPLYName)) {
      throw new Error(`LISPsmos Error: PLY variable name cannot be a list!`);
    }
    let outAST: ASTNode[] = ["list"];
    let xVerts = (parsedPLY.get("vertex").data.x as string[]).map(str => parseFloat(str));
    let yVerts = (parsedPLY.get("vertex").data.y as string[]).map(str => parseFloat(str));
    let zVerts = (parsedPLY.get("vertex").data.z as string[]).map(str => parseFloat(str));
    outAST.push(mean(xVerts).toString());
    outAST.push(mean(yVerts).toString());
    outAST.push(mean(zVerts).toString());
    let xStdev = stdev(xVerts);
    let yStdev = stdev(yVerts);
    let zStdev = stdev(zVerts);
    outAST.push(xStdev.toString());
    outAST.push(yStdev.toString());
    outAST.push(zStdev.toString());
    outAST.push(Math.hypot(xStdev, yStdev, zStdev).toString());
    return [outAST];
  });
}

function mean(arr: Array<number>) {
  return arr.reduce((acc, cur) => acc + cur, 0) / arr.length; 
}
function stdev(arr: Array<number>) {
  let datasetMean = mean(arr);
  return Math.sqrt(arr.reduce((acc, cur) => acc + Math.pow(cur - datasetMean, 2), 0) / (arr.length - 1))
}