import Vapor
import HTTP

final class PRBotController {
    
    private var cachedEnvirments: [PRBotEnviorment] = []

    enum Command: String {
        case test = "test"
        case beta = "beta?"
    }
    
    enum CommandScope: String {
        case help = "help"
        case list = "ls"
        case setup = "mk"
        case remove = "rm"
        case beta = "beta?"
        case sana = "hi"
    }
    
    func slackComment(_ req: Request) throws -> Future<Response> {
        let response = req.makeResponse()
        let promise = req.eventLoop.newPromise(Response.self)
        
        // Authrized Validation
        guard Network.shared.isAuthrized else {
            return EventLoopHelper.status(promise,
                                          res: response,
                                          status: .unauthorized)
        }
        
        return try req.content
            .decode(SlackCommand.self)
            .flatMap(to: Response.self, { cmd in
                // Slack Token Authrized Validation
                guard cmd.token == Network.shared.slackToken else {
                    return EventLoopHelper.status(promise,
                                                  res: response,
                                                  status: .forbidden)
                }
                
                let filteredEnvList = self.cachedEnvirments
                    .filter { $0.channel == cmd.channelName }
                
                // Command Validation with Envirments
                guard let params: [String] = cmd.text?
                        .split(separator: " ")
                        .map({ String($0) }),
                    let scopeParam: String = params.first else {
                        return EventLoopHelper.status(promise,
                                                      res: response,
                                                      status: .notFound)
                }
                
                // Command Scope
                let scope = CommandScope(rawValue: scopeParam) ?? .sana
                
                switch scope {
                case .beta, .list:
                    guard !filteredEnvList.isEmpty,
                        let reponame = self.getRepositoryName(params, list: filteredEnvList) else {
                            return EventLoopHelper.status(promise,
                                                          res: response,
                                                          status: .notFound)
                    }
                    return self.loadGithubPullRequest(req,
                                                      reponame: reponame,
                                                      scope: scope)
                        .map(to: Response.self, { body in
                            return EventLoopHelper.status(response,
                                                          status: .ok,
                                                          scope: .body(body))
                        })
                case .setup:
                    return self.setupResponse(promise,
                                              res: response,
                                              params: params,
                                              cmd: cmd)
                case .remove:
                    guard !filteredEnvList.isEmpty else {
                        return EventLoopHelper.status(promise,
                                                      res: response,
                                                      status: .notFound)
                    }
                    return self.removeResponse(promise,
                                               res: response,
                                               params: params,
                                               filteredEnvList: filteredEnvList,
                                               cmd: cmd)
                case .help:
                    return self.helpResponse(promise, res: response)
                default:
                    return self.defaultResponse(promise, res: response)
                }
            })
    }
    
    func setupSlackCommandService(_ req: Request) throws -> Future<HTTPStatus> {
        guard let serviceToken = req.http.headers.firstValue(name: .authorization),
            Network.shared.isVaildAuthToken(serviceToken) else {
                let event = req.eventLoop.newPromise(HTTPStatus.self)
                event.succeed(result: HTTPStatus.unauthorized)
                return event.futureResult
        }
        
        var slackToken: String?
        var githubAPIToken: String?
        
        req.http.headers.forEach({ name, value in
            switch name {
            case "Slack-Token":
                slackToken = value
            case "Github-Token":
                githubAPIToken = value
            default:
                break
            }
        })
        
        guard slackToken != nil && githubAPIToken != nil else {
            let event = req.eventLoop.newPromise(HTTPStatus.self)
            event.succeed(result: HTTPStatus.forbidden)
            return event.futureResult
        }
        
        return try req.content
            .decode(PRBotSetup.self)
            .map(to: HTTPStatus.self, {
                Network.shared.setupEnvirment(gitToken: githubAPIToken,
                                              slackToken: slackToken)
                self.cachedEnvirments = $0.list
                return .ok
            })
    }
    
}

