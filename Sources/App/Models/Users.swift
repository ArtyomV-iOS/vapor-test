import Fluent
import struct Foundation.UUID

final class Users: Model, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "role")
    var role: String

    @Field(key: "phone")
    var phone: String


    init() { }

    init(id: UUID? = nil, name: String, email: String, role: String, phone: String) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.phone = phone
    }
    
    func toDTO() -> UsersDTO {
        .init(
            id: self.id,
            name: self.$name.value,
            email: self.$email.value,
            role: self.$role.value,
            phone: self.$phone.value
        )
    }
} 
