//
//  AiRServer.swift
//  AiR
//
//  Created by Brendon Warwick on 13/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation

class Server {
    
    let domain = "https://air.xsanda.me/"
    
    func compatiableDate(_ date: Date!) -> String{
        return "YYYY-MM-DD"
    }
    
    func CreateFlight(flightNumber: String!, flightTime: Date!, completion: @escaping (_ success: Bool?) -> ()){
        let endpoint = "/api/v1/register"
        var request = URLRequest(url: URL(string: "\(domain)\(endpoint)")!)
        request.httpMethod = "POST"
        let postString = "date=\(compatiableDate(flightTime))&flightNumber=\(flightNumber)"
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("error=\(String(describing: error))")
                completion(false)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
                completion(false)
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
            completion(true)
        }
        task.resume()
    }
}

let AiRServer = Server()
