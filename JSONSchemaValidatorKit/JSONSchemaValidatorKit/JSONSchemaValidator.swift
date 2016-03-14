//
//  JSONSchemaValidator.swift
//  JSONSchemaValidatorKit
//
//  Created by Billy Tobon on 3/13/16.
//
//

import Foundation


extension NSData {
    
    func isValid(forScheme scheme:NSData) -> Bool{
        
        let validator = Validator(fromScheme: scheme)
        
        return false
        
    }
    
}

typealias Payload = [String: AnyObject]

struct Validator {

    var jsonScheme: Payload!
    var schemeProperties = [String: Property]()
    
    init(fromScheme scheme:NSData) {
    
        do {
        
            jsonScheme = try NSJSONSerialization.JSONObjectWithData(scheme, options: NSJSONReadingOptions()) as? Payload
            
        } catch {
            //TODO: throw this
            print(error)
            
        }

    //TODO: Validate scheme with the v4 scheme!
        
        if let properties = jsonScheme["properties"] as? [String:AnyObject] {
        
            for (name, property) in properties {
            
                if let type = property["type"] as? String,
                    let  description = property["description"] as? String,
                    let min = property["minimum"] as? Int { //TODO: non-mandatory
                
                        let sp = Property(name: name, type:type , description: description, minimum: min)
                
                        schemeProperties[name] = sp
                        
                }
                
                
            
            }
        }
        
    //object or array
    //each properties and make rules for each
    //make required rule
    
    }


}

struct Property {

    var name : String? //necesarry?
    let type : String //enum
    let description: String
    let minimum: Int  //only for certain

}