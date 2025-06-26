//
//  File.swift
//  Test-API
//
//  Created by Artyom Vlasov on 10.06.2025.
//

import Vapor

struct SuccessResponse: Content {
    var code: Int = 200
    var description: String = "Success"
}


struct SpeakerResponse: Content {
    var name: String?
    var role: String?
}