// private operation
extension PRBotController {
    private func setupResponse(_ promise: EventLoopPromise<Response>,
                               res: Response,
                               params: [String],
                               cmd: SlackCommand) -> Future<Response> {
        guard let channel = cmd.channelName,
            params.count > 1 else {
                return EventLoopHelper.status(promise,
                                              res: res,
                                              status: .forbidden)
        }
        
        let generatedEnvList = params.suffix(from: 1)
            .map { name -> PRBotEnviorment? in
                guard self.cachedEnvirments
                    .contains(where: { $0.channel == channel &&
                        $0.gitRepoName == name }) else {
                            return PRBotEnviorment(gitRepoName: name,
                                                   channel: channel)
                }
                return nil
            }.filter { $0 != nil } as! [PRBotEnviorment]
        
        self.cachedEnvirments.append(contentsOf: generatedEnvList)
        let text = generatedEnvList
            .map { $0.gitRepoName }
            .joined(separator: " · ")
        return EventLoopHelper.status(promise,
                                      res:  res,
                                      status: .ok,
                                      scope: .message("\(text) 구독 🙆🏼"))
    }
    
    private func removeResponse(_ promise: EventLoopPromise<Response>,
                                res: Response,
                                params: [String],
                                filteredEnvList: [PRBotEnviorment],
                                cmd: SlackCommand) -> Future<Response> {
        guard let reponame =
            self.getRepositoryName(params, list: filteredEnvList),
            let index = self.cachedEnvirments
                .index(where: { $0.channel == cmd.channelName &&
                    $0.gitRepoName == reponame }) else {
                        return EventLoopHelper.status(promise,
                                                      res: res,
                                                      status: .notFound)
        }
        
        self.cachedEnvirments.remove(at: index)
        return EventLoopHelper.status(promise,
                                      res:  res,
                                      status: .ok,
                                      scope: .message("\(reponame) 구독 취소 🙆🏼"))
    }
    
    private func defaultResponse(_ promise: EventLoopPromise<Response>,
                                 res: Response) -> Future<Response> {
        let sanaErok: String = ["바니바니바니바니 당근당근! 캬~",
                                "야 노네만 미곤개 나갈 고냐",
                                "온니는 공쩡돼요",
                                "괜찮아. 난 쿨한 여자니까.",
                                "야. 너 귤 어떻게 까냐?",
                                "오빠야. 어디 가나? 나 버리고 가나? ",
                                "치! 즈! 김! 빱!",
                                "오효오효~~~~"].random ?? "Hi!"
        return EventLoopHelper.status(promise,
                                      res: res,
                                      status: .ok,
                                      scope: .message(sanaErok))
    }
    
    private func helpResponse(_ promise: EventLoopPromise<Response>,
                              res: Response) -> Future<Response> {
        let helper = SlackHelperMessage()
        guard let encode = try? JSONEncoder().encode(helper) else {
            return EventLoopHelper.status(promise,
                                          res: res,
                                          status: .internalServerError)
        }
        return EventLoopHelper
            .status(promise,
                    res: res,
                    status: .ok,
                    scope: .body(HTTPBody(data: encode)))
    }
    
    private func getRepositoryName(_ params: [String],
                                   list: [PRBotEnviorment]) -> String? {
        // Find Github Repository Name
        if params.count > 1,
            let targetRepoName = params.last,
            let index = list
                .index(where: { $0.gitRepoName == targetRepoName }) {
            return list[index].gitRepoName
        } else if let targetRepoName = list.first?.gitRepoName {
            return targetRepoName
        } else {
            return nil
        }
    }
    
    private func loadGithubPullRequest(_ req: Request,
                                       reponame: String,
                                       scope: CommandScope) -> Future<HTTPBody>  {
        let api = GithubAPI.loadPullRequest(reponame)
        return Network.shared.reqClient(req,
                                        method: .GET,
                                        api: api,
                                        scope: .queryString)
            .map(to: [GithubPullReqeust].self, { res -> [GithubPullReqeust] in
                guard let data = res.http.body.data else {
                    return []
                }
                return try JSONDecoder().decode([GithubPullReqeust].self, from: data)
            })
            .map(to: HTTPBody.self, { pullRequests -> HTTPBody in
                let msg: PullRequestSlackMessage
                switch scope {
                case .beta:
                    msg = PullRequestSlackMessage(pullRequests,
                                                  scope: .betaPressure)
                default:
                    msg = PullRequestSlackMessage(pullRequests,
                                                  scope: .pullRequestListOnly(reponame))
                }
                let data: Data = try JSONEncoder().encode(msg)
                return HTTPBody(data: data)
            })
    }
}
