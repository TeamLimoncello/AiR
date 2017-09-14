//
//  AiRServer.swift
//  AiR
//
//  Created by Brendon Warwick on 13/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//
import Foundation

class Server {
    static let shared = Server()
    let domain = "https://air.xsanda.me/api/v1"
    
    func compatiableDate(_ date: Date!) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    /// Creates a flight on the server and returns a success flag and a payload, which will contain the flight id if successful or an error message otherwise.
 func CreateFlight(flightNumber: String!, flightTime: Date!, completion: @escaping (_ success: Bool, _ payload: String) -> Void){
        let endpoint = "/register"
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
                        completion(false, responseDict["string"] as! String)
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
    
    ///Fetch all of the associated data for a given flight
    func FetchData(id: String, completion: @escaping (_ data: Any?, _ error: String?) -> Void){
        let endpoint = "/fetch?id=\(id)"
        var request = URLRequest(url: URL(string: domain + endpoint)!)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                completion(nil, error!.localizedDescription)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse {
                switch httpStatus.statusCode {
                case 403:
                    completion(nil, "Error with flight ID.")
                case 503:
                    do {
                        let response = try JSONSerialization.jsonObject(with: data!) as! [String : Any]
                        let progress = response["progress"] as! Float
                        completion(nil, "Data is not ready yet. It is \(progress * 100)% completed")
                    } catch {
                        completion(nil, "Error whilst parsing JSON")
                    }
                case 200:
                    do {
                        let response = try JSONSerialization.jsonObject(with: data!) as! [String : Any]
                        completion(response, nil)
                    } catch {
                        completion(nil, "Error whilst parsing JSON")
                    }
                    completion(nil, nil)
                default:
                    completion(nil, "\(httpStatus.statusCode) error. ")
                }
            } else {
                completion(nil, "Error with HTTP Response")
            }
        }
    }
    
    ///Request that the data for a given flight is recalculated
    func RequestReload(id: String, completion: @escaping (_ success: Bool, _ error: String?) -> Void ){
        let endpoint = "/fetch?id=\(id)"
        var request = URLRequest(url: URL(string: domain + endpoint)!)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                completion(false, error!.localizedDescription)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse {
                switch httpStatus.statusCode {
                case 202:
                    completion(true, nil)
                case 403:
                    completion(false, "Bad request: id is not valid.")
                default:
                    completion(false, "Error \(httpStatus.statusCode)")
                }
            } else {
                completion(false, "Error whilst parsing HTTP Response")
            }
        }
    }
    
    ///Fetch rerequested data for a given flight
    func RefetchData(id: String, completion: @escaping (_ response: Any?, _ error: String?) -> Void){
        let endpoint = "/refetch?id=\(id)"
        var request = URLRequest(url: URL(string: domain + endpoint)!)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                completion(nil, error!.localizedDescription)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse {
                switch httpStatus.statusCode {
                case 403:
                    completion(nil, "Error with flight ID.")
                case 503:
                    do {
                        let response = try JSONSerialization.jsonObject(with: data!) as! [String : Any]
                        let progress = response["progress"] as! Float
                        completion(nil, "Data is not ready yet. It is \(progress * 100)% completed")
                    } catch {
                        completion(nil, "Error whilst parsing JSON")
                    }
                case 200:
                    do {
                        let response = try JSONSerialization.jsonObject(with: data!) as! [String : Any]
                        completion(response, nil)
                    } catch {
                        completion(nil, "Error whilst parsing JSON")
                    }
                    completion(nil, nil)
                default:
                    completion(nil, "\(httpStatus.statusCode) error. ")
                }
            } else {
                completion(nil, "Error with HTTP Response")
            }
        }
    }
}
