import Foundation

// ref: https://api.slack.com/custom-integrations/slash-commands
struct SlackCommand: Decodable {
    let token: String?
    let channelName: String?
    let command: String?
    let text: String?
    
    enum CodingKeys: String, CodingKey {
        case token
        case channelName = "channel_name"
        case command = "command"
        case text
    }
}
