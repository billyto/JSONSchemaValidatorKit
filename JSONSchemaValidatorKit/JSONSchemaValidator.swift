//
//  JSONSchemaValidator.swift
//  JSONSchemaValidatorKit
//
//  Created by Billy Tobon on 3/13/16.
//
//

import Foundation

typealias Payload = [String: AnyObject]

public enum JSONDataType: String {
    
    case JSONArray      = "array"
    case JSONObject     = "object"
    case JSONString     = "string"
    case JSONInteger    = "integer"
    case JSONNumber     = "number"
    case JSONBool       = "bool"
    
}

public enum validationResult {

    case Success
    case Failure(String)

}

extension NSData {
    
    func isValid(forSchema schema:SchemaValidator) -> validationResult{
        
        return schema.validateJSON(self)
    }
    
}

public class SchemaValidator {

    var schema: Payload!
    
    public init(withSchema schema:NSData) throws {
    
        do {
        
            self.schema = try NSJSONSerialization.JSONObjectWithData(schema, options: NSJSONReadingOptions()) as? Payload
            //TODO: add optional validation against v4
            
        } catch {
            throw error
            
        }
    }
    
    public init(withSchema schema:[String: AnyObject]) {
    
        self.schema = schema
        //TODO: add optional validation against v4
    }
    

    //Validate scheme against v4 spec
    public func isValidSchema() -> Bool {
    
        return true //TODO
    }
    
    
    
    public func validateJSON(JSONObject: NSData ) -> validationResult {
        
        let validation : validationResult
        
        do {
            
            let JSONObject: Payload = try NSJSONSerialization.JSONObjectWithData(JSONObject, options: NSJSONReadingOptions()) as! Payload
            validation = validateJSON(JSONObject)
            
        } catch {
            validation =  .Failure("serialization issue: \(error)")
        }
        
        return validation;
    }
    
    
    public func validateJSON(JSONObject: [String: AnyObject] ) -> validationResult {
    
         return validate(JSONObject, withSchema: self.schema)
        
    
    }

        
    //private functions now:
    
