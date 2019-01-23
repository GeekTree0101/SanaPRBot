import Foundation
import Vapor

struct GithubPullReqeust: Decodable {
    let title: String
    let state: String
    var author: GithubUser
    var assignees: [GithubUser] = []
    var reviewers: [GithubUser] = []
    var labels: [GithubLabel] = []
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case state
        case author = "user"
        case assignees
        case reviewers = "requested_reviewers"
        case labels
        case url = "html_url"
    }
}

struct GithubUser: Decodable {
    let name: String
    enum CodingKeys: String, CodingKey {
        case name = "login"
    }
}

struct GithubLabel: Decodable {
    let name: String
    let _color: String
    var hexColor: String {
        return "#" + _color
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case _color = "color"
    }
}
