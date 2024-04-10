//
//  ContactTableViewDelegate.swift
//  WorkEditor
//
//  Created by liga.griezne on 10/04/2024.
//

import UIKit

class ContactTableViewDelegate: NSObject, UITableViewDelegate {
    
    var navigationController: UINavigationController?
    var sectionsData: [(position: Position, employees: [Employee])] = []
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let navigationController = navigationController else {
            return
        }
        
        let employee = sectionsData[indexPath.section].employees[indexPath.row]
        let contactVC = ContactViewController()
        contactVC.selectedEmployee = employee
        navigationController.pushViewController(contactVC, animated: true)
    }
}

