import Fluent
import Vapor

struct UsersDTO: Content {
    var id: UUID?
    var name: String?
    var email: String?
    var role: String?
    var phone: String?
    
    func toModel() -> Users {
        let model = Users()
        
        model.id = self.id
        
        if let name = self.name {
            model.name = name
        }
        
        if let email = self.email {
            model.email = email
        }
        
        if let role = self.role {
            model.role = role
        }
        
        if let phone = self.phone {
            model.phone = phone
        }
        
        return model
    }
} 
