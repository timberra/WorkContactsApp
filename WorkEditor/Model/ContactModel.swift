//
//  ContactModel.swift
//  WorkEditor
//
//  Created by liga.griezne on 09/04/2024.
//
import Foundation

struct EmployeesWrapper: Codable {
    let employees: [Employee]
}
struct Employee: Codable {
    let fname: String
    let lname: String
    let position: Position
    let contactDetails: ContactDetails
    let projects: [String]?
    var hasMatchingContact: Bool = false

    private enum CodingKeys: String, CodingKey {
        case fname, lname, position, contactDetails
        case projects
    }
}

struct ContactDetails: Codable {
    let email: String
    let phone: String?

    private enum CodingKeys: String, CodingKey {
        case email, phone
    }

    init(email: String, phone: String? = nil) {
        self.email = email
        self.phone = phone
    }
}

enum Position: String, Codable {
    case IOS
    case ANDROID
    case WEB
    case PM
    case TESTER
    case SALES
    case OTHER
}

