import Foundation
import Vapor
import HTTP

enum GithubAPI {
    case loadPullRequest(String)
}

extension GithubAPI: NetworkAPI {
    var baseURL: URL {
        return URL(string: "https://api.github.com/")!
    }
    
    func repoURL(_ name: String) -> URL {
        return self.baseURL.appendingPathComponent("repos/\(name)")
    }
    
    func pullRequestURL(_ name: String) -> URL {
        return self.repoURL(name).appendingPathComponent("/pulls")
    }
    
    var route: (method: HTTPMethod, url: URL?) {
        switch self {
        case .loadPullRequest(let repoName):
            return (.GET, url: pullRequestURL(repoName))
        }
    }
    
    var parameter: Dictionary<String, Any>? {
        switch self {
        case .loadPullRequest:
            guard let gitToken = Network.shared.githubToken else {
                return nil
            }
            return ["access_token": gitToken]
        }
    }
}
