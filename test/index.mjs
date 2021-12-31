import * as fs from "fs/promises";
import * as lispsmos from "lispsmos";

let compiler = new lispsmos.compiler.LispsmosCompiler();
lispsmos.utilityMacros.register(compiler);
lispsmos.proceduralMacros.register(compiler);
let whileLoopTest = await compiler.compile(await fs.readFile(process.argv[2]));
fs.writeFile(process.argv[3], JSON.stringify(whileLoopTest));