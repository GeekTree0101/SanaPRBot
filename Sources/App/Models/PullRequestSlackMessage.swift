import Foundation

struct PullRequestSlackMessage: Encodable {
    let type = "in_channel"
    let text: String
    let attachments: [PullRequestAttachment]
    
    enum CodingKeys: String, CodingKey {
        case type = "response_type"
        case text
        case attachments = "attachments"
    }
    
    enum Scope {
        case betaPressure
        case pullRequestListOnly(String)
    }
    
    init(_ pullRequests: [GithubPullReqeust], scope: Scope) {
        // generate attachments ref: https://api.slack.com/docs/message-attachments
        attachments = pullRequests.map { PullRequestAttachment($0) }
        
        switch scope {
        case .betaPressure:
            text = "☝️ Code Review 부탁드립니다. Beta배포까지 예상 소요시간 *\(pullRequests.count.timeStamp) ± 30min* <!channel>"
        case .pullRequestListOnly(let repoName):
            text = "\(repoName): Pull Request List"
        }
    }
}

struct PullRequestAttachment: Encodable {
    struct Const {
        static let defaultColor: String = "#84888e"
    }
    let title: String
    let color: String
    let link: String
    let fields: [PullRequestAttachmentField]?
    
    enum CodingKeys: String, CodingKey {
        case title
        case color
        case link = "title_link"
        case fields
    }
    
    init(_ pullRequest: GithubPullReqeust) {
        self.title = pullRequest.title
        self.color = pullRequest.labels
            .map { $0.hexColor }.first ?? Const.defaultColor
        self.link = pullRequest.url
        var elements: [PullRequestAttachmentField] = []
        elements.append(.init(.assignee(pullRequest.assignees)))
        elements.append(.init(.reviewer(pullRequest.reviewers)))
        elements.append(.init(.status(pullRequest.labels)))
        self.fields = elements.isEmpty ? nil: elements
    }
}

struct PullRequestAttachmentField: Encodable {
    let title: String
    let value: String
    let short: Bool
    
    enum Scope {
        case assignee([GithubUser])
        case reviewer([GithubUser])
        case status([GithubLabel])
        
        var title: String {
            switch self {
            case .assignee:
                return "Assignee"
            case .reviewer:
                return "Reviewer"
            case .status:
                return "Status"
            }
        }
        
        var value: String {
            switch self {
            case .assignee(let users):
                if users.isEmpty {
                    return "⚠️Assignee가 없어요."
                } else {
                    return users.map { $0.name }.joined(separator: " · ")
                }
            case .reviewer(let users):
                if users.isEmpty {
                    return "⚠️Reviewer가 없어요."
                } else {
                    return users.map { $0.name }.joined(separator: " · ")
                }
            case .status(let lables):
                if lables.isEmpty {
                    return "⚠️PR확인해주세요!"
                } else {
                    return lables.map { $0.name }.joined(separator: " · ")
                }
            }
        }
        
        var isShorten: Bool {
            switch self {
            case .assignee, .reviewer:
                return true
            case .status:
                return false
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case title
        case value
        case short
    }
    
    init(_ scope: Scope) {
        self.title = scope.title
        self.value = scope.value
        self.short = scope.isShorten
    }
}
