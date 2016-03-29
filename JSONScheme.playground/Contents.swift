//: Playground - noun: a place where people can play

import Foundation

//Grab JSONDocument
let jsonPath = NSBundle.mainBundle().pathForResource("person", ofType: "json")
let jsonData = NSData(contentsOfFile: jsonPath!)
let jsonDocument = try NSJSONSerialization.JSONObjectWithData(jsonData!, options: .AllowFragments) as? [String: AnyObject]

//Grab JSONScheme
let jsonXPath = NSBundle.mainBundle().pathForResource("basic-schema", ofType: "json")
let jsonXData = NSData(contentsOfFile: jsonXPath!)
let jsonScheme = try NSJSONSerialization.JSONObjectWithData(jsonXData!, options: .AllowFragments) as? [String: AnyObject]



func validate(JSONObject: [String: AnyObject], scheme:[String: AnyObject]) -> Bool{

    print(JSONObject)
    
    //setup scheme
    let requiredkeys = scheme["required"] as! [String]
    let schemeProperties = scheme["Properties"] as! [String: AnyObject]
    
    
    
    //validate required
    let JSONObjectkeys = [String] (JSONObject.keys)
  
    
    //objectKeys - requiredKeys should = 0
    let setRequiredkeys = Set(requiredkeys)

    
    
    //validate key
    
    var isValidType = true // needs to be inside type validation
    
    for property in JSONObject{
    
        let propertyKey = property.0
        let propertyValue = property.1
        
        
        if schemeProperties.keys.contains(propertyKey){
        
            let validator = schemeProperties[propertyKey] as! [String: AnyObject]
            
            
            let propertyType = validator["type"] as! String
            switch propertyType {
            case "string":
                isValidType = propertyValue is String
            case "integer":
                isValidType = propertyValue is Int //Int? ot another int type?
            default:
                isValidType = false
            }
            
            //TODO: validate min
            
        }
    
    }
    
    //print what keys are not found
    return setRequiredkeys.subtract(JSONObjectkeys).isEmpty && isValidType
}

validate(jsonDocument!,  scheme: jsonScheme!)

