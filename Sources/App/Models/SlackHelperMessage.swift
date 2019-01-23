import Foundation

struct SlackHelperMessage: Encodable {
    let type = "ephemeral"
    let text: String = "😘 Need some help with SanaBot?"
    let attachments: [SlackHelperAttachment] = [
        .init(title: "현재 채널에서 Repository List 구독하기",
              text: "/sana mk REPO_NAME (ex: /sana setup balmbees/vingle-ios)"),
        .init(title: "Repository List 출력하기",
              text: "/sana ls REPO_NAME or /sana repo (default: 최초 등록한 repo name)"),
        .init(title: "Beta 독촉 (Client Only)",
              text: "/sana beta?"),
        .init(title: "현재 채널에서 Repository List 구독제거",
              text: "/sana rm REPO_NAME (ex: /sana rm balmbees/vingle-ios)")
    ]
    
    enum CodingKeys: String, CodingKey {
        case type = "response_type"
        case text
        case attachments = "attachments"
    }
}

struct SlackHelperAttachment: Encodable {
    let title: String
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case text
    }
}
