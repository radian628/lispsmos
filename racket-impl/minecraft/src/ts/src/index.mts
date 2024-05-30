import { stdout } from "process";
import { findImageEdges, ImageEdgesInput, ImageEdgesOutput } from "./image-edge.mjs";
import * as fs from "node:fs/promises"
import { Readable } from "stream";

type IPCMessageInput = ImageEdgesInput;

type IPCMessageInputSet = {
    [key: string]: IPCMessageInput
}

type IPCMessageOutput = ImageEdgesOutput;

type IPCMessageOutputSet = {
    [key: string]: IPCMessageOutput
};

async function read(stream: Readable) {
    const chunks = [];
    for await (const chunk of stream) chunks.push(chunk);
    return Buffer.concat(chunks).toString('utf-8');
}

const input: IPCMessageInputSet = JSON.parse((await read(process.stdin)));

console.error(input);

const output: IPCMessageOutputSet = {};
for (const [k, v] of Object.entries(input)) {
    if (v.type == "image-edges") {
        output[k] = findImageEdges(v);
    }
}

stdout.write(JSON.stringify(output), () => {
    stdout.end();
    process.exit();
});
    