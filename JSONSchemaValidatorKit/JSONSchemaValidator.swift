//
//  JSONSchemaValidator.swift
//  JSONSchemaValidatorKit
//
//  Created by Billy Tobon on 3/13/16.
//
//

import Foundation

typealias Payload = [String: AnyObject] //need?


struct validationResult { //TODO: turn into enum?
    
    var isValid: Bool!
    var message: String?
    
}

extension NSData {
    
    func isValid(forSchema schema:SchemaValidator) -> validationResult{
        
        return schema.validateJSON(self)
    }
    
}

class SchemaValidator {

    var schema: Payload!
    
    init(withSchema schema:NSData) {
    
        do {
        
            self.schema = try NSJSONSerialization.JSONObjectWithData(schema, options: NSJSONReadingOptions()) as? Payload
            
        } catch {
            //TODO: throw this
            print(error)
            
        }
    }
    
    init(withSchema schema:[String: AnyObject]) {
    
        self.schema = schema
    
    }
    

    //Validate scheme against v4 spec
    func isValidSchema() -> Bool {
    
        return true //TODO
    }
    
    
    
    func validateJSON(JSONObject: NSData ) -> validationResult {
        
        let validation : validationResult
        
        do {
            
            if let JSONObject = try NSJSONSerialization.JSONObjectWithData(JSONObject, options: NSJSONReadingOptions()) as? Payload {
                validation = validateJSON(JSONObject)
            } else {
                validation = validationResult(isValid: false, message: "NSData is not a valid JSON payload")
            }
            
            
        } catch {
            //TODO: throw this
            print(error)
            validation = validationResult(isValid: false, message:"serialization issue: \(error)")
            
        }
        
        return validation;
    }
    
    
    func validateJSON(JSONObject: [String: AnyObject] ) -> validationResult {
    
         return validate(JSONObject, withSchema: self.schema)
        
    
    }

        
    //private functions now:
    
