import SwiftSAN
import Foundation

var facebookDir = URL(fileURLWithPath: #filePath)
facebookDir.deleteLastPathComponent()
facebookDir = facebookDir.appendingPathComponent("../../Resources/facebook")

let g = try loadEgoNetwork(dir: facebookDir)
let socialNodes = g.vertices.filter { $0.isSocialNode }.compactMap { g.indexOfVertex($0) }
var attributeNodes = g.vertices.filter { $0.isAttributeNode }
.compactMap { (n: SANNode) -> (index : Int, node : AttributeNode)? in
    guard let index = g.indexOfVertex(n), let node = n.asAttributeNode else {
        return nil
    }
    return (index: index, node: node)
}

var output = attributeNodes.map { "\($0.node.attributeName):\($0.node.value)" }
.reduce("", {"\($0)\($1),"})
output = output + output.dropLast() 
for s in socialNodes {
    let line = try attributeNodes.map { try g.AdamicAdar(u: s, v: $0.index) }
    .reduce("", {"\($0)\($1),"}) 
    + attributeNodes.map { g.edgeExists(fromIndex: s, toIndex: $0.index) ? "1" : "0" }
    .reduce("", {"\($0)\($1),"}).dropLast()
    output += line + "\n"
}

try output.write(
    to: facebookDir.appendingPathComponent("classification.csv"),
    atomically: true,
    encoding: .utf8)