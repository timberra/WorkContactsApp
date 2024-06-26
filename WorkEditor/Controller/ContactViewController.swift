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
        configureNavigationBar()
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
        projectsTableView.delegate = self
        projectsTableView.dataSource = self
        view.addSubview(nameLabel)
        view.addSubview(positionTitleLabel)
        view.addSubview(positionInfoLabel)
        view.addSubview(emailTitleLabel)
        view.addSubview(emailInfoLabel)
        phoneTitleLabel.map { view.addSubview($0) }
        phoneInfoLabel.map { view.addSubview($0) }
        view.addSubview(projectsTableView)
        //MARK: -Layout constraints
        var constraints: [NSLayoutConstraint] = [
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            positionTitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            positionTitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            positionInfoLabel.topAnchor.constraint(equalTo: positionTitleLabel.bottomAnchor, constant: 4),
            positionInfoLabel.leadingAnchor.constraint(equalTo: positionTitleLabel.leadingAnchor),
            positionInfoLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            emailTitleLabel.topAnchor.constraint(equalTo: positionInfoLabel.bottomAnchor, constant: 20),
            emailTitleLabel.leadingAnchor.constraint(equalTo: positionTitleLabel.leadingAnchor),
            emailInfoLabel.topAnchor.constraint(equalTo: emailTitleLabel.bottomAnchor, constant: 4),
            emailInfoLabel.leadingAnchor.constraint(equalTo: emailTitleLabel.leadingAnchor),
            emailInfoLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ]
        if let phoneTitleLabel = phoneTitleLabel, let phoneInfoLabel = phoneInfoLabel {
            constraints.append(contentsOf: [
                phoneTitleLabel.topAnchor.constraint(equalTo: emailInfoLabel.bottomAnchor, constant: 20),
                phoneTitleLabel.leadingAnchor.constraint(equalTo: positionTitleLabel.leadingAnchor),
                phoneInfoLabel.topAnchor.constraint(equalTo: phoneTitleLabel.bottomAnchor, constant: 4),
                phoneInfoLabel.leadingAnchor.constraint(equalTo: positionTitleLabel.leadingAnchor),
                phoneInfoLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
            ])
        }
        constraints.append(contentsOf: [
            projectsTableView.topAnchor.constraint(equalTo: (phoneInfoLabel?.bottomAnchor ?? emailInfoLabel.bottomAnchor), constant: 44),
            projectsTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            projectsTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            projectsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
        NSLayoutConstraint.activate(constraints)
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
    //MARK: - NavBar contact button
    private func configureNavigationBar() {
        let store = CNContactStore()
        let predicate = CNContact.predicateForContacts(matchingName: "\(selectedEmployee.fname) \(selectedEmployee.lname)")
        let keys = [CNContactViewController.descriptorForRequiredKeys()] as [CNKeyDescriptor]
        do {
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
            if let _ = contacts.first { // Check if the contact exists
                let button = UIButton(type: .system)
                button.setImage(UIImage(systemName: "person.crop.circle"), for: .normal)
                button.addTarget(self, action: #selector(viewContact), for: .touchUpInside)
                button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
                let barButton = UIBarButtonItem(customView: button)
                navigationItem.rightBarButtonItem = barButton
            }
        } catch {
            print("Error fetching contact: \(error)")
        }
    }
    @objc private func viewContact() {
        let store = CNContactStore()
        let predicate = CNContact.predicateForContacts(matchingName: "\(selectedEmployee.fname) \(selectedEmployee.lname)")
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
//MARK: - Data Source/View Delegate
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
