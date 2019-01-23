import Foundation
import Vapor
import HTTP
import Crypto

protocol NetworkAPI {
    
    var route: (method: HTTPMethod, url: URL?) { get }
    var parameter: Dictionary<String, Any>? { get }
}

struct Network {
    
    static var shared = Network()
    var githubToken: String?
    var slackToken: String?
    var serviceToken: String?
    var isAuthrized: Bool = false
    
    struct Const {
        static let headers: HTTPHeaders = ["Accept": "application/json; charset=utf-8",
                                           "Content-Type": "application/json"]
    }
    
    enum URLConvertScope {
        case body
        case queryString
    }
    
    func request(_ req: Request,
                 api: NetworkAPI,
                 scope: URLConvertScope) -> Request {
        switch scope {
        case .queryString:
            guard var url = api.route.url else {
                return req
            }
            
            if let query = api.parameter?.queryString {
                url = URL(string: url.absoluteString + "?\(query)")!
            }
            
            req.http = HTTPRequest(method: api.route.method,
                                   url: url,
                                   headers: Const.headers)
            return req
        case .body:
            guard let url = api.route.url,
                let params = api.parameter,
                let body = try? JSONSerialization
                    .data(withJSONObject: params, options: .prettyPrinted)
                else {
                    return req
            }
            
            req.http = HTTPRequest(method: api.route.method,
                                   url: url,
                                   headers: Const.headers,
                                   body: body)
            return req
        }
    }
    
    
    func reqClient(_ req: Request,
                   method: HTTPMethod,
                   api: NetworkAPI,
                   scope: URLConvertScope) -> EventLoopFuture<Response> {
        let client = try! self.request(req,
                                       api: api,
                                       scope: scope)
            .make(Client.self)
        return client.get(req.http.url)
    }
}

extension Network {
    
    mutating func generateServiceToken() {
        let data = try? CryptoRandom().generateData(count: 30)
        self.serviceToken = data?.hexEncodedString()
        print("ServiceToken: \(serviceToken ?? "") \(Date.now)")
    }
    
    mutating func isVaildAuthToken(_ token: String) -> Bool {
        print("ErrorCode: \(self.serviceToken)")
        isAuthrized = self.serviceToken == token
        return isAuthrized
    }
    
    mutating func setupEnvirment(gitToken: String?,
                                 slackToken: String?) {
        self.slackToken = slackToken
        self.githubToken = gitToken
    }
}
