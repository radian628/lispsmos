import * as fs from "fs/promises";
import * as http from "http";
import * as path from "path";

let server = http.createServer(async (req, res) => {
    res.setHeader("Access-Control-Allow-Origin", "*");
    let url = req.url;
    let fileLocation = path.join(process.cwd(), url);
    fs.readFile(fileLocation)
    .then(file => {
        res.end(file);
    })
    .catch(err => {
        res.statusCode = 404;
        res.end("Not found.");
    });
    
});

server.listen("8080", "localhost")