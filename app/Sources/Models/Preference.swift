import Foundation

struct Preference: Codable {
    let hotkeys: [String: String]
    let defaultModifier: String
    let quickSwitchBindings: [String: String]
}
