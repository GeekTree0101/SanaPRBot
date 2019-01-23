import Foundation
import Vapor

struct EventLoopHelper {
    static func status(_ req: Request,
                       status: HTTPStatus) -> EventLoopFuture<HTTPStatus> {
        let event = req.eventLoop.newPromise(HTTPStatus.self)
        event.succeed(result: status)
        return event.futureResult
    }
    
    enum Scope {
        case message(String)
        case body(HTTPBody)
    }
    
    static func status(_ promise: EventLoopPromise<Response>,
                       res: Response,
                       status: HTTPStatus,
                       scope: Scope? = nil) -> EventLoopFuture<Response> {
        res.http.headers = Network.Const.headers
        
        if let scope = scope {
            switch scope {
            case .message(let msg):
                let slackMsgObj = SlackMessage(msg)
                if let data = try? JSONEncoder().encode(slackMsgObj) {
                    res.http.body = HTTPBody(data: data)
                }
            case .body(let data):
                res.http.body = data
            }
        }
        
        res.http.status = status
        promise.succeed(result: res)
        return promise.futureResult
    }
    
    static func status(_ res: Response,
                       status: HTTPStatus,
                       scope: Scope? = nil) -> Response {
        res.http.headers = Network.Const.headers
        
        if let scope = scope {
            switch scope {
            case .message(let msg):
                let slackMsgObj = SlackMessage(msg)
                if let data = try? JSONEncoder().encode(slackMsgObj) {
                    res.http.body = HTTPBody(data: data)
                }
            case .body(let data):
                res.http.body = data
            }
        }
        
        return res
    }
}
