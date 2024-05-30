var __asyncValues = (this && this.__asyncValues) || function (o) {
    if (!Symbol.asyncIterator) throw new TypeError("Symbol.asyncIterator is not defined.");
    var m = o[Symbol.asyncIterator], i;
    return m ? m.call(o) : (o = typeof __values === "function" ? __values(o) : o[Symbol.iterator](), i = {}, verb("next"), verb("throw"), verb("return"), i[Symbol.asyncIterator] = function () { return this; }, i);
    function verb(n) { i[n] = o[n] && function (v) { return new Promise(function (resolve, reject) { v = o[n](v), settle(resolve, reject, v.done, v.value); }); }; }
    function settle(resolve, reject, d, v) { Promise.resolve(v).then(function(v) { resolve({ value: v, done: d }); }, reject); }
};
import { stdout } from "process";
import { findImageEdges } from "./image-edge.mjs";
async function read(stream) {
    var e_1, _a;
    const chunks = [];
    try {
        for (var stream_1 = __asyncValues(stream), stream_1_1; stream_1_1 = await stream_1.next(), !stream_1_1.done;) {
            const chunk = stream_1_1.value;
            chunks.push(chunk);
        }
    }
    catch (e_1_1) { e_1 = { error: e_1_1 }; }
    finally {
        try {
            if (stream_1_1 && !stream_1_1.done && (_a = stream_1.return)) await _a.call(stream_1);
        }
        finally { if (e_1) throw e_1.error; }
    }
    return Buffer.concat(chunks).toString('utf-8');
}
const input = JSON.parse((await read(process.stdin)));
console.error(input);
const output = {};
for (const [k, v] of Object.entries(input)) {
    if (v.type == "image-edges") {
        output[k] = findImageEdges(v);
    }
}
stdout.write(JSON.stringify(output), () => {
    stdout.end();
    process.exit();
});
