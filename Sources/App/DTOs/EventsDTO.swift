import Fluent
import Vapor

struct EventsDTO: Content {
    var id: UUID?
    var date: String?
    var time: String?
    var name: String?
    var role: String?
    var photo: String?
    var category: String?
    var title: String?
    var descripton: String?
    
    func toModel() -> Events {
        let model = Events()
        
        model.id = self.id
        
        if let date = self.date {
            model.date = date
        }
        
        if let time = self.time {
            model.time = time
        }
        
        if let name = self.name {
            model.name = name
        }
        
        if let role = self.role {
            model.role = role
        }
        
        if let photo = self.photo {
            model.photo = photo
        }
        
        if let category = self.category {
            model.category = category
        }
        
        if let title = self.title {
            model.title = title
        }
        
        if let descripton = self.descripton {
            model.descripton = descripton
        }
        
        return model
    }
}
