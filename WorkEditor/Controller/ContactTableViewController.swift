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
    @objc func refreshData(_ sender: Any) {
        // Refresh both Tallinn and Tartu employees
        fetchEmployees()
    }
    func fetchEmployees() {
        // Fetch employees for both Tallinn and Tartu
        APIManager.fetchTallinnEmployees { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let tallinnEmployees):
                self.allEmployees.append(contentsOf: tallinnEmployees)
                self.fetchTartuEmployees()
            case .failure(_):
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                }
            }
        }
    }
    func fetchTartuEmployees() {
        APIManager.fetchTartuEmployees { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let tartuEmployees):
                self.allEmployees.append(contentsOf: tartuEmployees)
                self.updateSectionsData()
                DispatchQueue.main.async {
                    // Reload table view after fetching both Tallinn and Tartu employees
                    self.tableView.reloadData()
                    self.tableView.refreshControl?.endRefreshing()
                }
            case .failure(_):
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
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
        cell.textLabel?.text = "\(employee.fname) \(employee.lname)"
        // Check if there is a matching contact for the employee
        if employee.hasMatchingContact {
            // Create the button
            let button = UIButton(type: .system)
            button.setTitle("More", for: .normal) // Set the title for the normal state
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15) // Set the font for the title
            button.setTitleColor(.systemBlue, for: .normal) // Set the text color for the title
            button.addTarget(self, action: #selector(viewContactDetails(_:)), for: .touchUpInside)
            button.frame = CGRect(x: cell.contentView.bounds.width - 60, y: 5, width: 50, height: 35) // Adjust frame as needed
            // Add the button to the cell's content view
            cell.contentView.addSubview(button)
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
            // Filter employees based on search text
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
        if let cell = sender.superview?.superview as? UITableViewCell,
           let indexPath = tableView.indexPath(for: cell) {
            let employee = sectionsData[indexPath.section].employees[indexPath.row]
            let secondViewController = ContactViewController()
            secondViewController.selectedEmployee = employee
            navigationController?.pushViewController(secondViewController, animated: true)
        }
    }
}
//MARK: - UITableViewDelegate
extension ContactTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let employee = sectionsData[indexPath.section].employees[indexPath.row]
        let contactVC = ContactViewController()
        contactVC.selectedEmployee = employee
        
        guard let navigationController = self.navigationController else {
            return
        }
        
        navigationController.pushViewController(contactVC, animated: true)
    }
}
