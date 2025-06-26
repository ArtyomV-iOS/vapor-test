import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Configure JWT
    app.jwt.signers.use(.hs256(key: "your-secret-key-here"))

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "postgres",
        password: Environment.get("DATABASE_PASSWORD") ?? "postgres",
        database: Environment.get("DATABASE_NAME") ?? "postgres",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    app.migrations.add(CreateEvents())
    app.migrations.add(CreateUsers())

    app.views.use(.leaf)

    // register routes
    try routes(app)
}
