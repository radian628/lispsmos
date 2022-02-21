import * as lispsmos from "lispsmos";

lispsmos.buildServer(async () => {
  let compiler = new lispsmos.compiler.LispsmosCompiler();
  return await compiler.compile("(= y (^ x 2))")
})