import Foundation

struct PRBotSetup: Decodable {
    let list: [PRBotEnviorment]
    
    enum CodingKeys: String, CodingKey {
        case list
    }
}