    func validate(JSONObject: [String: AnyObject], withSchema schema:[String: AnyObject]) -> validationResult{
        
        //TODO: validate Type attribute constrain
        
        //TODO: same signature and response handling? maybe a map? using a funct type for xxxValidation
        let minProperties = minPropertiesValidation(JSONObject, withSchema:schema)
        
        switch minProperties {
        case .Failure(_):
            return minProperties
        default: break
        }
        
        
        let maxProperties = maxPropertiesValidation(JSONObject, withSchema:schema)
        switch maxProperties {
        case .Failure(_):
            return maxProperties
        default: break
        }
        
        let required = requiredPropertiesValidation(JSONObject, withSchema:schema)
        switch required {
        case .Failure(_):
            return required
        default: break
        }
        
        let propertiesPresence = propertiesPresenceValidation(JSONObject, withSchema:schema)
        switch propertiesPresence {
        case .Failure(_):
            return propertiesPresence
        default: break
        }
        
        let propertiesDependecy = dependecyValidation(JSONObject, withSchema: schema)
        switch propertiesDependecy {
        case .Failure(_):
            return propertiesDependecy
        default: break
        }
        
        if let schemaProperties = schema["properties"] as? [String: AnyObject] {
            
            for property in schemaProperties {
                
                let schemaPropertyKey = property.0
                
                if JSONObject[schemaPropertyKey] != nil { // TODO validate by type
                    
                    if JSONObject[schemaPropertyKey] is Array<AnyObject>{
                        print("Soy un array \(schemaPropertyKey)")
                        
                        if let subJSONArray = JSONObject[schemaPropertyKey] as? Array<AnyObject> {
                        
                            if let subSchemaPayload = property.1 as? [String: AnyObject] {
                                
                                let result = constraintsCompliance(subJSONArray, schema: subSchemaPayload)
                                switch result {
                                case .Failure(_):
                                    return result
                                default: break
                                }
                            }
                        }
                    }
                    
                    
                    if JSONObject[schemaPropertyKey] is [String:AnyObject]{
                        
                        print("Soy un objeto \(schemaPropertyKey)")
                        if let subJSONObject = JSONObject[schemaPropertyKey] as? [String:AnyObject]{

                            let result = validate(subJSONObject, withSchema: property.1 as! [String : AnyObject]  )
                            switch result {
                            case .Failure(_):
                                return result
                            default: break
                            }
                        }
                    }
                    
                    if JSONObject[schemaPropertyKey] is String{
                        if let subJSONString = JSONObject[schemaPropertyKey] as? String {
                            if let subSchemaPayload = property.1 as? [String: AnyObject] {
                                
                                let result = constraintsCompliance(subJSONString, schema: subSchemaPayload)
                                switch result {
                                case .Failure(_):
                                    return result
                                default: break
                                }
                            }
                        }
                    }
                    
                    if JSONObject[schemaPropertyKey] is Int{
                        print("Soy un numero \(schemaPropertyKey)")
                        if let subJSONInteger = JSONObject[schemaPropertyKey] as? Int {
                            if let subSchemaPayload = property.1 as? [String: AnyObject] {
                                
                                let result = constraintsCompliance(subJSONInteger, schema: subSchemaPayload)
                                switch result {
                                case .Failure(_):
                                    return result
                                default: break
                                }
                            }
                            
                        }
                    }
                    if JSONObject[schemaPropertyKey] is Bool{
                        print("Soy un Bool \(schemaPropertyKey)")
                    }
                    
                }
                
            }
            
        }
        
        return .Success
    }
    
    
    func isValidStringConstrains(val: AnyObject, schema:[String: AnyObject] ) -> validationResult{
        
        guard val is String else {
            return .Failure("Value \(val) is not a String.")
        }
        
        let stringVar = val as! String
        var validConstrains = true
        
        // 5.2.1 maxLength
        if let maxLength = schema["maxLength"] as? Int {
            
            if maxLength > 0 { //5.2.1.1.  Valid values
                validConstrains = stringVar.characters.count <= maxLength
                if !validConstrains {
                    return .Failure("Max length \(maxLength) not passing to \(stringVar).")
                }
            }
        }
        
        // 5.2.2.  minLength
        if let minLength = schema["minLength"] as? Int {
            
            if minLength > 0 { //5.2.2.1.  Valid values
                validConstrains = stringVar.characters.count >= minLength
                if !validConstrains {
                    return .Failure("Min length \(minLength) not passing to \(stringVar).")
                }
            }
        }
        
        //5.2.3.  pattern
        if let pattern = schema["pattern"] as? String {
            
            if stringVar.rangeOfString(pattern, options: .RegularExpressionSearch) == nil {
                    return .Failure("Pattern \(pattern) not passing to \(stringVar).")
            }
            
        }
        
        return .Success
    }
    
    
    func isValidIntegerConstrains(val: AnyObject, schema:[String: AnyObject] ) -> validationResult{
        
        guard val is Int else {
            
            return .Failure("Value \(val) is not a Integer.")
        }
        
        let intVar = val as! Int
        
        var validConstrains = true
        
        
        //5.1.1.  multipleOf
        if let multipleOf = schema["multipleOf"] as? Int {
            
            if multipleOf > 0 { //5.1.1.1.  Valid values
                validConstrains = (intVar %  multipleOf) == 0
                if !validConstrains {
                    return .Failure("multipleOf \(multipleOf) not passing to \(intVar).")
                }
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
            if !validConstrains {
                return .Failure("maximum/exclusiveMaximum \(maximumConstraint) not passing to \(intVar).") //TODO: Separate maximum and maxExclusive
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
            if !validConstrains {
                return .Failure("minimumConstraint/exclusiveMim \(minimumConstraint) not passing to \(intVar).") //TODO: Separate maximum and maxExclusive
            }
        }
        return .Success
    }
    
    func isValidArrayConstrains(val: AnyObject, schema:[String: AnyObject] ) -> validationResult{
        
        guard val is Array<AnyObject> else {
            
            return .Failure("Type not an array")
        }
        
        let arrayVar = val as! Array<AnyObject>
        
//        var validConstrains = true
        
        //5.3.1.  additionalItems and items
        if let additionalItems = schema["additionalItems"] as?  Bool {
            
            if !additionalItems {
                
                if let items = schema["items"] as? Array<AnyObject> {
                    let validConstrains = arrayVar.count <= items.count
                    if !validConstrains {
                        return .Failure("additionalItems \(additionalItems) not passing to \(items.count) vs. \(arrayVar.count)")
                    }
                    
                }
            }
            
        }
        
        //5.3.2.  maxItems
        if let maxItems = schema["maxItems"] as? Int {
            
            if maxItems > 0 { //5.3.2.1.  Valid values
                let validConstrains = arrayVar.count <= maxItems
                if !validConstrains {
                    return .Failure("maxItems \(maxItems) not passing to \(arrayVar.count)")
                }
            }
        }
        
        //5.3.3.  minItems
        if let minItems = schema["minItems"] as? Int {
            
            if minItems > 0 { //5.3.3.1.  Valid values
                let validConstrains = arrayVar.count >= minItems
                if !validConstrains {
                    return .Failure("minItems \(minItems) not passing to \(arrayVar.count)")
                }
            }
        }
        
        //5.3.4.  uniqueItems
        if let uniqueItems = schema["uniqueItems"] as? Bool {
            
            if uniqueItems {
                
                if let anies = arrayVar as? Array<String> {
                    
                    let uniques = Set(anies)
                    let validConstrains = arrayVar.count == uniques.count
                    if !validConstrains {
                        return .Failure("uniqueItems \(uniqueItems) not passing to \(anies) vs \(uniques)")
                    }
                }
            }
        }
        
        return .Success
    }
    
    
    func constraintsCompliance(value: AnyObject, schema: [String: AnyObject]) -> validationResult{
        
        var validConstrains : validationResult!
        
        guard let rawJSONtype = schema["type"] as? String else{
            
            return .Failure("Type attribute is mandatory]")
        }
        
        if let JSONType = JSONDataType(rawValue: rawJSONtype) {
        
            switch JSONType {
            case .JSONString:
                validConstrains = isValidStringConstrains(value, schema: schema)
            case .JSONInteger:
                validConstrains = isValidIntegerConstrains(value, schema: schema)
            case .JSONArray:
                validConstrains = isValidArrayConstrains(value, schema: schema)
            default:
                validConstrains = .Success
            }
        }
        return validConstrains
    }

    //5.4.1.  maxProperties
    func maxPropertiesValidation(JSONObject: [String: AnyObject], withSchema schema:[String: AnyObject]) -> validationResult {
        
        if let maxProperties = schema["maxProperties"] as? Int {
            
            if maxProperties >= 0 { //5.4.1.1.  Valid values
                
                let propertiesCount = JSONObject.keys.count
                
                if  !(propertiesCount <= maxProperties) {
                    
                    return .Failure("Number of properties \(propertiesCount) exceeds maxProperties \(maxProperties).")
                    
                }
            }
        }
        return .Success
    }
    
    //5.4.2.  minProperties
    func minPropertiesValidation(JSONObject: [String: AnyObject], withSchema schema:[String: AnyObject]) -> validationResult {
        
        if let minProperties = schema["minProperties"] as? Int {
            
            if minProperties >= 0 { //5.4.2.1.  Valid values
                
                let propertiesCount = JSONObject.keys.count
                
                if  !(propertiesCount >= minProperties) {
                    
                    return .Failure("Number of properties \(propertiesCount) is inferior to maxProperties \(minProperties).")
                    
                }
            }
        }
        return .Success
    }
    
    //5.4.3.  required
    func requiredPropertiesValidation(JSONObject: [String: AnyObject], withSchema schema:[String: AnyObject]) -> validationResult {
        
        if let requiredProperties = schema["required"] as? Array<String> {
            
            let requiredPropertiesSet = Set(requiredProperties)
            let schemaPropertiesSet = Set(JSONObject.keys)
            
            let missingRequired = requiredPropertiesSet.subtract(schemaPropertiesSet)
            
            if missingRequired.count > 0 {
                
                let missed = missingRequired.joinWithSeparator(", ")
                
                return .Failure("missing \(missingRequired.count) element(s) [\(missed)] for required = [\(requiredProperties.joinWithSeparator(", "))].")
            }
        }
        
        return .Success
        
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
                        
                        return .Failure("Invalid additional properties are present [\(sSansP.joinWithSeparator(", "))].")
                    }
                }
            } // additionalProperties = true will validate constraint
        }
        
        return .Success
        
    }
    
    //5.4.5. dependencies
    func dependecyValidation(JSONObject: [String: AnyObject], withSchema schema:[String: AnyObject]) -> validationResult {
        
        
        if let dependencies = schema["dependencies"] as? [String: AnyObject] {
            
            for (k,v) in dependencies {
                
                if let propertyDepencies = v as? Array<String> { //Property dependency
                    print (propertyDepencies)
                    let s = Set(JSONObject.keys)
                    let dependeciesSet = Set(propertyDepencies)
                    
                    if s.contains(k) && !dependeciesSet.isSubsetOf(s)  {
                        
                        return .Failure("Dependency \(k) not found")
                        
                    }
                } else if let schemaDependecy = v as? [String: AnyObject]  {  // Schema dependency
                    
                    print("schema? \(schemaDependecy)")
                    
                    let s = Array(JSONObject.keys)
                    if s.contains(k) {
                        
                        
                        let validConstrains = constraintsCompliance(JSONObject[k]!, schema: schemaDependecy)
                        switch validConstrains {
                        case .Failure(_):
                            return validConstrains
                        default: break
                        }
                    }
                    
                }
            } // end for
        }
        return .Success
    }
    
    //TODO: 5.5.  Validation keywords for any instance type
    
    
}

