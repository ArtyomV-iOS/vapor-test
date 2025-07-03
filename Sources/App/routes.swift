import Fluent
import Vapor

func routes(_ app: Application) throws {
    // Health check endpoint
    app.get("health") { req async throws -> String in
        return "OK"
    }
    
    try app.register(collection: EventsController())
    try app.register(collection: UsersController())
}
