//
//  ContactAPI.swift
//  WorkEditor
//
//  Created by liga.griezne on 09/04/2024.
//

import Foundation

struct APIManager {
    static func fetchTallinnEmployees(completion: @escaping (Result<[Employee], Error>) -> Void) {
        fetchEmployees(from: "https://tallinn-jobapp.aw.ee/employee_list/", completion: completion)
    }
    static func fetchTartuEmployees(completion: @escaping (Result<[Employee], Error>) -> Void) {
        fetchEmployees(from: "https://tartu-jobapp.aw.ee/employee_list/", completion: completion)
    }
    private static func fetchEmployees(from urlString: String, completion: @escaping (Result<[Employee], Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(.failure(error))
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
                completion(.failure(error))
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                let error = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP request failed"])
                completion(.failure(error))
                return
            }
            guard let data = data else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(.failure(error))
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedWrapper = try decoder.decode(EmployeesWrapper.self, from: data)
                completion(.success(decodedWrapper.employees))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
