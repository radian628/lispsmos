import * as fs from "fs/promises";
import * as http from "http";
import * as path from "path";
//@ts-ignore
import * as mime from "mime-types";
import * as build from "./index.js";

let server = http.createServer(async (req, res) => {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Cross-Origin-Resource-Policy", "cross-origin");
    res.setHeader("Content-Type", mime.lookup(req.url));
    let url = req.url;
    if (url.match(/build$/g)) {
      res.end(JSON.stringify(await build.default()));
      return;
    }
    let fileLocation = path.join("../", url);
    fs.readFile(fileLocation)
    .then(file => {
        res.end(file);
    })
    .catch(err => {
        res.statusCode = 404;
        res.end("Not found.");
    });
    
});

//@ts-ignore
server.listen("8081", "localhost"); 