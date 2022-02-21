import * as http from "node:http";

export * as compiler from "./compiler.js";
export * as compilerUtils from "./compiler-utils.js";
export * as utilityMacros from "./utility-macros.js";
export * as proceduralMacros from "./procedural-macros.js";
export * as graphicsMacros from "./graphics-macros.js";

export function buildServer(requestCallback: () => Promise<object>, port?: number, hostname?: string) {
    const server = http.createServer(async (req, res) => {
        let response: string;
        res.setHeader("Access-Control-Allow-Origin", "*");
        try {
            response = JSON.stringify(await requestCallback())
        } catch (err) {
            response = JSON.stringify({
                isError: true,
                message: err.message
            });
        }
        res.end(response);
    })
    if (port === undefined) port = 8090;
    if (hostname === undefined) hostname = "localhost";
    console.log(`LISPsmos build server running on '${hostname}' with port ${port}.`);
    server.listen(port, hostname);
}