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
        
        if maxLength > 0 { //5.2.1.1.  Valid values
            validConstrains = stringVar.characters.count <= maxLength
        }
    }
    
    // 5.2.2.  minLength
    if let minLength = scheme["minLength"] as? Int {
    
        if minLength > 0 { //5.2.2.1.  Valid values
            validConstrains = stringVar.characters.count >= minLength
        }
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
    
    
    //5.1.1.  multipleOf
    if let multipleOf = scheme["multipleOf"] as? Int {
    
        if multipleOf > 0 { //5.1.1.1.  Valid values
            validConstrains = (intVar %  multipleOf) == 0
        }
    }
    
    
    //5.1.2.  maximum and exclusiveMaximum
    if let maximumConstraint = scheme["maximum"] as? Int {
        
        if let exclusiveMax = scheme["exclusiveMaximum"] as? Bool {
            
            if exclusiveMax {
                validConstrains = maximumConstraint > intVar
            }else {
                validConstrains = maximumConstraint >= intVar //TODO: code repeated
            }
            
        } else {
            
            validConstrains = maximumConstraint >= intVar
            
        }
    }
    
    
    
    //5.1.3. minimum and exclusiveMinimum
    if let minimumConstraint = scheme["minimum"] as? Int {
    
        if let exclusiveMin = scheme["exclusiveMinimum"] as? Bool {
        
            if exclusiveMin {
                 validConstrains = minimumConstraint < intVar
            }else {
                 validConstrains = minimumConstraint <= intVar //TODO: code repeated
            }
            
        } else {
            
           validConstrains = minimumConstraint <= intVar
        
        }
    }
    
    
    //more int constraints
    
    return validConstrains
}

func isValidArrayConstrains(val: AnyObject, scheme:[String: AnyObject] ) -> Bool{

    guard val is Array<AnyObject> else {
        
        return false
    }
    
    let arrayVar = val as! Array<AnyObject>
    
    var validConstrains = true
    
    //5.3.1.  additionalItems and items
    if let additionalItems = scheme["additionalItems"] as?  Bool {
    
        if !additionalItems {
        
            if let items = scheme["items"] as? Array<AnyObject> {
                validConstrains = arrayVar.count <= items.count
            } else{
                validConstrains = true
            }
            
        }else{
        
            validConstrains = true
        }
    
    }
    
    //5.3.2.  maxItems
    if let maxItems = scheme["maxItems"] as? Int {
        
        if maxItems > 0 { //5.3.2.1.  Valid values
            validConstrains = arrayVar.count <= maxItems
        }
    }
    
    //5.3.3.  minItems
    if let minItems = scheme["minItems"] as? Int {
        
        if minItems > 0 { //5.3.3.1.  Valid values
            validConstrains = arrayVar.count >= minItems
        }
    }
    
    //5.3.4.  uniqueItems
    if let uniqueItems = scheme["uniqueItems"] as? Bool {
    
        if uniqueItems {
            
            if let anies = arrayVar as? Array<String> { //TODO: is this safe? what for other objects?
                
                let uniques = Set(anies)
                validConstrains = arrayVar.count == uniques.count
            
            }
        }
    
    }
    
    
    return validConstrains
}

func isValidObjectConstrains(val: AnyObject, scheme:[String: AnyObject] ) -> Bool{

    guard val is [String: AnyObject] else {
        
        return false
    }
    
    let objectVar = val as! [String: AnyObject]
    
    var validConstrains = true

    
    //5.4.1.  maxProperties
    if let maxProperties = scheme["maxProperties"] as? Int {
        
        if maxProperties >= 0 { //5.4.1.1.  Valid values
            
            validConstrains =  objectVar.keys.count <= maxProperties
        }
    }
    
    //5.4.2.  minProperties
    if let minProperties = scheme["minProperties"] as? Int {
        
        if minProperties >= 0 { //5.4.2.1.  Valid values
            
            validConstrains =  objectVar.keys.count >= minProperties
        }
    }
    
    //5.4.3.  required
    if let requiredProperties = scheme["required"] as? Array<String> {
        
        if requiredProperties.count > 0 { //5.4.3.1.  Valid values
            
            let uniqueRequiredProperties = Array(Set(requiredProperties)) //TODO: ugly
            
            for required in uniqueRequiredProperties {
                
                if !objectVar.keys.contains(required){
                    validConstrains = false
                    break
                }
                
            }
        }
    }
    
    
    //5.4.4.  additionalProperties, properties and patternProperties
    
    if scheme["additionalProperties"] is Bool {
        
        if scheme["additionalProperties"] as! Bool == false {
        
            let s = Array(objectVar.keys)
            if let p = scheme["properties"] as? [String: AnyObject] {
            
                var sSansP = s.filter{ //take all the declared properties
                    !p.keys.contains($0)
                }
                print("filtering \(sSansP.count)")
            
                if sSansP.count > 0 { // still elements
                    
                    if let pp = scheme["patternProperties"] as? [String: AnyObject] {
                    
                        for ppk in pp.keys {
                            
                            sSansP = sSansP.filter {
                                
                                $0.rangeOfString(ppk, options: .RegularExpressionSearch) == nil
                            }
                        }
                        print("\(sSansP.count) left for dead")
                         validConstrains =  sSansP.count == 0 //validates if this is empty
                        
                    } else{
                        validConstrains = false //no patterns and still keys
                    }
                }
            }
        }
    }// if additionalProperties is a scheme, it succeeds
    
 
    //    5.4.5.  dependencies
    if let dependencies = scheme["dependencies"] as? [String: AnyObject] {
    
        for (k,v) in dependencies {
        
            if let dependeciesArray = v as? Array<String>{
                
                Set(dependeciesArray)
            }
            
            
            if let propertyDepencies = v as? Array<String> { //Property dependency
            print (propertyDepencies)
                let s = Set(objectVar.keys)
                let dependeciesSet = Set(propertyDepencies)
                
                if s.contains(k) && !dependeciesSet.isSubsetOf(s)  {
                    
                    validConstrains = false
                    break
                    
                }
            } else if let schemaDependecy = v as? [String: AnyObject]  {  // Schema dependency
                
                print("scheme? \(schemaDependecy)")
                
                let s = Array(objectVar.keys)
                if s.contains(k) {
                
                    
                
                    validConstrains = constraintsCompliance(objectVar, scheme: schemaDependecy)
                }
                
                
                
            }
        }
    
    
    }
    
    
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
    case "array":
        validConstrains = isValidArrayConstrains(value, scheme: scheme)
    case "object":
        validConstrains = isValidObjectConstrains(value, scheme: scheme)
    default:
        validConstrains = true
    }
    
    //TODO: false results might get cleared later down for a positive result
    return validConstrains

}

//isValidObjectConstrains and validate might be the same function
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





