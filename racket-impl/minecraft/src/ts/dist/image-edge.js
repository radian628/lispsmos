"use strict";
exports.__esModule = true;
exports.findImageEdges = void 0;
function findImageEdges(input) {
    var uniqueColors = new Set();
    input.colors.forEach(function (col) { return uniqueColors.add(col); });
    var vertexPositionLists = [];
    uniqueColors.forEach(function (uniqueCol) {
        var edgeHash = [];
        var edgeList = [];
        var edgesChecked = [];
        for (var y = 0; y < input.h + 1; y++) {
            for (var x = 0; x < input.w + 1; x++) {
                edgeHash.push([]);
            }
        }
        input.colors.forEach(function (col, i) {
            if (col != uniqueCol)
                return;
            var above = (i - input.w >= 0) ? input.colors[i - input.w] : -1;
            var below = (i + input.w < input.w * input.h) ? input.colors[i + input.w] : -1;
            var left = ((i % input.w) != 0) ? input.colors[i - 1] : -1;
            var right = ((i % input.w) != (input.w - 1)) ? input.colors[i + 1] : -1;
            var topLeftIndex = i;
            var topRightIndex = i + 1;
            var bottomLeftIndex = i + input.w;
            var bottomRightIndex = i + input.w + 1;
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
        var vposList = [];
        var currentEdgeIndex = 0;
        var currentEndpointIndex = -1;
        while (currentEdgeIndex != -1) {
            edgesChecked[currentEdgeIndex] = true;
            var endpoints = edgeList[currentEdgeIndex];
            currentEndpointIndex = (currentEndpointIndex == endpoints[0]) ? endpoints[1] : endpoints[0];
            vposList.push([
                (currentEndpointIndex % (input.w + 1)) / input.w,
                (Math.floor(currentEndpointIndex / (input.w + 1))) / input.w
            ]);
            var maybeCurrentEdgeIndex = edgeHash[currentEndpointIndex].find(function (elem) { return !edgesChecked[elem]; });
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
    return {
        type: "image-edges",
        uniqueColors: Array.from(uniqueColors),
        vertexPositions: vertexPositionLists
    };
}
exports.findImageEdges = findImageEdges;
