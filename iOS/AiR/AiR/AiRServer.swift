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
    
    func compatiableDate(_ date: Date!) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    /// Creates a flight on the server and returns a success flag and a payload, which will contain the flight id if successful or an error message otherwise.
    func CreateFlight(flightNumber: String!, flightTime: Date!, completion: @escaping ((_ success: Bool?, _ payload: String?) -> ())){
        let endpoint = "/api/v1/register"
        var request = URLRequest(url: URL(string: "\(domain)\(endpoint)")!)
        request.httpMethod = "POST"
        let postString = "date=\(compatiableDate(flightTime))&flightNumber=\(flightNumber)"
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            do {
                guard error == nil else {
                    print("error=\(String(describing: error))")
                    completion(false, "Please check your connection and try again.")
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse {
                    guard httpStatus.statusCode == 200 else {
                        print("statusCode should be 200, but is \(httpStatus.statusCode)")
                        print("response = \(String(describing: response))")
                        let responseDict = try JSONSerialization.jsonObject(with: data!) as! [String:Any]
                        completion(false, responseDict["string"] as? String)
                        return
                    }
                }
                
                let responseString = String(data: data!, encoding: .utf8)
                print("responseString = \(String(describing: responseString))")
                completion(true, responseString!)
            } catch {
                completion(false, "Please check your connection and try again.")
            }
        }
        task.resume()
    }
}

let AiRServer = Server()
