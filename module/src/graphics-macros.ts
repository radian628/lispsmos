//import { astToDesmosExpressions } from "./compiler";
import { LispsmosCompiler, MacroFunc } from "./compiler.js";
import { ASTNode } from "./compiler-utils.js"
import {extractStringFromLiteral } from "./compiler-utils.js";

type ElementDescriptor = { count: number, properties: string[][], data: { [propName: string]: (number | number[])[]} };
function parseASCIIPLY(ply: string) {
  //validation
  let plyLines = ply.split("\n").filter(str => !str.startsWith("comment"));
  if (plyLines[0] != "ply") throw new Error("Not a ply file - First line must be 'ply'.");
  if (plyLines[1] != "format ascii 1.0") throw new Error(`Unsupported PLY version/format: ${plyLines[1]}`)
  
  //parse header
  plyLines = plyLines.slice(2);
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
            let newList: number[] = [];
            elem.data[propName].push(newList);
            let arrlen = parseInt(line.pop());
            for (let j = 0; j < arrlen; j++) {
              newList.push(Number(line.pop()));
            }
            break;
          default:
            elem.data[propName].push(Number(line.pop()));
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
    throw new Error(`LISPsmos Error: Cannot import a  list!`);
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

async function makePLYAvailableToJS(ast: ASTNode, compiler: LispsmosCompiler) {
  await getPLYFile(ast, compiler);
  let parsedPLY = tryLoadPLY(ast, compiler);
  let plyTags = ast[2];
  let taggedParsedPLYs = compiler.macroState.graphics.taggedParsedPLYs;
  if (plyTags) {
    if (!Array.isArray(plyTags)) {
      throw new Error("LISPsmos Error: PLY tag list must be an array!");
    }
    plyTags.forEach(plyTag => {
      if (Array.isArray(plyTag)) {
        throw new Error("LISPsmos Error: Individual PLY tags must be strings!");
      }
      let plysWithSpecificTag = taggedParsedPLYs[plyTag];
      if (!plysWithSpecificTag) {
        plysWithSpecificTag = {};
        taggedParsedPLYs[plyTag] = plysWithSpecificTag;
      }
      plysWithSpecificTag[ast[1] as string] = {
        raw: parsedPLY,
      }
    });
  }
  compiler.macroState.graphics.parsedPLYs[extractStringFromLiteral(ast[1] as string)] = {
    raw: parsedPLY,
  };
  return;
}

export function register (c: LispsmosCompiler) {
  c.registerEvent("init", (compiler) => {
    compiler.macroState.graphics = {};
    compiler.macroState.graphics.assets = {};
    compiler.macroState.graphics.parsedPLYs = {};
    compiler.macroState.graphics.taggedParsedPLYs = {};
    compiler.macroState.graphics.bakedLights = [];
  });
  c.registerResourceGatherer("importPLY", getPLYFile);
  c.registerResourceGatherer("importPLYBounds", getPLYFile);
  c.registerResourceGatherer("importPLYStats", getPLYFile);
  c.registerResourceGatherer("importCompressedPLY", getPLYFile);
  c.registerResourceGatherer("makePLYAvailableToJS", makePLYAvailableToJS);
  c.registerMacro("makePLYAvailableToJS", (ast, compiler) => { return [] });
  c.registerMacro("importPLY", (ast: ASTNode, compiler: LispsmosCompiler): ASTNode[] => {
    //import PLY file
    let parsedPLY = tryLoadPLY(ast, compiler);

    //setup variables
    let importedPLYName = ast[2];
    if (Array.isArray(importedPLYName)) {
      throw new Error(`LISPsmos Error: PLY variable name cannot be a list!`);
    }
    let outAST: ASTNode[] = [];

    parsedPLY.get("face").data.vertex_indices = parsedPLY.get("face").data.vertex_indices.map(t => (t as number[]).map(v => (1 + v))); 
    parsedPLY.forEach((elem, elemName) => {
      Object.entries(elem.data).forEach((properties => {
        let propName = properties[0];
        let propValue = properties[1];
        outAST.push(["=", plyPropEscape(`${importedPLYName}ELEM${elemName}PROP${propName}`), ["list"].concat(propValue.flat().map(e => e.toString()))]);
      }));
    });
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
    let xVerts = parsedPLY.get("vertex").data.x as number[];
    let yVerts = parsedPLY.get("vertex").data.y as number[];
    let zVerts = parsedPLY.get("vertex").data.z as number[];
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
    let xVerts = parsedPLY.get("vertex").data.x as number[];
    let yVerts = parsedPLY.get("vertex").data.y as number[];
    let zVerts = parsedPLY.get("vertex").data.z as number[];
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
  function getXVerts(parsedPLY: Map<string, ElementDescriptor>) {
    return parsedPLY.get("vertex").data.x as number[];
  }
  function getYVerts(parsedPLY: Map<string, ElementDescriptor>) {
    return parsedPLY.get("vertex").data.y as number[];
  }
  function getZVerts(parsedPLY: Map<string, ElementDescriptor>) {
    return parsedPLY.get("vertex").data.z as number[];
  }
  function getIndices(parsedPLY: Map<string, ElementDescriptor>) {
    return parsedPLY.get("face").data.vertex_indices as number[][];
  }
  c.registerMacro("importCompressedPLY", (ast: ASTNode, compiler: LispsmosCompiler): ASTNode[] => {
    // try parse ply
    let sunPosition = compiler.macroState.utility.keyValueStore.get("sunPosition").slice(1).map((e: string) => parseFloat(e));
    let parsedPLY = tryLoadPLY(ast, compiler);

    let importedPLYName = ast[2];
    if (Array.isArray(importedPLYName)) {
      throw new Error(`LISPsmos Error: PLY variable name cannot be a list!`);
    }

    let outAST: ASTNode[] = ["list"];
    let perVertexData = parsedPLY.get("vertex");
    let perFaceData = parsedPLY.get("face");
    let xVerts: number[] = perVertexData.data.x as number[];
    let yVerts: number[] = perVertexData.data.y as number[];
    let zVerts: number[] = perVertexData.data.z as number[];
    let indices: number[][] = perFaceData.data.vertex_indices as number[][];
    let indexCount = indices.length;


    let vertexCount = xVerts.length;

    let rVertexColors = perVertexData.data.red;
    let gVertexColors = perVertexData.data.green;
    let bVertexColors = perVertexData.data.blue;

    let rFaceColors: number[] = [];
    let gFaceColors: number[] = [];
    let bFaceColors: number[] = [];

    indices.forEach((triangle: number[], i) => {
      rFaceColors.push(
        triangle.reduce((sum, vertIndex) => sum + (rVertexColors[(vertIndex)] as number), 0) / 3
      );
      gFaceColors.push(
        triangle.reduce((sum, vertIndex) => sum + (gVertexColors[(vertIndex)] as number), 0) / 3
      );
      bFaceColors.push(
        triangle.reduce((sum, vertIndex) => sum + (bVertexColors[(vertIndex)] as number), 0) / 3
      );
    });


    let newTriangles: number[][][][] = [];

    let isOccludedBySun: boolean[] = [];
    indices.forEach((triangle: number[]) => {
      let vert1: number[] = [xVerts[triangle[0]], yVerts[triangle[0]], zVerts[triangle[0]]] as number[];
      let vert2: number[] = [xVerts[triangle[1]], yVerts[triangle[1]], zVerts[triangle[1]]] as number[];
      let vert3: number[] = [xVerts[triangle[2]], yVerts[triangle[2]], zVerts[triangle[2]]] as number[];
      let lightDir = normalize(sunPosition);
      let newTriangleList = splitTriangle(vert1, vert2, vert3, (position: number[]): boolean => {
        //return mullerTrumbore(position, lightDir)
        let allIntersections: number[] = [];
        let terrains = compiler.macroState.graphics.taggedParsedPLYs.terrain;
        let terrainsEntries = Array.from(Object.entries(terrains));
        let terrainsToUse: {raw: Map<string, ElementDescriptor>}[] = [];
        let myTerrainIndex = parseInt((ast[1] as string).match(/\/[\w\W]+$/g)[0].match(/[0-9]+/)[0]);
        terrainsEntries.forEach(terrainEntry => {
          let terrainName = terrainEntry[0];
          let terrainValue = terrainEntry[1];
          let otherTerrainIndex = parseInt(terrainName.match(/\/[\w\W]+$/g)[0].match(/[0-9]+/)[0]);
          if (myTerrainIndex == otherTerrainIndex || myTerrainIndex+1 == otherTerrainIndex || myTerrainIndex-1 == otherTerrainIndex ) {
            //@ts-ignore
            terrainsToUse.push(terrainValue);
          }
        });
        /*Array.from(Object.values(terrains))*/terrainsToUse.forEach((otherTerrainPLYData: {raw: Map<string, ElementDescriptor>}) => {
          let otherTerrainPLY = otherTerrainPLYData.raw;
          let xVerts2 = getXVerts(otherTerrainPLY);
          let yVerts2 = getYVerts(otherTerrainPLY);
          let zVerts2 = getZVerts(otherTerrainPLY);
          let indices2 = getIndices(otherTerrainPLY);
          let intersections = indices2.map((triangle2: number[], triangleIndex2) => {
  
            // if (triangleIndex != triangleIndex2) {=
            let vert02: number[] = [xVerts2[triangle2[0]], yVerts2[triangle2[0]], zVerts2[triangle2[0]]] as number[];
            let vert12: number[] = [xVerts2[triangle2[1]], yVerts2[triangle2[1]], zVerts2[triangle2[1]]] as number[];
            let vert22: number[] = [xVerts2[triangle2[2]], yVerts2[triangle2[2]], zVerts2[triangle2[2]]] as number[];
              
            let raycastPosition = [
              position[0] + lightDir[0] * 0.0001,
              position[1] + lightDir[1] * 0.0001,
              position[2] + lightDir[2] * 0.0001,
            ]
  
            return mullerTrumbore(
              raycastPosition,
              lightDir,
              vert02,
              vert12,
              vert22
            );
          });
          allIntersections.push(...intersections);
        });
        return allIntersections.some(intersection => intersection > 0);
      });
      newTriangles.push(newTriangleList.triangles);
      isOccludedBySun.push(...newTriangleList.predicateResults);
    });

    //xVerts.splice(0, xVerts.length);
    //yVerts.splice(0, yVerts.length);
    //zVerts.splice(0, zVerts.length);
    let newXVerts: number[] = [];
    let newYVerts: number[] = [];
    let newZVerts: number[] = [];
    let newIndices: number[][] = [];
    let newRFaceColors: number[] = [];
    let newGFaceColors: number[] = [];
    let newBFaceColors: number[] = [];
    newTriangles.forEach((newTriangleList, triangleListIndex) => {
      newTriangleList.forEach(newTriangle => {
        let newTriangleIndices: number[] = [];
        newIndices.push(newTriangleIndices);
        newTriangle.forEach(newVertex => {
          let indexOfVert = newXVerts.indexOf(newVertex[0]);
          let indexOfVertY = newYVerts.indexOf(newVertex[1]);
          let indexOfVertZ = newZVerts.indexOf(newVertex[2]);
          if (indexOfVert == -1 || indexOfVertY == -1 || indexOfVertZ == -1 || (indexOfVert != indexOfVertY || indexOfVertY != indexOfVertZ)) {
            newXVerts.push(newVertex[0]);
            newYVerts.push(newVertex[1]);
            newZVerts.push(newVertex[2]);
            newTriangleIndices.push(newXVerts.length - 1);
          } else {
            newTriangleIndices.push(indexOfVert);
          }
        });
        newRFaceColors.push(rFaceColors[triangleListIndex]);
        newGFaceColors.push(gFaceColors[triangleListIndex]);
        newBFaceColors.push(bFaceColors[triangleListIndex]);
      });
    });

    xVerts = newXVerts;///.map(v => v.toString());
    yVerts = newYVerts;
    zVerts = newZVerts;
    indices = newIndices;
    rFaceColors = newRFaceColors;
    gFaceColors = newGFaceColors;
    bFaceColors = newBFaceColors;
    vertexCount = xVerts.length;
    indexCount = indices.length;

    let bakedLights = compiler.macroState.graphics.bakedLights;
    indices.forEach((triangle: number[], triangleIndex) => {
      let vert0: number[] = [xVerts[triangle[0]], yVerts[triangle[0]], zVerts[triangle[0]]] as number[];
      let vert1: number[] = [xVerts[triangle[1]], yVerts[triangle[1]], zVerts[triangle[1]]] as number[];
      let vert2: number[] = [xVerts[triangle[2]], yVerts[triangle[2]], zVerts[triangle[2]]] as number[];

      let edge1 = [vert1[0] - vert0[0], vert1[1] - vert0[1], vert1[2] - vert0[2]];
      let edge2 = [vert2[0] - vert0[0], vert2[1] - vert0[1], vert2[2] - vert0[2]];
      let normal = cross(edge1, edge2);
      normal = normal.map(e => e / Math.hypot(...normal));
      let lightDir = normalize(sunPosition);
      
      // let intersections0: number[] = [];
      // let intersections1: number[] = [];
      // let intersections2: number[] = [];
      // [vert0, vert1, vert2].forEach((vertex, vertexIndex) => {
      //   indices.forEach((triangle2, triangleIndex2) => {
      //     if (triangleIndex != triangleIndex2) {
      //       let triangleInts2 = (triangle2 as string[]).map(e => parseInt(e));
      //       let vert02 = [xVerts[triangleInts2[0]], yVerts[triangleInts2[0]], zVerts[triangleInts2[0]]].map(e => parseFloat(e as string));
      //       let vert12 = [xVerts[triangleInts2[1]], yVerts[triangleInts2[1]], zVerts[triangleInts2[1]]].map(e => parseFloat(e as string));
      //       let vert22 = [xVerts[triangleInts2[2]], yVerts[triangleInts2[2]], zVerts[triangleInts2[2]]].map(e => parseFloat(e as string));
            
      //       [intersections0, intersections1, intersections2][vertexIndex].push(mullerTrumbore(
      //         vertex,
      //         lightDir,
      //         vert02,
      //         vert12,
      //         vert22
      //       ));
      //     }
      //   });
      // })

      let brightnessFactor = Math.max(dot(normal, lightDir), 0);
      if (isOccludedBySun[triangleIndex]) brightnessFactor = 0;
      // [intersections0, intersections1, intersections2].forEach(intersections => {
      //   if (intersections.some(intersection => intersection > 0)) {
      //     brightnessFactor = Math.max(-0.75, brightnessFactor - 0.6);
      //   }
      // });
      let brightness = Math.ceil(brightnessFactor * 4) / 4 * 0.5 + 0.5;
      //if ) {
      rFaceColors[triangleIndex] *= brightness;
      gFaceColors[triangleIndex] *= brightness;
      bFaceColors[triangleIndex] *= brightness;

      type BakedLight = {
        x: number,
        y: number,
        z:number,
        r: number,
        g: number,
        b: number,
        strength: number
      };
      bakedLights.forEach((bakedLight: BakedLight) => {
        let rValue = 1;
        let gValue = 1;
        let bValue = 1;
        (triangle as number[]).forEach((triIndex) => {
          let lightOffset = ([
            bakedLight.x - xVerts[triIndex],
            bakedLight.y - yVerts[triIndex],
            bakedLight.z - zVerts[triIndex]
          ]);
          let lightDir2 = normalize(lightOffset);
          let normalBrightnessFactor = dot(normal, lightDir2);
          let distToLight = Math.hypot(...lightOffset);
          let mix = (a: number, b: number, fac: number) => a * fac + b * (1 - fac); 
          normalBrightnessFactor = mix(1, normalBrightnessFactor, Math.min(distToLight, 1));
          //if (distToLight < 5) normalBrightnessFactor = 1;
          let brightness = Math.min(0.007, 0.1 * bakedLight.strength * Math.max(0, Math.ceil(normalBrightnessFactor * 2) / 2) / (Math.ceil((distToLight ** 2) / 12) * 12));
          rValue += brightness * bakedLight.r / 3;
          gValue += brightness * bakedLight.g / 3;
          bValue += brightness * bakedLight.b / 3;
        });
        rFaceColors[triangleIndex] *= rValue;
        gFaceColors[triangleIndex] *= gValue;
        bFaceColors[triangleIndex] *= bValue;
      });

      rFaceColors[triangleIndex] = Math.max(Math.min(rFaceColors[triangleIndex], 255), 0);
      gFaceColors[triangleIndex] = Math.max(Math.min(gFaceColors[triangleIndex], 255), 0);
      bFaceColors[triangleIndex] = Math.max(Math.min(bFaceColors[triangleIndex], 255), 0);
      //}
    });

    outAST.push(vertexCount.toString());
    outAST.push(indexCount.toString());
    let numbersInCurrentNumber = 2;
    [xVerts, yVerts, zVerts].forEach(vertexArray => {
      let numsToAppend: number[] = [];
      numbersInCurrentNumber = 2;
      let verticesAsInts = vertexArray.map(vertexPos => Math.round(vertexPos * 1024) + (1 << 25));
      verticesAsInts.forEach(vertexAsInt => {
        if (numbersInCurrentNumber == 2) {
          numsToAppend.push(0);
          numbersInCurrentNumber = 0;
        }
        numsToAppend[numsToAppend.length - 1] += vertexAsInt * Math.pow(2, numbersInCurrentNumber * 26);
        numbersInCurrentNumber++;
      });
      outAST = outAST.concat(numsToAppend.map(num => num.toString()));
    });

    numbersInCurrentNumber = 5;
    let indicesToAppend: number[] = [];
    let indicesAsInts = indices.flat(2);
    indicesAsInts.forEach(indexAsInt => {
      if (numbersInCurrentNumber == 5) {
        indicesToAppend.push(0);
        numbersInCurrentNumber = 0;
      }
      indicesToAppend[indicesToAppend.length - 1] += indexAsInt * Math.pow(2, numbersInCurrentNumber * 10);
      numbersInCurrentNumber++;
    });
    outAST = outAST.concat(indicesToAppend.map(num => num.toString()));

    [rFaceColors, gFaceColors, bFaceColors].forEach(colorArray => {
      numbersInCurrentNumber = 8;
      let colorsToAppend: number[] = [];
      let colorsAsInts = colorArray.map(color => Math.floor(color/4));
      colorsAsInts.forEach(colorAsInt => {
        if (numbersInCurrentNumber == 8) {
          colorsToAppend.push(0);
          numbersInCurrentNumber = 0;
        }
          colorsToAppend[colorsToAppend.length - 1] += colorAsInt * Math.pow(2, numbersInCurrentNumber * 6);
        numbersInCurrentNumber++;
      });
      outAST = outAST.concat(colorsToAppend.map(color => color.toString()));
    });

    return [outAST];

  });

  c.registerResourceGatherer("importBakedLightSource", async (ast: ASTNode, compiler: LispsmosCompiler) => {
    await getPLYFile(ast, compiler);
    let bakedLights = compiler.macroState.graphics.bakedLights;
    let parsedPLY = tryLoadPLY(ast, compiler);

    let perVertexData = parsedPLY.get("vertex");

    let xVerts = perVertexData.data.x;
    let yVerts = perVertexData.data.y;
    let zVerts = perVertexData.data.z;

    let rVertexColors = perVertexData.data.red;
    let gVertexColors = perVertexData.data.green;
    let bVertexColors = perVertexData.data.blue;

    let xMean = mean(xVerts as number[]);
    let yMean = mean(yVerts as number[]);
    let zMean = mean(zVerts as number[]);
    let rMean = mean(rVertexColors as number[]);
    let gMean = mean(gVertexColors as number[]);
    let bMean = mean(bVertexColors as number[]);
    
    bakedLights.push({
      x: xMean,
      y: yMean,
      z: zMean,
      r: rMean,
      g: gMean,
      b: bMean,
      strength: Math.pow(2, Math.hypot(stdev(xVerts as number[]), stdev(yVerts as number[]), stdev(zVerts as number[])))
    });

    return;
  })
}


function cross(v1: number[], v2: number[]) {
  return [
    v1[1] * v2[2] - v1[2] * v2[1],
    v1[2] * v2[0] - v1[0] * v2[2],
    v1[0] * v2[1] - v1[1] * v2[0],
  ];
}

function dot (v1: number[], v2: number[]) {
  let sum = 0;
  for (let i = 0; i < v1.length; i++) {
    sum += v1[i] * v2[i];
  }
  return sum;
}
function mean(arr: Array<number>) {
  return arr.reduce((acc, cur) => acc + cur, 0) / arr.length; 
}
function meanStr(arr: Array<string>) {
  return mean(arr.map(e => parseFloat(e)));
}
function stdev(arr: Array<number>) {
  let datasetMean = mean(arr);
  return Math.sqrt(arr.reduce((acc, cur) => acc + Math.pow(cur - datasetMean, 2), 0) / (arr.length - 1))
}
function stdevStr(arr: Array<string>) {
  return stdev(arr.map(e => parseFloat(e)));
}
function normalize(arr: number[]) {
  let mag = Math.hypot(...arr);
  return arr.map(e => e / mag);
}
function mullerTrumbore(ray: number[], dir: number[], tri1: number[], tri2: number[], tri3: number[]) {
  let edge1 = [tri2[0] - tri1[0], tri2[1] - tri1[1], tri2[2] - tri1[2]];
  let edge2 = [tri3[0] - tri1[0], tri3[1] - tri1[1], tri3[2] - tri1[2]];
  let normal = cross(edge1, edge2);
  let det = -dot(dir, normal);
  let invdet = 1 / det;
  let AO = [ray[0] - tri1[0], ray[1] - tri1[1], ray[2] - tri1[2]];
  let DAO = cross(AO, dir);
  let u = dot(edge2, DAO) * invdet;
  let v = -1 * dot(edge1, DAO) * invdet;
  let t = dot(AO, normal) * invdet;
  if (det > 0.00001 && t > 0 && u > 0 && v > 0 && u + v < 1) return t;
}

type SplitTrianglePredicate = (position: number[]) => boolean;
function splitTriangle(tri1: number[], tri2: number[], tri3: number[], predicate: SplitTrianglePredicate) {
  let triNormal = calcNormal(tri1, tri2, tri3);
  let verts = [tri1, tri2, tri3];
  let avg = verts.reduce((acc, cur) => {
    return [acc[0]+cur[0]/3, acc[1]+cur[1]/3, acc[2]+cur[2]/3];
  },[0, 0, 0]);
  let adjustedVerts = verts.map(vert => {
      return [
        avg[0] + (vert[0] - avg[0]) * 0.995,
        avg[1] + (vert[1] - avg[1]) * 0.995,
        avg[2] + (vert[2] - avg[2]) * 0.995
      ]
    }
  )
  let predicateResults = adjustedVerts.map(av => predicate(av));
  if (predicateResults.every(e => e) || !predicateResults.some(e => e)) {
    return {
      triangles: [[tri1, tri2, tri3]],
      predicateResults: [predicateResults[0]]
    };
  }
  let edgeIndices = [ //
    [0, 1, 2],
    [2, 1, 0],
    [2, 0, 1]
  ];
  let unusedEdgePair: number[];
  let intersections = edgeIndices.map((edgeIndexPair, edgeIndexPairIndex) => {
    if (predicateResults[edgeIndexPair[0]] != predicateResults[edgeIndexPair[1]]) {
      let v1 = verts[edgeIndexPair[0]];
      let v2 = verts[edgeIndexPair[1]];
      let av1 = adjustedVerts[edgeIndexPair[0]];
      let av2 = adjustedVerts[edgeIndexPair[1]];
      if (predicateResults[edgeIndexPair[0]]) {
        v2 = verts[edgeIndexPair[0]];
        v1 = verts[edgeIndexPair[1]];
        av2 = adjustedVerts[edgeIndexPair[0]];
        av1 = adjustedVerts[edgeIndexPair[1]];
      }
      let binSearchFactor = 0.5;
      let binSearchDelta = 0.25;
      let getBinSearchPos = () => {
        return [
          v1[0] + (v2[0] - v1[0]) * binSearchFactor,
          v1[1] + (v2[1] - v1[1]) * binSearchFactor,
          v1[2] + (v2[2] - v1[2]) * binSearchFactor,
        ];
      }
      let getAdjustedBinSearchPos = () => {
        return [
          av1[0] + (av2[0] - av1[0]) * binSearchFactor,
          av1[1] + (av2[1] - av1[1]) * binSearchFactor,
          av1[2] + (av2[2] - av1[2]) * binSearchFactor,
        ];
      }
      for (let i = 0; i < 12; i++) {
        if (predicate(getAdjustedBinSearchPos())) {
          binSearchFactor -= binSearchDelta;
        } else {
          binSearchFactor += binSearchDelta;
        }
        binSearchDelta /= 2;
      }
      return getBinSearchPos();
    } else {
      unusedEdgePair = edgeIndexPair;
    }
  }).filter(e => e);
  let outTriangles = [
    [verts[unusedEdgePair[2]], intersections[0], intersections[1]],
    [intersections[1], verts[unusedEdgePair[0]], verts[unusedEdgePair[1]]],
    [intersections[0], verts[unusedEdgePair[1]], intersections[1]]
  ];
  outTriangles = outTriangles.map((tri: number[][]) => {
    let subTriNormal = calcNormal(tri[0], tri[1], tri[2]);
    let epsilon = 0.00001;
    if (Math.abs(triNormal[0] - subTriNormal[0]) > epsilon || 
    Math.abs(triNormal[1] - subTriNormal[1]) > epsilon || 
    Math.abs(triNormal[2] - subTriNormal[2]) > epsilon) {

      return [tri[0], tri[2], tri[1]];
    }

    return tri;
  })
  return {
    triangles: outTriangles,
    predicateResults: [
      predicateResults[unusedEdgePair[2]],
      !predicateResults[unusedEdgePair[2]],
      !predicateResults[unusedEdgePair[2]]
    ]
  };
}

function calcNormal(vert0: number[], vert1: number[], vert2: number[]) {
  let edge1 = [vert1[0] - vert0[0], vert1[1] - vert0[1], vert1[2] - vert0[2]];
  let edge2 = [vert2[0] - vert0[0], vert2[1] - vert0[1], vert2[2] - vert0[2]];
  let normal = cross(edge1, edge2);
  normal = normal.map(e => e / Math.hypot(...normal));
  return normal;
}