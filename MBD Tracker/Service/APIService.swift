//
//  APIService.swift
//  MBD Tracker
//
//  Created by Soeng Saravit on 6/7/21.
//

import Foundation

class APIService {
    final let BASE_URL = "http://147.182.226.231:5000"
    
    func addHeartRate(heartRate:Int) {
        let req_url = self.BASE_URL + "/api/heart-rate"
        let data: [String:Any] = [
            "heart_rate": heartRate
        ]
        
        var urlRequest = URLRequest(url: URL(string: req_url)!)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        
        let urlSession = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let err = error {
                print("API Error: \(err.localizedDescription)")
            }else {
                if let jsonObject = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String:Any] {
                    print("API Info:", jsonObject["message"] as! String)
                }
            }
        }
        urlSession.resume()
    }
}
