import Foundation
import Vapor

struct PRBotEnviorment: Codable {
    let gitRepoName: String
    let channel: String

    enum CodingKeys: String, CodingKey {
        case gitRepoName = "repo_name"
        case channel = "channel"
    }
}