    func validate(JSONObject: [String: AnyObject], withSchema schema:[String: AnyObject]) -> validationResult{
        
        //TODO: validate Type attribute constrain
        
        let minProperties = minPropertiesValidation(JSONObject, withSchema:schema)
        if !minProperties.isValid {
            return minProperties
        }
        
        let maxProperties = maxPropertiesValidation(JSONObject, withSchema:schema)
        if !maxProperties.isValid {
            return maxProperties
        }
        
        let required = requiredPropertiesValidation(JSONObject, withSchema:schema)
        if !required.isValid {
            return required
        }
        
        let propertiesPresence = propertiesPresenceValidation(JSONObject, withSchema:schema)
        if !propertiesPresence.isValid {
            return propertiesPresence
        }
        
        
        if let schemaProperties = schema["properties"] as? [String: AnyObject] {
            
            for property in schemaProperties {
                
                let schemaPropertyKey = property.0
                
                if JSONObject[schemaPropertyKey] != nil { // TODO validate by type
                    
                    if JSONObject[schemaPropertyKey] is Array<AnyObject>{
                        print("Soy un array \(schemaPropertyKey)")
                    }
                    
                    
                    if JSONObject[schemaPropertyKey] is [String:AnyObject]{
                        
                        print("Soy un objeto \(schemaPropertyKey)")
                        if let subJSONObject = JSONObject[schemaPropertyKey] as? [String:AnyObject]{
                            print(property.1)
                            let result = validate(subJSONObject, withSchema: property.1 as! [String : AnyObject]  )
                            
                            if !result.isValid{
                                
                                return result
                            }
                            
                        }
                        
                        
                    }
                    if JSONObject[schemaPropertyKey] is Int{
                        print("Soy un numero \(schemaPropertyKey)")
                    }
                    if JSONObject[schemaPropertyKey] is Bool{
                        print("Soy un Bool \(schemaPropertyKey)")
                    }
                    
                }
                
            }
            
        }
        
        //TODO: validate for additional attributes and patterns
        //TODO: validate for dependecies schema and property dependency
        
        
        
        return validationResult(isValid: true, message: nil)
    }
    
    
    func isValidStringConstrains(val: AnyObject, schema:[String: AnyObject] ) -> Bool{
        
        guard val is String else {
            
            return false
        }
        
        let stringVar = val as! String
        var validConstrains = true
        
        // 5.2.1 maxLength
        if let maxLength = schema["maxLength"] as? Int {
            
            if maxLength > 0 { //5.2.1.1.  Valid values
                validConstrains = stringVar.characters.count <= maxLength
            }
        }
        
        // 5.2.2.  minLength
        if let minLength = schema["minLength"] as? Int {
            
            if minLength > 0 { //5.2.2.1.  Valid values
                validConstrains = stringVar.characters.count >= minLength
            }
        }
        
        //5.2.3.  pattern
        if let pattern = schema["pattern"] as? String {
            
            if stringVar.rangeOfString(pattern, options: .RegularExpressionSearch) == nil {
                
                validConstrains = false
            }
            
        }
        
        return validConstrains
    }
    
    
    func isValidIntegerConstrains(val: AnyObject, schema:[String: AnyObject] ) -> Bool{
        
        guard val is Int else {
            
            return false
        }
        
        let intVar = val as! Int
        
        var validConstrains = true
        
        
        //5.1.1.  multipleOf
        if let multipleOf = schema["multipleOf"] as? Int {
            
            if multipleOf > 0 { //5.1.1.1.  Valid values
                validConstrains = (intVar %  multipleOf) == 0
            }
        }
        
        
        //5.1.2.  maximum and exclusiveMaximum
        if let maximumConstraint = schema["maximum"] as? Int {
            
            if let exclusiveMax = schema["exclusiveMaximum"] as? Bool {
                
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
        if let minimumConstraint = schema["minimum"] as? Int {
            
            if let exclusiveMin = schema["exclusiveMinimum"] as? Bool {
                
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
    
    func isValidArrayConstrains(val: AnyObject, schema:[String: AnyObject] ) -> Bool{
        
        guard val is Array<AnyObject> else {
            
            return false
        }
        
        let arrayVar = val as! Array<AnyObject>
        
        var validConstrains = true
        
        //5.3.1.  additionalItems and items
        if let additionalItems = schema["additionalItems"] as?  Bool {
            
            if !additionalItems {
                
                if let items = schema["items"] as? Array<AnyObject> {
                    validConstrains = arrayVar.count <= items.count
                } else{
                    validConstrains = true
                }
                
            }else{
                
                validConstrains = true
            }
            
        }
        
        //5.3.2.  maxItems
        if let maxItems = schema["maxItems"] as? Int {
            
            if maxItems > 0 { //5.3.2.1.  Valid values
                validConstrains = arrayVar.count <= maxItems
            }
        }
        
        //5.3.3.  minItems
        if let minItems = schema["minItems"] as? Int {
            
            if minItems > 0 { //5.3.3.1.  Valid values
                validConstrains = arrayVar.count >= minItems
            }
        }
        
        //5.3.4.  uniqueItems
        if let uniqueItems = schema["uniqueItems"] as? Bool {
            
            if uniqueItems {
                
                if let anies = arrayVar as? Array<String> { //TODO: is this safe? what for other objects?
                    
                    let uniques = Set(anies)
                    validConstrains = arrayVar.count == uniques.count
                    
                }
            }
            
        }
        
        
        return validConstrains
    }
    
    
    func constraintsCompliance(value: AnyObject, schema: [String: AnyObject]) -> validationResult{
        
        var validConstrains = true
        
        guard let JSONtype = schema["type"] as? String else{
            
            return validationResult(isValid:validConstrains, message: "Type attribute is mandatory]") //should throw an exception?
        }
        
        switch JSONtype {
        case "string":
            validConstrains = isValidStringConstrains(value, schema: schema)
        case "integer":
            validConstrains = isValidIntegerConstrains(value, schema: schema)
        case "array":
            validConstrains = isValidArrayConstrains(value, schema: schema)
            //    case "object":  [TODO: verify not needed]
        //        validConstrains = isValidObjectConstrains(value, schema: schema)
        default:
            validConstrains = true
        }
        
        //TODO: false results might get cleared later down for a positive result
        return validationResult(isValid:validConstrains, message: "[TODO]")
        
    }

    //5.4.1.  maxProperties
    func maxPropertiesValidation(JSONObject: [String: AnyObject], withSchema schema:[String: AnyObject]) -> validationResult {
        
        if let maxProperties = schema["maxProperties"] as? Int {
            
            if maxProperties >= 0 { //5.4.1.1.  Valid values
                
                let propertiesCount = JSONObject.keys.count
                
                if  !(propertiesCount <= maxProperties) {
                    
                    return validationResult(isValid: false, message:"Number of properties \(propertiesCount) exceeds maxProperties \(maxProperties).")
                    
                }
            }
        }
        
        return validationResult(isValid: true, message:nil)
        
    }
    
    //5.4.2.  minProperties
    func minPropertiesValidation(JSONObject: [String: AnyObject], withSchema schema:[String: AnyObject]) -> validationResult {
        
        if let minProperties = schema["minProperties"] as? Int {
            
            if minProperties >= 0 { //5.4.2.1.  Valid values
                
                let propertiesCount = JSONObject.keys.count
                
                if  !(propertiesCount >= minProperties) {
                    
                    return validationResult(isValid: false, message:"Number of properties \(propertiesCount) is inferior to maxProperties \(minProperties).")
                    
                }
            }
        }
        
        return validationResult(isValid: true, message:nil)
        
    }
    
    //5.4.3.  required
    func requiredPropertiesValidation(JSONObject: [String: AnyObject], withSchema schema:[String: AnyObject]) -> validationResult {
        
        if let requiredProperties = schema["required"] as? Array<String> {
            
            let requiredPropertiesSet = Set(requiredProperties)
            let schemaPropertiesSet = Set(JSONObject.keys)
            
            let missingRequired = requiredPropertiesSet.subtract(schemaPropertiesSet)
            
            if missingRequired.count > 0 {
                
                let missed = missingRequired.joinWithSeparator(", ")
                
                return validationResult(isValid: false, message: "missing \(missingRequired.count) element(s) [\(missed)] for required = [\(requiredProperties.joinWithSeparator(", "))].")
            }
        }
        
        return validationResult(isValid: true, message:nil)
        
    }
    
    //5.4.4. additionalProperties, properties and patternProperties
    func propertiesPresenceValidation(JSONObject: [String: AnyObject], withSchema schema:[String: AnyObject]) -> validationResult {
        
        
        if  schema["additionalProperties"] is Bool {
            
            if schema["additionalProperties"] as! Bool == false {
                
                let s = Array(JSONObject.keys)
                if let p = schema["properties"] as? [String: AnyObject] {
                    
                    var sSansP = s.filter{ //take all the declared properties
                        !p.keys.contains($0)
                    }
                    //                print("filtering \(sSansP.count)")
                    
                    if sSansP.count > 0 { // still elements
                        
                        if let pp = schema["patternProperties"] as? [String: AnyObject]  {
                            
                            for regex in pp.keys {
                                
                                sSansP = sSansP.filter {
                                    
                                    $0.rangeOfString(regex, options: .RegularExpressionSearch) == nil
                                }
                            }
                            //                        print("\(sSansP.count) left for dead")
                        }
                    }
                    
                    if sSansP.count > 0 {
                        
                        return validationResult(isValid: false, message:"Invalid additional properties are present [\(sSansP.joinWithSeparator(", "))].")
                    }
                    
                    
                }
            } // additionalProperties = true will validate constraint
        }
        
        return validationResult(isValid: true, message:nil)
        
    }
    
    //5.4.5. dependencies
    func dependecyValidation(JSONObject: [String: AnyObject], withSchema schema:[String: AnyObject]) -> validationResult {
        
        
        if let dependencies = schema["dependencies"] as? [String: AnyObject] {
            
            for (k,v) in dependencies {
                
//                    if let dependeciesArray = v as? Array<String>{ //TODO: Necessary?
//                        
//                        Set(dependeciesArray)
//                    }
                
                
                if let propertyDepencies = v as? Array<String> { //Property dependency
                    print (propertyDepencies)
                    let s = Set(JSONObject.keys)
                    let dependeciesSet = Set(propertyDepencies)
                    
                    if s.contains(k) && !dependeciesSet.isSubsetOf(s)  {
                        
                        return validationResult(isValid: false, message:"Dependency \(k) not found")
                        
                    }
                } else if let schemaDependecy = v as? [String: AnyObject]  {  // Schema dependency
                    
                    print("schema? \(schemaDependecy)")
                    
                    let s = Array(JSONObject.keys)
                    if s.contains(k) {
                        
                        
                        let validConstrains = constraintsCompliance(JSONObject, schema: schemaDependecy)
                        if !validConstrains.isValid {
                            
                            return validConstrains
                            
                        }
                    }
                    
                }
            } // end for
        }
        return validationResult(isValid: true, message: nil)
        
    }
}

