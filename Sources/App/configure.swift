import Vapor
import HTTP

public func configure(_ config: inout Config,
                      _ env: inout Environment,
                      _ services: inout Services) throws {
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    var middlewares = MiddlewareConfig()
    middlewares.use(ErrorMiddleware.self)
    services.register(middlewares)
}
