import Vapor
import PostgresNIO
import Fluent

struct FileUpload: Content {
    var file: File
}

struct GoogleSheetRequest: Content {
    let apiKey: String
    let range: String // например, "Лист1!A1:I1000"
}

struct GoogleSheetAppendRequest: Content {
    let accessToken: String // OAuth2 access token пользователя/сервиса
    let range: String       // Например, "Лист1!A1:I1"
    let event: EventsDTO    // DTO с данными события
}

struct EventsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let router = routes.grouped("events")
        router.post("uploadBase", use: uploadExcel)
        router.get("getData", use: getData)
        router.get("getSpeakers", use: getSpeakers)
        router.post("uploadGoogle", use: uploadFromGoogleSheet)
        router.post("appendGoogle", use: appendToGoogleSheet)
    }
    
    private func parseCSVLine(_ line: String, separator: Character) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        var i = 0
        
        while i < line.count {
            let char = line[line.index(line.startIndex, offsetBy: i)]
            
            if char == "\"" {
                if i + 1 < line.count {
                    let nextChar = line[line.index(line.startIndex, offsetBy: i + 1)]
                    if nextChar == "\"" {
                        // Двойная кавычка внутри кавычек - добавляем одну кавычку
                        currentField.append("\"")
                        i += 2
                        continue
                    }
                }
                insideQuotes.toggle()
            } else if char == separator && !insideQuotes {
                result.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            i += 1
        }
        
        // Добавляем последнее поле
        result.append(currentField)
        
        // Очистка полей
        return result.map { field in
            var cleaned = field.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Удаляем кавычки только если они парные и находятся в начале и конце
            if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
                cleaned = String(cleaned.dropFirst().dropLast())
            }
            
            return cleaned
        }
    }
    
    @Sendable
    func uploadExcel(req: Request) async throws -> SuccessResponse {
        // Получаем файл из multipart/form-data
        let upload = try req.content.decode(FileUpload.self)
        let buffer = upload.file.data
        
        guard let content = buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes) else {
            throw Abort(.badRequest, reason: "Invalid file encoding")
        }

        // Нормализуем переносы строк и разбиваем на строки
        let normalizedContent = content.replacingOccurrences(of: "\r\n", with: "\n")
                                     .replacingOccurrences(of: "\r", with: "\n")
        
        // Разбиваем на строки, сохраняя переносы строк внутри кавычек
        var lines: [String] = []
        var currentLine = ""
        var insideQuotes = false
        
        for char in normalizedContent {
            if char == "\"" {
                insideQuotes.toggle()
                currentLine.append(char)
            } else if char == "\n" && !insideQuotes {
                lines.append(currentLine)
                currentLine = ""
            } else {
                currentLine.append(char)
            }
        }
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        var imported = 0
        var skipped = 0
        
        // Очистка базы
        try await Events.query(on: req.db).delete()
        
        // Парсинг заголовков
        guard let headerLine = lines.first else {
            throw Abort(.badRequest, reason: "Empty file")
        }
        
        // Разбиваем заголовки с учетом точки с запятой
        let headers = parseCSVLine(headerLine, separator: ";")
            .filter { !$0.isEmpty }
        
        req.logger.info("Found headers: \(headers)")
        
        let headerIndices = Dictionary(uniqueKeysWithValues: headers.enumerated().map { ($1, $0) })
        
        // Проверка наличия всех необходимых заголовков
        let requiredHeaders = ["ID", "Дата", "Время", "Имя спикера", "Роль", "Фото", "Категория", "Название", "Описание"]
        for header in requiredHeaders {
            guard headerIndices[header] != nil else {
                throw Abort(.badRequest, reason: "Missing required header: \(header)")
            }
        }

        // Парсинг данных
        for (index, line) in lines.dropFirst().enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            // Разбиваем данные с учетом точки с запятой
            let columns = parseCSVLine(trimmed, separator: ";")
            
            if columns.count < headers.count {
                req.logger.warning("Line \(index + 2) skipped: not enough columns (\(columns.count))")
                skipped += 1
                continue
            }

            // Логируем значения для отладки
            req.logger.info("Processing line \(index + 2):")
            for (header, index) in headerIndices {
                req.logger.info("\(header): \(columns[index])")
            }

            // Создание события с данными из соответствующих колонок
            let event = Events(
                id: UUID(uuidString: columns[headerIndices["ID"]!]),
                date: columns[headerIndices["Дата"]!],
                time: columns[headerIndices["Время"]!],
                name: columns[headerIndices["Имя спикера"]!],
                role: columns[headerIndices["Роль"]!],
                photo: columns[headerIndices["Фото"]!],
                category: columns[headerIndices["Категория"]!],
                title: columns[headerIndices["Название"]!],
                descripton: columns[headerIndices["Описание"]!]
            )

            do {
                try await event.save(on: req.db)
                imported += 1
            } catch {
                req.logger.error("Failed to save event on line \(index + 2): \(error)")
                skipped += 1
            }
        }

        req.logger.info("Imported: \(imported), Skipped: \(skipped)")
        if skipped == 0 {
            return SuccessResponse(description: "Success upload all: \(imported)")
        } else if imported > 0, skipped > 0 {
            return SuccessResponse(description: "SemiSuccess upload: \(imported), skipped: \(skipped)")
        } else if imported == 0, skipped > 0 {
            return SuccessResponse(description: "Fail upload, skipped all \(skipped)")
        }
        return SuccessResponse(description: "Upload empty")
    }
    
    @Sendable
    func getData(req: Request) async throws -> [EventsDTO] {
        try await Events.query(on: req.db).all().map { $0.toDTO() }
    }
    
    @Sendable
    func getSpeakers(req: Request) async throws -> [SpeakerResponse] {
        try await Events.query(on: req.db).all().map { $0.toSpeaker() }
    }

    @Sendable
    func uploadFromGoogleSheet(req: Request) async throws -> SuccessResponse {
        let sheetId = "1WZdX_E1t2RGS-jMWTSILG750fp6HmKBTNl-vvc4NEho"
        let params = try req.content.decode(GoogleSheetRequest.self)
        let url = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/\(params.range)?key=\(params.apiKey)"

        let client = req.client
        let response = try await client.get(URI(string: url))
        guard response.status == .ok else {
            throw Abort(.badRequest, reason: "Failed to fetch Google Sheet")
        }

        struct GoogleSheetResponse: Content {
            let values: [[String]]
        }

        let sheet = try response.content.decode(GoogleSheetResponse.self)
        guard let headers = sheet.values.first else {
            throw Abort(.badRequest, reason: "No headers in sheet")
        }

        let headerIndices = Dictionary(uniqueKeysWithValues: headers.enumerated().map { ($1, $0) })
        let requiredHeaders = ["ID", "Дата", "Время", "Имя спикера", "Роль", "Фото", "Категория", "Название", "Описание"]
        for header in requiredHeaders {
            guard headerIndices[header] != nil else {
                throw Abort(.badRequest, reason: "Missing required header: \(header)")
            }
        }

        // Очистка базы
        try await Events.query(on: req.db).delete()

        var imported = 0
        var skipped = 0

        for row in sheet.values.dropFirst() {
            if row.count < headers.count { skipped += 1; continue }
            let event = Events(
                id: UUID(uuidString: row[headerIndices["ID"]!]),
                date: row[headerIndices["Дата"]!],
                time: row[headerIndices["Время"]!],
                name: row[headerIndices["Имя спикера"]!],
                role: row[headerIndices["Роль"]!],
                photo: row[headerIndices["Фото"]!],
                category: row[headerIndices["Категория"]!],
                title: row[headerIndices["Название"]!],
                descripton: row[headerIndices["Описание"]!]
            )
            do {
                try await event.save(on: req.db)
                imported += 1
            } catch {
                skipped += 1
            }
        }

        return SuccessResponse(description: "Imported: \(imported), Skipped: \(skipped)")
    }

    @Sendable
    func appendToGoogleSheet(req: Request) async throws -> SuccessResponse {
        let sheetId = "1WZdX_E1t2RGS-jMWTSILG750fp6HmKBTNl-vvc4NEho"
        let params = try req.content.decode(GoogleSheetAppendRequest.self)
        let url = "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)/values/\(params.range):append?valueInputOption=USER_ENTERED?key=\(params.accessToken)"

        // Формируем массив значений в нужном порядке
        let values: [[String]] = [[
            params.event.id?.uuidString ?? "",
            params.event.date ?? "",
            params.event.time ?? "",
            params.event.name ?? "",
            params.event.role ?? "",
            params.event.photo ?? "",
            params.event.category ?? "",
            params.event.title ?? "",
            params.event.descripton ?? ""
        ]]

        let body: [String: Any] = ["values": values]
        let googleBody = try JSONSerialization.data(withJSONObject: body)

        let client = req.client
        let response = try await client.post(URI(string: url)) { req in
//            req.headers.bearerAuthorization = .init(token: params.accessToken)
            req.headers.contentType = .json
            req.body = .init(data: googleBody)
        }

        guard response.status == .ok else {
            let errorText = try? response.body?.getString(at: response.body?.readerIndex ?? 0, length: response.body?.readableBytes ?? 0)
            throw Abort(.badRequest, reason: "Failed to append to Google Sheet: \(errorText ?? "Unknown error")")
        }

        return SuccessResponse(description: "Event added to Google Sheet")
    }
}


