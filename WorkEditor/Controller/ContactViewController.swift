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
        let boldFont = UIFont.boldSystemFont(ofSize: 17.0)
        let boldAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: boldFont]
        
        let fullName = NSMutableAttributedString(string: "\(selectedEmployee.fname) \(selectedEmployee.lname)")
        fullName.addAttributes(boldAttributes, range: NSRange(location: 0, length: selectedEmployee.fname.count))
        fullName.addAttributes(boldAttributes, range: NSRange(location: selectedEmployee.fname.count + 1, length: selectedEmployee.lname.count))

        let nameLabel = createLabel(with: fullName, titleText: "", highlightWords: nil)
        let positionLabel = createLabel(with: "Position:", titleText: "Position:", highlightWords: ["Position:"])
        let emailLabel = createLabel(with: "Email:", titleText: "Email:", highlightWords: ["Email:"])
        var phoneLabel: UILabel?
        if let phone = selectedEmployee.contactDetails.phone, !phone.isEmpty {
            phoneLabel = createLabel(with: "Phone Number:", titleText: "Phone Number:", highlightWords: ["Phone Number:"])
        }
        
        let positionInfoLabel = createLabel(with: selectedEmployee.position.rawValue, titleText: nil, highlightWords: nil)
        let emailInfoLabel = createLabel(with: selectedEmployee.contactDetails.email, titleText: nil, highlightWords: nil)
        var phoneInfoLabel: UILabel?
        if let phone = selectedEmployee.contactDetails.phone, !phone.isEmpty {
            phoneInfoLabel = createLabel(with: phone, titleText: nil, highlightWords: nil)
        }
        
        // Table view for projects
        projectsTableView.delegate = self
        projectsTableView.dataSource = self
        
        // Button for viewing contact
        let contactButton = createButton(title: "View Contact", action: #selector(viewContactDetails(_:)), isHidden: !selectedEmployee.hasMatchingContact)
        
        // Add subviews
        view.addSubview(nameLabel)
        view.addSubview(positionLabel)
        view.addSubview(positionInfoLabel)
        view.addSubview(emailLabel)
        view.addSubview(emailInfoLabel)
        if let phoneLabel = phoneLabel {
            view.addSubview(phoneLabel)
        }
        if let phoneInfoLabel = phoneInfoLabel {
            view.addSubview(phoneInfoLabel)
        }
        view.addSubview(projectsTableView)
        view.addSubview(contactButton)
        
        // Layout constraints
        var constraints: [NSLayoutConstraint] = [
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            
            positionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            positionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            positionInfoLabel.leadingAnchor.constraint(equalTo: positionLabel.trailingAnchor, constant: 8),
            positionInfoLabel.centerYAnchor.constraint(equalTo: positionLabel.centerYAnchor),
            
            emailLabel.topAnchor.constraint(equalTo: positionLabel.bottomAnchor, constant: 10),
            emailLabel.leadingAnchor.constraint(equalTo: positionLabel.leadingAnchor),
            
            emailInfoLabel.leadingAnchor.constraint(equalTo: emailLabel.trailingAnchor, constant: 8),
            emailInfoLabel.centerYAnchor.constraint(equalTo: emailLabel.centerYAnchor)
        ]

        if let phoneLabel = phoneLabel {
            constraints.append(contentsOf: [
                phoneLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 10),
                phoneLabel.leadingAnchor.constraint(equalTo: positionLabel.leadingAnchor),
                
                phoneInfoLabel!.leadingAnchor.constraint(equalTo: phoneLabel.trailingAnchor, constant: 8),
                phoneInfoLabel!.centerYAnchor.constraint(equalTo: phoneLabel.centerYAnchor)
            ])
        }

        constraints.append(contentsOf: [
            projectsTableView.topAnchor.constraint(equalTo: (phoneLabel != nil ? phoneLabel!.bottomAnchor : emailLabel.bottomAnchor), constant: 20),
            projectsTableView.leadingAnchor.constraint(equalTo: positionLabel.leadingAnchor),
            projectsTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            projectsTableView.heightAnchor.constraint(equalToConstant: 120), // Adjust height as needed
            
            contactButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contactButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        NSLayoutConstraint.activate(constraints)
        
        // Display "PROJECTS" label if projects are available
        if let projects = selectedEmployee.projects, !projects.isEmpty {
            let projectsLabel = UILabel()
            projectsLabel.translatesAutoresizingMaskIntoConstraints = false
            projectsLabel.text = "PROJECTS"
            projectsLabel.font = UIFont.systemFont(ofSize: 14.0) // Set the font size here
            projectsLabel.textColor = .systemYellow // Optionally, set the text color
            view.addSubview(projectsLabel)
            
            NSLayoutConstraint.activate([
                projectsLabel.topAnchor.constraint(equalTo: projectsTableView.topAnchor, constant: -20),
                projectsLabel.leadingAnchor.constraint(equalTo: projectsTableView.leadingAnchor)
            ])
        }
    }
    
    private func createLabel(with attributedText: NSAttributedString, titleText: String? = nil, highlightWords: [String]? = nil) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        
        // Set the label's attributed text
        if let titleText = titleText {
            let mutableAttributedString = NSMutableAttributedString(string: titleText)
            mutableAttributedString.append(attributedText)
            label.attributedText = mutableAttributedString
            if let highlightWords = highlightWords {
                let attributedString = NSMutableAttributedString(attributedString: mutableAttributedString)
                for word in highlightWords {
                    let range = (mutableAttributedString.string as NSString).range(of: word)
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.systemYellow, range: range)
                }
                label.attributedText = attributedString
            }
        } else {
            label.attributedText = attributedText
        }
        
        return label
    }
    
    private func createLabel(with text: String, titleText: String? = nil, highlightWords: [String]? = nil) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        
        // Set the label's text
        if let titleText = titleText {
            label.attributedText = NSAttributedString(string: titleText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            if let highlightWords = highlightWords {
                let attributedString = NSMutableAttributedString(string: text)
                for word in highlightWords {
                    let range = (text as NSString).range(of: word)
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.systemYellow, range: range)
                }
                label.attributedText = attributedString
            }
        } else {
            label.text = text
        }
        
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
    
    @objc func viewContactDetails(_ sender: UIButton) {
        // Your implementation for viewing contact details
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
