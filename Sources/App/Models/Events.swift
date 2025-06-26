import Fluent
import struct Foundation.UUID

/// Property wrappers interact poorly with `Sendable` checking, causing a warning for the `@ID` property
/// It is recommended you write your model with sendability checking on and then suppress the warning
/// afterwards with `@unchecked Sendable`.
final class Events: Model, @unchecked Sendable {
    static let schema = "events"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "date")
    var date: String
    
    @Field(key: "time")
    var time: String
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "role")
    var role: String

    @Field(key: "photo")
    var photo: String
    
    @Field(key: "category")
    var category: String
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "descripton")
    var descripton: String
    
    

    init() { }

    init(id: UUID? = nil, date: String, time: String, name: String, role: String, photo: String, category: String, title: String, descripton: String) {
        self.id = id
        self.date = date
        self.time = time
        self.name = name
        self.role = role
        
        self.photo = photo
        self.category = category
        self.title = title
        self.descripton = descripton
    }
    
    func toDTO() -> EventsDTO {
        .init(
            id: self.id,
            date: self.$date.value,
            time: self.$time.value,
            name: self.$name.value,
            role: self.$role.value,
            
            photo: self.$photo.value,
            category: self.$category.value,
            title: self.$title.value,
            descripton: self.$descripton.value
        )
    }
    
    func toSpeaker() -> SpeakerResponse {
        .init(name: self.$name.value,
              role: self.$role.value)
    }
}
