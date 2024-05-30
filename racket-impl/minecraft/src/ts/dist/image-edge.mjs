function getMaxIndex(arr, callback) {
    let val = -Infinity;
    let index = -1;
    arr.forEach((e, i) => {
        const currentVal = callback(e);
        if (val > currentVal) {
            val = currentVal;
            index = i;
        }
    });
    return index;
}
function joinStraightLines(polyline) {
    var _a, _b;
    let newPolyline = [];
    let prevAngle = -9999999;
    for (const segment of polyline) {
        let angle = Math.atan2(((_a = newPolyline[newPolyline.length - 1]) !== null && _a !== void 0 ? _a : [-1, -1])[1] - segment[1], ((_b = newPolyline[newPolyline.length - 1]) !== null && _b !== void 0 ? _b : [-1, -1])[0] - segment[0]);
        if (Math.abs(angle - prevAngle) < 0.00001) {
            newPolyline[newPolyline.length - 1] = segment;
        }
        else {
            newPolyline.push(segment);
        }
    }
    return newPolyline;
}
export function findImageEdges(input) {
    const uniqueColors = new Set();
    input.colors.forEach(col => uniqueColors.add(col));
    const vertexPositionLists = [];
    uniqueColors.forEach(uniqueCol => {
        const edgeHash = [];
        const edgeList = [];
        const edgesChecked = [];
        for (let y = 0; y < input.h + 1; y++) {
            for (let x = 0; x < input.w + 1; x++) {
                edgeHash.push([]);
            }
        }
        input.colors.forEach((col, i) => {
            if (col != uniqueCol)
                return;
            const above = (i - input.w >= 0) ? input.colors[i - input.w] : -1;
            const below = (i + input.w < input.w * input.h) ? input.colors[i + input.w] : -1;
            const left = ((i % input.w) != 0) ? input.colors[i - 1] : -1;
            const right = ((i % input.w) != (input.w - 1)) ? input.colors[i + 1] : -1;
            const i2 = i + Math.floor(i / input.w);
            const topLeftIndex = i2;
            const topRightIndex = i2 + 1;
            const bottomLeftIndex = i2 + input.w + 1;
            const bottomRightIndex = i2 + input.w + 2;
            function testSquareBoundary(compare, endpoint1, endpoint2) {
                if (col != compare) {
                    edgeHash[endpoint1].push(edgeList.length);
                    edgeHash[endpoint2].push(edgeList.length);
                    edgeList.push([endpoint1, endpoint2]);
                    edgesChecked.push(false);
                }
            }
            testSquareBoundary(above, topLeftIndex, topRightIndex);
            testSquareBoundary(below, bottomLeftIndex, bottomRightIndex);
            testSquareBoundary(left, topLeftIndex, bottomLeftIndex);
            testSquareBoundary(right, topRightIndex, bottomRightIndex);
        });
        const vposList = [];
        let currentEdgeIndex = 0;
        let currentEndpointIndex = -1;
        while (currentEdgeIndex != -1) {
            edgesChecked[currentEdgeIndex] = true;
            const endpoints = edgeList[currentEdgeIndex];
            currentEndpointIndex = (currentEndpointIndex == endpoints[0]) ? endpoints[1] : endpoints[0];
            vposList.push([
                (currentEndpointIndex % (input.w + 1)) / input.w,
                1 - (Math.floor(currentEndpointIndex / (input.w + 1))) / input.h
            ]);
            let maybeCurrentEdgeIndex = edgeHash[currentEndpointIndex].find(elem => !edgesChecked[elem]);
            if (maybeCurrentEdgeIndex != undefined) {
                currentEdgeIndex = maybeCurrentEdgeIndex;
            }
            else {
                currentEdgeIndex = edgesChecked.indexOf(false);
                vposList.push([-1, -1]);
            }
        }
        vertexPositionLists.push(vposList);
    });
    const maxIndex = getMaxIndex(vertexPositionLists, vposList => vposList.length);
    vertexPositionLists[maxIndex] = [[0, 0], [0, 1], [1, 1], [1, 0]];
    return {
        type: "image-edges",
        uniqueColors: Array.from(uniqueColors),
        vertexPositions: vertexPositionLists.map(list => joinStraightLines(list))
    };
}
