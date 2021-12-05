//
//  API.swift
//  SmoothWalker
//
//  Created by Mark Falcone on 11/30/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation


    
func apiCall(firstName:String, lastName: String, email:String, HealthData:[String:AnyHashable]){
        guard let url = URL(string: "https://magicmirrorhealth-developer-edition.na163.force.com/services/apexrest/postHealth?firstname=\(firstName)&lastname=\(lastName)&email=\(email)")else{
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String:AnyHashable] = HealthData//TODO ADD HEALTH DATA
    request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .fragmentsAllowed)
    
    let task = URLSession.shared.dataTask(with: request){data, _, error in
        guard let data = data, error == nil else {
            return
        }
        do{
            let responce = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            print("success")
        }catch{
            print(error)
        }
    }
    task.resume()
    }

        
