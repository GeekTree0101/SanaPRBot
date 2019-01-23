import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let botController = PRBotController()
    router.post("cmd", use: botController.slackComment)
    router.post("envirment", use: botController.setupSlackCommandService)
}
