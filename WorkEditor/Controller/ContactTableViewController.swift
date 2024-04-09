//
//  ContactTableViewController.swift
//  WorkEditor
//
//  Created by liga.griezne on 09/04/2024.
//

import UIKit
import Foundation

class ContactTableViewController: UIViewController {
    
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var allEmployees: [Employee] = []
    var filteredEmployees: [Employee] = []
    var sectionsData: [(position: Position, employees: [Employee])] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegate for search bar
        searchBar.delegate = self
        
        // Configure table view
        tableView.dataSource = self
        
        // Fetch employees for Tallinn and Tartu
        fetchEmployees()
        
        // Add pull-to-refresh functionality
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
            case .failure(let error):
                print("Error fetching Tallinn employees:", error.localizedDescription)
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
            case .failure(let error):
                // Handle error
                print("Error fetching Tartu employees:", error.localizedDescription)
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

extension ContactTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            // If search text is empty, display all employees
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
}
