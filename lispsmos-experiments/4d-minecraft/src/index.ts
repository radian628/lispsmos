import { compiler, utilityMacros, compilerUtils } from "lispsmos";
//@ts-ignore
import * as OBJFile from "obj-file-parser";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

export default async function () {
  let lc = new compiler.LispsmosCompiler();
  utilityMacros.register(lc);
  lc.registerImporter(async (lc, location) => {
    try {
      let sourceCode = await fs.readFile(location);
      return { payload: sourceCode.toString(), success: true };
    } catch (err) {
      return { payload: undefined, success: false };
    }
  });
  let sourceCode = await fs.readFile(path.join(path.dirname(fileURLToPath(import.meta.url)), "../lispsmos/main.lisp"));
  let result = await lc.compile(sourceCode.toString());
  return result;
}