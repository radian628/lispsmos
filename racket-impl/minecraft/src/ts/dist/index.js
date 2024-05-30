"use strict";
exports.__esModule = true;
var process_1 = require("process");
var image_edge_1 = require("./image-edge");
var bufferData = [];
process.stdin.on("data", function (buffer) {
    bufferData.push(buffer);
});
process.stdin.end(function () {
    var input = JSON.parse(Buffer.concat(bufferData).toString());
    var output = {};
    for (var _i = 0, _a = Object.entries(input); _i < _a.length; _i++) {
        var _b = _a[_i], k = _b[0], v = _b[1];
        if (v.type == "image-edges") {
            output[k] = (0, image_edge_1.findImageEdges)(v);
        }
    }
    process_1.stdout.write(JSON.stringify(output));
    process_1.stdout.end();
});
