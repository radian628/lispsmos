import { compiler, utilityMacros, compilerUtils } from "lispsmos";
//@ts-ignore
import * as OBJFile from "obj-file-parser";
import * as fs from "node:fs/promises";
import { stringify } from "node:querystring";
import * as execIf from "./exec-if.js";

import { ensureArray, ensureSymbol, removeQuotes, noScientific } from "../../common/common.js";

function binaryEncodeNumberList(numberList: number[], bitDepth: number, bitMult: number, signed?: boolean) {
  let numbersPerNumber = Math.floor(52 / bitDepth);
  let numberCounter = 0;
  let binEncodedNumbers: number[] = [];
  let currentNumber = 0;
  let bitMultFactor = Math.pow(2, bitMult);
  for (let num of numberList) {
    currentNumber += Math.floor((num * bitMultFactor + (signed ? Math.pow(2, bitDepth - 1) : 0))) * Math.pow(2, numberCounter * bitDepth);
    numberCounter++;
    if (numberCounter >= numbersPerNumber) {
      numberCounter = 0;
      binEncodedNumbers.push(currentNumber);
      currentNumber = 0;
    }
  }
  return binEncodedNumbers;
}

function getCompressedOBJDesmosData(objModel: any) {
  let xFaceNormals: any[] = [];
  let yFaceNormals: any[] = [];
  let zFaceNormals: any[] = [];
  objModel.faces.forEach((face: any) => {
    let xNormal = face.vertices.reduce((prev: any, vertex: any) => {
      return prev + objModel.vertexNormals[vertex.vertexNormalIndex - 1].x;
    }, 0);
    let yNormal = face.vertices.reduce((prev: any, vertex: any) => {
      return prev + objModel.vertexNormals[vertex.vertexNormalIndex - 1].y;
    }, 0);
    let zNormal = face.vertices.reduce((prev: any, vertex: any) => {
      return prev + objModel.vertexNormals[vertex.vertexNormalIndex - 1].z;
    }, 0);
    xFaceNormals.push(xNormal);
    yFaceNormals.push(yNormal);
    zFaceNormals.push(zNormal);
  });
  return [objModel.vertices.length, objModel.faces.length]
  .concat(binaryEncodeNumberList(objModel.vertices.map((v: any) => v.x) as number[], 26, 10, true))
  .concat(binaryEncodeNumberList(objModel.vertices.map((v: any) => v.y) as number[], 26, 10, true))
  .concat(binaryEncodeNumberList(objModel.vertices.map((v: any) => v.z) as number[], 26, 10, true)) 
  .concat(binaryEncodeNumberList(xFaceNormals as number[], 6, 6, true))
  .concat(binaryEncodeNumberList(yFaceNormals as number[], 6, 6, true))
  .concat(binaryEncodeNumberList(zFaceNormals as number[], 6, 6, true)) 
  .concat(binaryEncodeNumberList(objModel.faces.map((f: any) => f.vertices.map((v: any) => v.vertexIndex)).flat(2) as number[], 10, 0)); 
}

export default async function () {
  let lc = new compiler.LispsmosCompiler();
  utilityMacros.register(lc);
  execIf.default(lc);
  lc.registerImporter(async (lc, location) => {
    try {
      let sourceCode = await fs.readFile(location);
      return { payload: sourceCode.toString(), success: true };
    } catch (err) {
      return { payload: undefined, success: false };
    }
  });

  lc.registerEvent("init", lc => {
    lc.macroState.obj = new Map<string, Object>();
  });

  lc.registerResourceGatherer("importOBJ", async (ast, lc) => {
    let path = removeQuotes(ensureSymbol(ast[1], "OBJ path cannot be a list!"));
    let alias = removeQuotes(ensureSymbol(ast[2], "OBJ name cannot be a list!"));

    let objImport = await lc.import(path);
    if (objImport.success) {
      let objFile = new OBJFile.default(objImport.payload).parse();
      lc.macroState.obj.set(alias, objFile);
      console.log("MACROSTATE", lc.macroState);
    } else {
      throw new Error(`OBJ file '${path}' with alias '${alias}' not found.`);
    }
  });

  lc.registerMacro("importOBJ", (ast, lc) => []);

  lc.registerMacro("getOBJData", (ast, lc) => {
    let objName = removeQuotes(ensureSymbol(ast[1], "OBJ name cannot be a list!"));
    let objData = lc.macroState.obj.get(objName);
    let firstModel = objData.models[0];
    let obj = getCompressedOBJDesmosData(firstModel);
    return [["list", ...obj.map(e => noScientific(e))]];
  });

  let sourceCode = await fs.readFile("../lispsmos-src/main.lisp");
  let result = await lc.compile(sourceCode.toString());
  return result;
}