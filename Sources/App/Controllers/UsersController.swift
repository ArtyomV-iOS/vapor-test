//
//  File.swift
//  Test-API
//
//  Created by Artyom Vlasov on 17.06.2025.
//

import Vapor
import PostgresNIO
import Fluent
import JWT

struct LoginResponse: Content {
    var phone: String
}

struct AuthResponse: Content {
    var token: String
    var user: UsersDTO
}

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let router = routes.grouped("users")
        router.post("login", use: login)
        router.post("addUser", use: addUser)
//        excel.get("getData", use: getData)
//        excel.get("getSpeakers", use: getSpeakers)
    }
    
    
    @Sendable
    func login(req: Request) async throws -> AuthResponse {
        let model = try req.content.decode(LoginResponse.self)
        
        // Check if user with this phone exists
        guard let user = try await Users.query(on: req.db)
            .filter(\.$phone == model.phone)
            .first() else {
            throw Abort(.unauthorized, reason: "User not found")
        }
        
        // Generate JWT token
        let payload = JWTPayloadable(
            subject: user.id?.uuidString ?? "",
            expiration: Date().addingTimeInterval(86400) // 24 hours
        )
        
        let token = try req.jwt.sign(payload)
        
        return AuthResponse(
            token: token,
            user: user.toDTO()
        )
    }
    
    
    @Sendable
    func addUser(req: Request) async throws -> SuccessResponse {
        let user = try req.content.decode(Users.self)
        
        // Check if user with this email already exists
        if let _ = try await Users.query(on: req.db)
            .filter(\.$phone == user.phone)
            .first() {
            throw Abort(.conflict, reason: "User with phone \(user.phone) already exists")
        }
        
        do {
            try await user.save(on: req.db)
            return SuccessResponse(description: "User successfully created")
        } catch {
            req.logger.error("Failed to save user: \(error)")
            throw Abort(.internalServerError, reason: "Failed to create user: \(error.localizedDescription)")
        }
    }
}

// JWT Payload structure
struct JWTPayloadable: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
    }
    
    var subject: String
    var expiration: Date
    
    func verify(using signer: JWTSigner) throws {
        // Verify expiration
        guard expiration > Date() else {
            throw JWTError.claimVerificationFailure(name: "exp", reason: "Token has expired")
        }
    }
}
