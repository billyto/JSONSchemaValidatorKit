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

//likely not needed
enum JSONDataType: String {
    
    case JSONArray = "array"
    case JSONObject = "object"
    case JSONString = "string"
    case JSONInteger = "integer"
    case JSONNumber = "number"
    case JSONBool = "bool"
    
}

func isValidStringConstrains(val: AnyObject, scheme:[String: AnyObject] ) -> Bool{

    guard val is String else {
        
        return false
    }
    
    let stringVar = val as! String
    var validConstrains = true
    
    // 5.2.1 maxLength
    if let maxLength = scheme["maxLength"] as? Int {
        
        validConstrains = stringVar.characters.count <= maxLength
        
    }
    
    // 5.2.2.  minLength
    if let minLength = scheme["minLength"] as? Int {
    
        validConstrains = stringVar.characters.count >= minLength
        
    }
    
    //5.2.3.  pattern
    if let pattern = scheme["pattern"] as? String {
    
        if stringVar.rangeOfString(pattern, options: .RegularExpressionSearch) == nil {
            
            validConstrains = false
        }
        
    }
    
    return validConstrains
}


func isValidIntegerConstrains(val: AnyObject, scheme:[String: AnyObject] ) -> Bool{

    guard val is Int else {
    
        return false
    }
    
    let intVar = val as! Int
    
    var validConstrains = true
    
    if let minimumConstraint = scheme["minimum"] as? Int {
    
        validConstrains = minimumConstraint <= intVar
    }
    
    //more int constraints
    
    return validConstrains
}

func constraintsCompliance(value: AnyObject, scheme: [String: AnyObject]) -> Bool{

    var validConstrains = true
    
    guard let JSONtype = scheme["type"] as? String else{
    
        return false //they should throw an exception?
    }
    
    switch JSONtype {
    case "string":
        validConstrains = isValidStringConstrains(value, scheme: scheme)
    case "integer":
            validConstrains = isValidIntegerConstrains(value, scheme: scheme)
    default:
        validConstrains = true
    }
    
    
    return validConstrains

}

func validate(JSONObject: [String: AnyObject], scheme:[String: AnyObject]) -> Bool{

    print(JSONObject)
    
    //setup scheme
    let requiredkeys = scheme["required"] as! [String]
    let schemeProperties = scheme["properties"] as! [String: AnyObject]
    
    
    //validate required
    let JSONObjectkeys = [String] (JSONObject.keys)
  
    
    //objectKeys - requiredKeys should = 0
    let setRequiredkeys = Set(requiredkeys)

    
    //validate key
    var isValidConstrains = true
    
    for property in JSONObject{
    
        let propertyKey = property.0
        let propertyValue = property.1
        
        
        if schemeProperties.keys.contains(propertyKey){
        
            let validator = schemeProperties[propertyKey] as! [String: AnyObject]
            isValidConstrains = constraintsCompliance(propertyValue, scheme: validator)
            
            if !isValidConstrains {
                break
            }
        }
    
    }
    
    //print what keys are not found
    return setRequiredkeys.subtract(JSONObjectkeys).isEmpty && isValidConstrains
}

let isValid = validate(jsonDocument!, scheme:jsonScheme!)

print("Do we have a valid json? \(isValid)")





