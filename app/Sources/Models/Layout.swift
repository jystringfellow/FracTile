import Foundation

struct Layout: Codable {
    let id: String
    let name: String
    let zones: [Zone]
    let metadata: [String: String]?
}
