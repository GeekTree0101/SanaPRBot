import Foundation

struct SlackMessage: Encodable {
    let type: String = "in_channel"
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case text
        case type = "response_type"
    }
    
    init(_ message: String) {
        text = message
    }
}
