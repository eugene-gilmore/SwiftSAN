import SwiftGraph
import Foundation

extension String : Error {
}

public struct AttributeNode : Codable, Equatable {
    var attributeName : String
    var value : String
}

public enum SANNode : Codable, Equatable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = container.allKeys.first else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath, debugDescription: "Unable to decode SANNode"
                )
            )
        }

        switch key {
        case .AttributeNode:
            self = .AttributeNode(
                try container.decode(SwiftSAN.AttributeNode.self, forKey: .AttributeNode)
            )
        case .SocialNode:
            self = .SocialNode(try container.decode(String.self, forKey: .SocialNode))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .AttributeNode(attribute):
            try container.encode(attribute, forKey: .AttributeNode)
        case let .SocialNode(name):
            try container.encode(name, forKey: .SocialNode)
        }
    }

    enum CodingKeys : CodingKey {
        case SocialNode, AttributeNode
    }

    case SocialNode(String), AttributeNode(AttributeNode)
}

public typealias SocialAttriubteNetwork = WeightedUniqueElementsGraph<SANNode,Double>

public func loadEgoNetwork(dir: URL, directedEdge : Bool = false) throws -> SocialAttriubteNetwork {
    guard let files = try? FileManager.default.contentsOfDirectory(
        atPath: dir.path) else {
        throw "Can't read contents of \(dir)"
    }
    let egoNodes = files.filter {
        $0.hasSuffix("egofeat")
    }.map {
        String($0.prefix(while: {$0 != "."}))
    }

    let graph = WeightedUniqueElementsGraph<SANNode,Double>()

    func readFile(file : String) throws-> String {
        guard let contents = try? String(contentsOf: dir.appendingPathComponent(file)) else {
            throw "Can't read file: \(file)"
        }
        return contents
    }

    for n in egoNodes {
        let egoIndex = graph.addVertex(.SocialNode(n))
        let edges = try readFile(file: n+".edges")
        .components(separatedBy: .newlines)
        .compactMap { (line : String) -> (n1: String, n2: String)? in
            let nodes = line.components(separatedBy: .whitespaces)
            guard nodes.count == 2 else {
                return nil
            }
            return (n1: nodes[0], n2: nodes[1])
        }
        for e in edges {
            let index1 = graph.addVertex(.SocialNode(e.n1))
            let index2 = graph.addVertex(.SocialNode(e.n2))
            graph.addEdge(fromIndex: index1, toIndex: index2, weight: 1, directed: directedEdge)
            graph.addEdge(fromIndex: egoIndex, toIndex: index1, weight: 1, directed: directedEdge)
        }

        let features = try readFile(file: n+".featnames")
        .components(separatedBy: .newlines)
        .compactMap { (line : String) -> (index: Int, attribute: AttributeNode)? in
            guard let index = Int(line.prefix(while: {!$0.isWhitespace})),
            let nameStartIndex = line.firstIndex(where: {$0.isWhitespace}),
            let nameEndIndex = line.lastIndex(of: ";") ,
            let valueStartIndex = Optional(line.index(nameEndIndex, offsetBy: 1)),
            valueStartIndex != line.endIndex else {
                return nil
            }
            let name = line[nameStartIndex...nameEndIndex]
            .trimmingCharacters(in: .whitespaces)
            let value = line[valueStartIndex..<line.endIndex]
            .trimmingCharacters(in: .whitespaces)
            return (index: index, attribute: AttributeNode(attributeName: name, value: value))
        }
        .sorted {$0.index < $1.index}
        .map { graph.addVertex(.AttributeNode($0.attribute)) }

        let _ = try readFile(file: n+".feat")
        .components(separatedBy: .newlines)
        .map { (line : String) -> () in
            let values = line.components(separatedBy: .whitespaces)
            let attributeValues = values.dropFirst().compactMap { Int($0) }
            guard let nodeName = values.first, attributeValues.count == features.count else {
                return
            }
            let index = graph.addVertex(.SocialNode(nodeName))
            for i in 0..<features.count {
                if(attributeValues[i] != 0) {
                    graph.addEdge(fromIndex: index, toIndex: features[i],
                    weight: Double(attributeValues[i]))
                }
            }
        }

        let _ = try readFile(file: n+".egofeat")
        .components(separatedBy: .newlines)
        .map { (line : String) -> () in
            let values = line.components(separatedBy: .whitespaces)
            let attributeValues = values.compactMap { Int($0) }
            guard attributeValues.count == features.count else {
                return
            }
            for i in 0..<features.count {
                if(attributeValues[i] != 0) {
                    graph.addEdge(fromIndex: egoIndex, toIndex: features[i],
                    weight: Double(attributeValues[i]))
                }
            }
        }
    }

    return graph
}