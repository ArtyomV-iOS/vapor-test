import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: EventsController())
    try app.register(collection: UsersController())
}
