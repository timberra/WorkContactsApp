//
//  ContactViewController.swift
//  WorkEditor
//
//  Created by liga.griezne on 09/04/2024.
//

import Contacts
import ContactsUI
import UIKit

class ContactViewController: UIViewController {
    
    var selectedEmployee: Employee!
    
    private let projectsTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "projectCell")
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Labels for name, position, email, and phone number
        let boldYellowFont = UIFont.boldSystemFont(ofSize: 12.0)
        let smallBlackFont = UIFont.systemFont(ofSize: 16.0)
        let boldBlackFont = UIFont.boldSystemFont(ofSize: 21.0)
        let boldYellowAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: boldYellowFont, NSAttributedString.Key.foregroundColor: UIColor.systemYellow]
        let smallBlackAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: smallBlackFont, NSAttributedString.Key.foregroundColor: UIColor.black]
        let boldBlackAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: boldBlackFont, NSAttributedString.Key.foregroundColor: UIColor.black]
        
        let fullName = "\(selectedEmployee.fname) \(selectedEmployee.lname)"
        let nameLabel = createLabel(with: fullName, attributes: boldBlackAttributes)
        
        let positionTitleLabel = createLabel(with: "POSITION", attributes: boldYellowAttributes)
        let positionInfoLabel = createLabel(with: selectedEmployee.position.rawValue, attributes: smallBlackAttributes)
        
        let emailTitleLabel = createLabel(with: "EMAIL", attributes: boldYellowAttributes)
        let emailInfoLabel = createLabel(with: selectedEmployee.contactDetails.email, attributes: smallBlackAttributes)
        
        var phoneTitleLabel: UILabel?
        var phoneInfoLabel: UILabel?
        if let phone = selectedEmployee.contactDetails.phone, !phone.isEmpty {
            phoneTitleLabel = createLabel(with: "PHONE NUMBER", attributes: boldYellowAttributes)
            phoneInfoLabel = createLabel(with: phone, attributes: smallBlackAttributes)
        }
        
        // Table view for projects
        projectsTableView.delegate = self
        projectsTableView.dataSource = self
        
        // Add subviews
        view.addSubview(nameLabel)
        view.addSubview(positionTitleLabel)
        view.addSubview(positionInfoLabel)
        view.addSubview(emailTitleLabel)
        view.addSubview(emailInfoLabel)
        if let phoneTitleLabel = phoneTitleLabel {
            view.addSubview(phoneTitleLabel)
        }
        if let phoneInfoLabel = phoneInfoLabel {
            view.addSubview(phoneInfoLabel)
        }
        view.addSubview(projectsTableView)
        
        // Layout constraints
        var constraints: [NSLayoutConstraint] = [
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            
            positionTitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            positionTitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            positionInfoLabel.topAnchor.constraint(equalTo: positionTitleLabel.bottomAnchor, constant: 4),
            positionInfoLabel.leadingAnchor.constraint(equalTo: positionTitleLabel.leadingAnchor),
            positionInfoLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20), // Limit trailing edge
            
            emailTitleLabel.topAnchor.constraint(equalTo: positionInfoLabel.bottomAnchor, constant: 20),
            emailTitleLabel.leadingAnchor.constraint(equalTo: positionTitleLabel.leadingAnchor),
            
            emailInfoLabel.topAnchor.constraint(equalTo: emailTitleLabel.bottomAnchor, constant: 4),
            emailInfoLabel.leadingAnchor.constraint(equalTo: emailTitleLabel.leadingAnchor),
            emailInfoLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20), // Limit trailing edge
        ]

        if let phoneTitleLabel = phoneTitleLabel {
            constraints.append(contentsOf: [
                phoneTitleLabel.topAnchor.constraint(equalTo: emailInfoLabel.bottomAnchor, constant: 20),
                phoneTitleLabel.leadingAnchor.constraint(equalTo: positionTitleLabel.leadingAnchor),
                
                phoneInfoLabel!.topAnchor.constraint(equalTo: phoneTitleLabel.bottomAnchor, constant: 4),
                phoneInfoLabel!.leadingAnchor.constraint(equalTo: positionTitleLabel.leadingAnchor),
                phoneInfoLabel!.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20) // Limit trailing edge
            ])
        }

        constraints.append(contentsOf: [
            projectsTableView.topAnchor.constraint(equalTo: (phoneTitleLabel != nil ? phoneInfoLabel!.bottomAnchor : emailInfoLabel.bottomAnchor), constant: 44), // Increase the padding here
            projectsTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            projectsTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            projectsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20), // Ensure projects table view doesn't exceed bottom
        ])

        NSLayoutConstraint.activate(constraints)
        
        // Display "PROJECTS" label if projects are available
        if let projects = selectedEmployee.projects, !projects.isEmpty {
            let projectsLabel = createLabel(with: "PROJECTS", attributes: boldYellowAttributes)
            view.addSubview(projectsLabel)
            
            NSLayoutConstraint.activate([
                projectsLabel.topAnchor.constraint(equalTo: projectsTableView.topAnchor, constant: -20),
                projectsLabel.leadingAnchor.constraint(equalTo: projectsTableView.leadingAnchor)
            ])
        }
    }
    
    private func createLabel(with text: String, attributes: [NSAttributedString.Key: Any]) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = NSAttributedString(string: text, attributes: attributes)
        label.numberOfLines = 0
        return label
    }
    
    private func createButton(title: String, action: Selector, isHidden: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.isHidden = isHidden
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}

extension ContactViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedEmployee.projects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "projectCell", for: indexPath)
        cell.textLabel?.text = selectedEmployee.projects?[indexPath.row]
        return cell
    }
}
