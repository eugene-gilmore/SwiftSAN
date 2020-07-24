import SwiftSAN
import Foundation

var facebookDir = URL(fileURLWithPath: #filePath)
facebookDir.deleteLastPathComponent()
facebookDir = facebookDir.appendingPathComponent("../../Resources/facebook")

let g = try loadEgoNetwork(dir: facebookDir)