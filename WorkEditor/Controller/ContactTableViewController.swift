//
//  ContactTableViewController.swift
//  WorkEditor
//
//  Created by liga.griezne on 09/04/2024.
//

import UIKit
import Foundation
import Contacts
import ContactsUI

class ContactTableViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var allEmployees: [Employee] = []
    var filteredEmployees: [Employee] = []
    var sectionsData: [(position: Position, employees: [Employee])] = []
    var contactTableViewDelegate = ContactTableViewDelegate()
    var phoneContactNames: Set<String> = []
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = contactTableViewDelegate // Set the tableView delegate
        searchBar.showsCancelButton = false
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        fetchEmployees()
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
//MARK: - Data fetching/refreshing
    @objc func refreshData(_ sender: Any) {
        showLoadingMessage("Refreshing data...")
        fetchEmployees()
    }
    func fetchEmployees() {
        APIManager.fetchTallinnEmployees { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let tallinnEmployees):
                self.addUniqueEmployees(tallinnEmployees)
                self.fetchTartuEmployees()
            case .failure(let error):
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                    self.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    func fetchTartuEmployees() {
        APIManager.fetchTartuEmployees { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let tartuEmployees):
                self.addUniqueEmployees(tartuEmployees)
                self.fetchPhoneContacts()
                self.updateSectionsData()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tableView.refreshControl?.endRefreshing()
                    self.dismissLoadingMessage()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                    self.dismissLoadingMessage()
                    self.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    func addUniqueEmployees(_ employees: [Employee]) {
        var uniqueEmployeeIdentifiers: Set<String> = Set()
        let newEmployees = employees.filter { employee in
            let identifier = "\(employee.fname.lowercased()) \(employee.lname.lowercased())"
            let isUnique = !uniqueEmployeeIdentifiers.contains(identifier)
            if isUnique {
                uniqueEmployeeIdentifiers.insert(identifier)
            }
            return isUnique
        }
        let uniqueNewEmployees = newEmployees.filter { newEmployee in
            let identifier = "\(newEmployee.fname.lowercased()) \(newEmployee.lname.lowercased())"
            return !self.allEmployees.contains { existingEmployee in
                let existingIdentifier = "\(existingEmployee.fname.lowercased()) \(existingEmployee.lname.lowercased())"
                return existingIdentifier == identifier
            }
        }
        allEmployees.append(contentsOf: uniqueNewEmployees)
    }
    func fetchPhoneContacts() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { [weak self] granted, error in
            guard let self = self, granted else { return }
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey] as [CNKeyDescriptor]
            let request = CNContactFetchRequest(keysToFetch: keys)
            do {
                var uniquePhoneContactNames: Set<String> = Set()
                try store.enumerateContacts(with: request) { contact, _ in
                    let fullName = "\(contact.givenName) \(contact.familyName)"
                    uniquePhoneContactNames.insert(fullName.lowercased())
                }
                self.phoneContactNames = uniquePhoneContactNames
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                DispatchQueue.main.async {
                    self.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    func updateSectionsData() {
        let uniquePositions = Set(allEmployees.map { $0.position })
        let sortedPositions = uniquePositions.sorted { $0.rawValue < $1.rawValue }
        sectionsData = sortedPositions.map { position in
            let employeesForPosition = allEmployees.filter { $0.position == position }
            let sortedEmployees = employeesForPosition.sorted { $0.lname < $1.lname }
            return (position: position, employees: sortedEmployees)
        }
    }
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alert.addAction(dismissAction)
        present(alert, animated: true, completion: nil)
    }
    func showLoadingMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
    }
    func dismissLoadingMessage() {
        dismiss(animated: true)
    }
}
//MARK: - Data Source Logic
extension ContactTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionsData.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionsData[section].employees.count
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionsData[section].position.rawValue
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "employeeCell", for: indexPath)
        let employee = sectionsData[indexPath.section].employees[indexPath.row]
        cell.textLabel?.text = "\(employee.lname) \(employee.fname)"
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let contactExists = phoneContactNames.contains("\(employee.fname.lowercased()) \(employee.lname.lowercased())")
        if contactExists {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "person.crop.circle"), for: .normal)
            button.addTarget(self, action: #selector(viewContactDetails(_:)), for: .touchUpInside)
            button.tag = indexPath.row
            let buttonWidth: CGFloat = 30
            let buttonHeight: CGFloat = 30
            button.frame = CGRect(x: cell.contentView.frame.width - buttonWidth - 10,
                                  y: (cell.contentView.frame.height - buttonHeight) / 2,
                                  width: buttonWidth, height: buttonHeight)
            cell.contentView.addSubview(button)
        } else {
            for subview in cell.contentView.subviews {
                if let button = subview as? UIButton, button.titleLabel?.text == "Contact Exists" {
                    button.removeFromSuperview()
                }
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.lightGray
        let headerLabel = UILabel(frame: CGRect(x: 15, y: 5, width: tableView.frame.width - 30, height: 20))
        headerLabel.font = UIFont.boldSystemFont(ofSize: 16)
        headerLabel.textColor = UIColor.black
        headerLabel.text = sectionsData[section].position.rawValue
        headerView.addSubview(headerLabel)
        return headerView
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
}
//MARK: - Searchbar logic
extension ContactTableViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        filteredEmployees = allEmployees
        updateSectionsData(filteredEmployees)
        tableView.reloadData()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredEmployees = allEmployees
        } else {
            filteredEmployees = allEmployees.filter { employee in
                let searchString = searchText.lowercased()
                return employee.fname.lowercased().contains(searchString) ||
                employee.lname.lowercased().contains(searchString) ||
                employee.contactDetails.email.lowercased().contains(searchString) ||
                (employee.projects?.contains { $0.lowercased().contains(searchString) } ?? false) ||
                employee.position.rawValue.lowercased().contains(searchString)
            }
        }
        updateSectionsData(filteredEmployees)
        tableView.reloadData()
    }
    func updateSectionsData(_ employees: [Employee]) {
        let allPositions: [Position] = [.IOS, .ANDROID, .WEB, .PM, .TESTER, .SALES, .OTHER]
        let uniquePositions = Set(employees.map { $0.position })
        let sortedPositions = allPositions.filter { uniquePositions.contains($0) }
        sectionsData = sortedPositions.map { position in
            let employeesForPosition = employees.filter { $0.position == position }
            let sortedEmployees = employeesForPosition.sorted { $0.lname < $1.lname }
            return (position: position, employees: sortedEmployees)
        }
        let positionsWithoutEmployees = allPositions.filter { !uniquePositions.contains($0) }
        for position in positionsWithoutEmployees {
            sectionsData.append((position: position, employees: []))
        }
        sectionsData.sort { $0.position.rawValue < $1.position.rawValue }
    }
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(false, animated: true)
        return true
    }
}
//MARK: - Gesture Recognizer
extension ContactTableViewController: UIGestureRecognizerDelegate {
    @objc func viewContactDetails(_ sender: UIButton) {
        guard let cell = sender.superview?.superview as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell),
              let employee = getEmployee(at: indexPath) else {
            return
        }
        let fullName = "\(employee.fname) \(employee.lname)"
        let alertController = UIAlertController(title: nil, message: "Do you want to open Contacts for \(fullName)?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        let openAction = UIAlertAction(title: "Open", style: .default) { _ in
            self.openPhoneContact(for: employee)
        }
        alertController.addAction(openAction)
        present(alertController, animated: true, completion: nil)
    }
    func getEmployee(at indexPath: IndexPath) -> Employee? {
        return sectionsData[indexPath.section].employees[indexPath.row]
    }
    func openPhoneContact(for employee: Employee) {
        let store = CNContactStore()
        let predicate = CNContact.predicateForContacts(matchingName: "\(employee.fname) \(employee.lname)")
        let keys = [CNContactViewController.descriptorForRequiredKeys()] as [CNKeyDescriptor]
        do {
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
            guard let contact = contacts.first else {
                print("Contact not found.")
                return
            }
            let contactViewController = CNContactViewController(for: contact)
            contactViewController.allowsActions = false
            contactViewController.allowsEditing = false
            navigationController?.pushViewController(contactViewController, animated: true)
        } catch {
            print("Error fetching contact: \(error)")
        }
    }
}
//MARK: - UITableViewDelegate
extension ContactTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let employee = getEmployee(at: indexPath) else {
            return
        }
        let contactVC = ContactViewController()
        contactVC.selectedEmployee = employee
        navigationController?.pushViewController(contactVC, animated: true)
    }
}
