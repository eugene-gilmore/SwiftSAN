import SwiftSAN
import Foundation

var facebookDir = URL(fileURLWithPath: #filePath)
facebookDir.deleteLastPathComponent()
facebookDir = facebookDir.appendingPathComponent("../../Resources/facebook")

let g = try loadEgoNetwork(dir: facebookDir)
var attributeNodes = g.vertices.filter { $0.isAttributeNode }
.compactMap { (n: SANNode) -> (index : Int, node : AttributeNode, numLinks: Int)? in
    guard let index = g.indexOfVertex(n), let node = n.asAttributeNode else {
        return nil
    }
    return (index: index, node: node, numLinks: g.numberNeighborsForIndex(index))
}
let socialNodes = try g.vertices.filter { $0.isSocialNode }
.compactMap { (node: SANNode) -> (index: Int, aaVals: [Double])? in
    guard let index = g.indexOfVertex(node) else {
        return nil
    }
    return (
        index: index, 
        aaVals: try attributeNodes.map { try g.AdamicAdar(u: index, v: $0.index) })
}

var output = attributeNodes.map { "\($0.node.attributeName):\($0.node.value)" }
.reduce("", {"\($0)\($1),"})
output = output + output.dropLast() 
for s in socialNodes {
    let line = s.aaVals.reduce("", {"\($0)\($1),"}) 
    + attributeNodes.map { g.edgeExists(fromIndex: s.index, toIndex: $0.index) ? "1" : "0" }
    .reduce("", {"\($0)\($1),"}).dropLast()
    output += line + "\n"
}

try output.write(
    to: facebookDir.appendingPathComponent("classification.csv"),
    atomically: true,
    encoding: .utf8)

var counts : [Int: [(node: AttributeNode, index: Int, graphIndex: Int)]] = [:]
for i in 0..<attributeNodes.count {
    let a = attributeNodes[i]
    counts[a.numLinks] = (counts[a.numLinks] ?? [])+[(node: a.node, index: i, graphIndex: a.index)]
}

let numDatasets = 20
var step = Double(counts.count-1)/Double(numDatasets-1)
let sortedDist = counts.sorted(by: {$0.key < $1.key})
for i in 0..<numDatasets {
    let dist = sortedDist[Int((Double(i)*step).rounded())]
    guard let classNode = dist.value.randomElement() else {
        throw "Internal Error"
    }
    var attributes = attributeNodes
    attributes.remove(at: classNode.index)
    output = attributes.map { "\($0.node.attributeName):\($0.node.value)" }
    .reduce("", {"\($0)\($1),"}) + "\(classNode.node.attributeName):\(classNode.node.value)\n"
    for s in socialNodes {
        var vals = s.aaVals
        vals.remove(at: classNode.index)
        output += vals.reduce("", {"\($0)\($1),"}) 
        + "\(g.edgeExists(fromIndex: s.index, toIndex: classNode.graphIndex) ? "1" : "0")\n"
    }
    try output.write(
        to: facebookDir.appendingPathComponent("classification-\(classNode.node.value)(p\(dist.key)).csv"),
        atomically: true,
        encoding: .utf8)
}