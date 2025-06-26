import Fluent

struct CreateEvents: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Сначала удаляем таблицу, если она существует
//        try await database.schema("todos").delete()
        
        // Создаем таблицу заново с UUID
        try await database.schema("events")
            .field("id", .uuid, .identifier(auto: false))
            .field("date", .string, .required)
            .field("time", .string, .required)
            .field("name", .string, .required)
            .field("role", .string, .required)
            .field("photo", .string, .required)
            .field("category", .string, .required)
            .field("title", .string, .required)
            .field("descripton", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("events").delete()
    }
}
