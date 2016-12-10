//
//  JSONSchemaValidator.swift
//  JSONSchemaValidatorKit
//
//  Created by Billy Tobon on 3/13/16.
//
//

import Foundation

public typealias JSONObject =  [String: AnyObject]
public typealias JSONSchema =  [String: AnyObject]
public typealias JSONArray  =  [AnyObject]

public enum JSONDataType: String {
    
    case JSONArray      = "array"
    case JSONObject     = "object"
    case JSONString     = "string"
    case JSONInteger    = "integer"
    case JSONNumber     = "number"
    case JSONBoolean    = "boolean"
    case JSONNull       = "null"
    
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

    var schema: JSONSchema!
    
    public init(withSchema schema:NSData) throws {
    
        do {
        
            self.schema = try NSJSONSerialization.JSONObjectWithData(schema, options: NSJSONReadingOptions()) as? JSONSchema
            //TODO: add optional validation against v4
            
        } catch {
            throw error
            
        }
    }
    
    public init(withSchema schema:JSONSchema) {
    
        self.schema = schema
        //TODO: add optional validation against v4
    }
    

    //Validate scheme against v4 spec
    public func isValidSchema() -> Bool {
    
        return true //TODO
    }
    
    
    
    public func validateJSON(data: NSData ) -> validationResult {
        
        let validation : validationResult
        
        do {
            
            let JSONContent = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
            validation = validateJSON(JSONContent, withSchema: self.schema)
            
        } catch {
            validation =  .Failure("serialization issue: \(error)")
        }
        
        return validation;
    }
    
    // entry point, decide what to validate
    public func validateJSON<T>(content: T, withSchema schema:JSONSchema) -> validationResult {
    
        var validation : validationResult = .Success
    
        validation = validateInstance(content, withSchema: schema) //Apply to all type of instances
        
        switch validation {
        case .Failure(_):
            return validation
        default:
            break
        }
        

        if let jsonObject = content as? JSONObject {
            
            validation = validateObject(jsonObject, withSchema: schema)
            
        } else if let jsonArray = content as? JSONArray {
            
            validation = isValidArrayConstrains(jsonArray, schema: schema)

        } else if let jsonString = content as? String {
        
            validation = isValidStringConstrains(jsonString, schema: schema)
        
        } else if let jsonNumber = content as? Double {
            
            validation = isValidNumberConstrains(jsonNumber, schema: schema)
        }
        
        return validation
    
    }
    
    
    func validateInstance<T>(jsonObject: T, withSchema schema:JSONSchema) -> validationResult{
    
        var validation : validationResult = .Success
        
        //TODO: check on $ref
        
        validation = typeValidation(jsonObject, withSchema: schema)
        switch validation {
        case .Failure(_):
            return validation
        default:
            break
        }
        
        validation = allOfValidation(jsonObject, withSchema: schema)
        switch validation {
        case .Failure(_):
            return validation
        default:
            break
        }
        
        validation = anyOfValidation(jsonObject, withSchema: schema)
        switch validation {
        case .Failure(_):
            return validation
        default:
            break
        }
        
        validation = oneOfValidation(jsonObject, withSchema: schema)
        switch validation {
        case .Failure(_):
            return validation
        default:
            break
        }
        
        validation = notValidation(jsonObject, withSchema: schema)
        switch validation {
        case .Failure(_):
            return validation
        default:
            break
        }
        
        return validation
    }

    //MARK: 5.4.  Validation keywords for objects
    func validateObject(jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult{
        
        
        // Enum for Object
        //TODO: Implement for Object
        //        let validation = enumValidation([???], withSchema: schema)
        //        switch validation {
        //        case .Failure(_):
        //            return validation
        //        default:
        //            break
        //        }
        
        
        let minProperties = minPropertiesValidation(jsonObject, withSchema:schema)
        switch minProperties {
        case .Failure(_):
            return minProperties
        default: break
        }
        
        let maxProperties = maxPropertiesValidation(jsonObject, withSchema:schema)
        switch maxProperties {
        case .Failure(_):
            return maxProperties
        default: break
        }
        
        let required = requiredPropertiesValidation(jsonObject, withSchema:schema)
        switch required {
        case .Failure(_):
            return required
        default: break
        }
        
        let propertiesPresence = propertiesPresenceValidation(jsonObject, withSchema:schema)
        switch propertiesPresence {
        case .Failure(_):
            return propertiesPresence
        default: break
        }
        
        let propertiesDependecy = dependecyValidation(jsonObject, withSchema: schema)
        switch propertiesDependecy {
        case .Failure(_):
            return propertiesDependecy
        default: break
        }
        
        if let schemaProperties = schema["properties"] as? JSONSchema {
            
            for property in schemaProperties {
                
                let schemaPropertyKey = property.0
                
                if jsonObject[schemaPropertyKey] != nil { // TODO validate by type
                    
                    if let subSchemaPayload = property.1 as? JSONSchema {
                    
                        let result = validateJSON(jsonObject[schemaPropertyKey], withSchema: subSchemaPayload)
                        switch result {
                        case .Failure(_):
                            return result
                        default: break
                        }
                    }
                }
            }
        }
        return .Success
    }
    
    
   public func isValidStringConstrains(val: String, schema:JSONSchema ) -> validationResult{
        
        var validConstrains = true
    
        // Enum for Strings
        let validation = enumValidation(val, withSchema: schema)
        switch validation {
        case .Failure(_):
            return validation
        default:
            break
        }
    
        //MARK: 5.2.1. maxLength
        if let maxLength = schema["maxLength"] as? Int {
            
            if maxLength > 0 { //5.2.1.1.  Valid values
                validConstrains = val.characters.count <= maxLength
                if !validConstrains {
                    return .Failure("Max length \(maxLength) not passing to \(val).")
                }
            }
        }
        
        //MARK: 5.2.2.  minLength
        if let minLength = schema["minLength"] as? Int {
            
            if minLength > 0 { //5.2.2.1.  Valid values
                validConstrains = val.characters.count >= minLength
                if !validConstrains {
                    return .Failure("Min length \(minLength) not passing to \(val).")
                }
            }
        }
        
        //MARK: 5.2.3.  pattern
        if let pattern = schema["pattern"] as? String {
            
            if val.rangeOfString(pattern, options: .RegularExpressionSearch) == nil {
                    return .Failure("Pattern \(pattern) not passing to \(val).")
            }
            
        }
        
        return .Success
    }
    
    
    func isValidNumberConstrains(val: Double, schema:JSONSchema ) -> validationResult{
        
        var validConstrains = true
        
        // Enum for Numbers
        let validation = enumValidation(val, withSchema: schema)
        switch validation {
        case .Failure(_):
            return validation
        default:
            break
        }
        
        
        //MARK: 5.1.1.  multipleOf
        if let multipleOf = schema["multipleOf"] as? Double {
            
            if multipleOf > 0 { //5.1.1.1.  Valid values
                validConstrains = (val %  multipleOf) == 0
                if !validConstrains {
                    return .Failure("multipleOf \(multipleOf) not passing to \(val).")
                }
            }
        }
        
        
        //MARK: 5.1.2.  maximum and exclusiveMaximum
        if let maximumConstraint = schema["maximum"] as? Double {
            
            if let exclusiveMax = schema["exclusiveMaximum"] as? Bool {
                
                if exclusiveMax {
                    validConstrains = maximumConstraint > val
                }else {
                    validConstrains = maximumConstraint >= val //TODO: code repeated
                }
                
            } else {
                
                validConstrains = maximumConstraint >= val
                
            }
            if !validConstrains {
                return .Failure("maximum/exclusiveMaximum \(maximumConstraint) not passing to \(val).") //TODO: Separate maximum and maxExclusive
            }
        }
        
        
        
        //MARK: 5.1.3. minimum and exclusiveMinimum
        if let minimumConstraint = schema["minimum"] as? Double {
            
            if let exclusiveMin = schema["exclusiveMinimum"] as? Bool {
                
                if exclusiveMin {
                    validConstrains = minimumConstraint < val
                }else {
                    validConstrains = minimumConstraint <= val //TODO: code repeated
                }
                
            } else {
                
                validConstrains = minimumConstraint <= val
                
            }
            if !validConstrains {
                return .Failure("minimumConstraint/exclusiveMim \(minimumConstraint) not passing to \(val).") //TODO: Separate maximum and maxExclusive
            }
        }
        return .Success
    }
    
    func isValidArrayConstrains(val: JSONArray, schema:JSONSchema ) -> validationResult{
        
        // Enum for Array
        //TODO: Implement for array
//        let validation = enumValidation([???], withSchema: schema)
//        switch validation {
//        case .Failure(_):
//            return validation
//        default:
//            break
//        }
        
        //MARK: 5.3.1.  additionalItems and items
        if let additionalItems = schema["additionalItems"] as?  Bool {
            
            if !additionalItems {
                
                if let items = schema["items"] as? JSONArray {
                    let validConstrains = val.count <= items.count
                    if !validConstrains {
                        return .Failure("additionalItems \(additionalItems) not passing to \(items.count) vs. \(val.count)")
                    }
                    
                }
            }
            
        }
        
        //MARK: 5.3.2.  maxItems
        if let maxItems = schema["maxItems"] as? Int {
            
            if maxItems > 0 { //5.3.2.1.  Valid values
                let validConstrains = val.count <= maxItems
                if !validConstrains {
                    return .Failure("maxItems \(maxItems) not passing to \(val.count)")
                }
            }
        }
        
        //MARK: 5.3.3.  minItems
        if let minItems = schema["minItems"] as? Int {
            
            if minItems > 0 { //5.3.3.1.  Valid values
                let validConstrains = val.count >= minItems
                if !validConstrains {
                    return .Failure("minItems \(minItems) not passing to \(val.count)")
                }
            }
        }
        
        //MARK: 5.3.4.  uniqueItems
        if let uniqueItems = schema["uniqueItems"] as? Bool {
            
            if uniqueItems {
                
                if let anies = val as? Array<String> {
                    
                    let uniques = Set(anies)
                    let validConstrains = val.count == uniques.count
                    if !validConstrains {
                        return .Failure("uniqueItems \(uniqueItems) not passing to \(anies) vs \(uniques)")
                    }
                }
            }
        }
        
        return .Success
    }

    //MARK: 5.4.1.  maxProperties
    func maxPropertiesValidation(jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult {
        
        if let maxProperties = schema["maxProperties"] as? Int {
            
            if maxProperties >= 0 { //5.4.1.1.  Valid values
                
                let propertiesCount = jsonObject.keys.count
                
                if  !(propertiesCount <= maxProperties) {
                    
                    return .Failure("Number of properties \(propertiesCount) exceeds maxProperties \(maxProperties).")
                    
                }
            }
        }
        return .Success
    }
    
    //MARK: 5.4.2.  minProperties
    func minPropertiesValidation(jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult {
        
        if let minProperties = schema["minProperties"] as? Int {
            
            if minProperties >= 0 { //5.4.2.1.  Valid values
                
                let propertiesCount = jsonObject.keys.count
                
                if  !(propertiesCount >= minProperties) {
                    
                    return .Failure("Number of properties \(propertiesCount) is inferior to maxProperties \(minProperties).")
                    
                }
            }
        }
        return .Success
    }
    
    //MARK: 5.4.3.  required
    func requiredPropertiesValidation(jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult {
        
        if let requiredProperties = schema["required"] as? Array<String> {
            
            let requiredPropertiesSet = Set(requiredProperties)
            let schemaPropertiesSet = Set(jsonObject.keys)
            
            let missingRequired = requiredPropertiesSet.subtract(schemaPropertiesSet)
            
            if missingRequired.count > 0 {
                
                let missed = missingRequired.joinWithSeparator(", ")
                
                return .Failure("missing \(missingRequired.count) element(s) [\(missed)] for required = [\(requiredProperties.joinWithSeparator(", "))].")
            }
        }
        
        return .Success
        
    }
    
    //MARK: 5.4.4. additionalProperties, properties and patternProperties
    func propertiesPresenceValidation(jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult {
        
        
        if  schema["additionalProperties"] is Bool {
            
            if schema["additionalProperties"] as! Bool == false {
                
                let s = Array(jsonObject.keys)
                if let p = schema["properties"] as? JSONSchema {
                    
                    var sSansP = s.filter{ //take all the declared properties
                        !p.keys.contains($0)
                    }
                    //                print("filtering \(sSansP.count)")
                    
                    if sSansP.count > 0 { // still elements
                        
                        if let pp = schema["patternProperties"] as? JSONSchema {
                            
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
    
    //MARK: 5.4.5. dependencies
    func dependecyValidation(jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult {
        
        
        if let dependencies = schema["dependencies"] as? JSONSchema {
            
            for (k,v) in dependencies {
                
                if let propertyDepencies = v as? Array<String> { //Property dependency
                    print (propertyDepencies)
                    let s = Set(jsonObject.keys)
                    let dependeciesSet = Set(propertyDepencies)
                    
                    if s.contains(k) && !dependeciesSet.isSubsetOf(s)  {
                        
                        return .Failure("Dependency \(k) not found")
                        
                    }
                } else if let schemaDependecy = v as? JSONSchema  {  // Schema dependency
                    
                    print("schema? \(schemaDependecy)")
                    
                    let s = Array(jsonObject.keys)
                    if s.contains(k) {
                        
                        
                        let validConstrains = validateJSON(jsonObject[k]!, withSchema: schemaDependecy)
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
    
    
    //MARK: 5.5.1.  enum
    func enumValidation<T where T: Equatable>(val: T, withSchema schema:JSONSchema) -> validationResult {
    
        if let enumArray = schema["enum"] as? Array<T> {
        
            let index = enumArray.indexOf {
                $0 == val
            }
            
            if index == nil {
                return .Failure("\(val) not found in \(enumArray)")
            } else {
                return .Success
            }
        
        } else {
            return .Success
        }
    }
    
    
    
    
    //MARK: Combining schemas
    
    
    //Mark 5.5.2.  type
    func typeValidation<T>(jsonObject: T, withSchema schema:JSONSchema) -> validationResult {
    
        let validation: validationResult = .Success
        
        if let rawSchemaType = schema["type"] as? String {
        
            if let schemaType = JSONDataType(rawValue: rawSchemaType) {
            
                switch schemaType {
                case .JSONString:
                    if !(jsonObject is String) {
                        return .Failure("\(jsonObject) is not a \(rawSchemaType)")
                    }
                case .JSONInteger, .JSONNumber:
                    if !(jsonObject is Double) {
                        return .Failure("\(jsonObject) is not a \(rawSchemaType)")
                    }
                case .JSONArray:
                    if !(jsonObject is JSONArray) {
                        return .Failure("\(jsonObject) is not a \(rawSchemaType)")
                    }
                case .JSONBoolean:
                    if !(jsonObject is Bool) {
                        return .Failure("\(jsonObject) is not a \(rawSchemaType)")
                    }
                case .JSONObject:
                    if !(jsonObject is JSONObject) {
                        return .Failure("\(jsonObject) is not a \(rawSchemaType)")
                    }
                case .JSONNull:
                    if !(jsonObject is NilLiteralConvertible) {
                        return .Failure("\(jsonObject) is not a \(rawSchemaType)")
                    }
                }
            } else {
                return .Failure("Type \(rawSchemaType) not recognized")
            }
        } else {
            return .Failure("Type validation not found in schema \(schema)")

        }
        
        return validation
    }
    
    //MARK: 5.5.3.  allOf
    func allOfValidation<T>(jsonObject: T, withSchema schema:JSONSchema) -> validationResult {
    
        if let combinedSchemas = schema["allOf"] as? JSONArray {
        
            for schm in combinedSchemas {
                
                if let subSchema = schm as? JSONSchema {
                    
                    let result = validateJSON(jsonObject, withSchema: subSchema)
                    switch result {
                    case .Success:
                        continue
                    case .Failure(_):
                        return result
                    }
                }
            }
        }
        return .Success
    }
    
    //MARK: 5.5.4.  anyOf
    func anyOfValidation<T>(jsonObject: T, withSchema schema:JSONSchema) -> validationResult {
        
        if let combinedSchemas = schema["anyOf"] as? JSONArray {
            
            for schm in combinedSchemas {
                
                if let subSchema = schm as? JSONSchema {
                    
                    let result = validateJSON(jsonObject, withSchema: subSchema)
                    switch result {
                    case .Success:
                         return result
                    case .Failure(_):
                        continue
                    }
                }
            }
            return .Failure("\(jsonObject) not validated against any of \(schema)")
        }
        return .Success
    }
    
    
    //MARK: 5.5.5.  oneOf
    func oneOfValidation<T>(jsonObject: T, withSchema schema:JSONSchema) -> validationResult {
        
        if let combinedSchemas = schema["oneOf"] as? JSONArray {
            
            var validSchemas = Array<validationResult>()
            
            for schm in combinedSchemas {
                
                if let subSchema = schm as? JSONSchema {
                    
                    let result = validateJSON(jsonObject, withSchema: subSchema)
                    switch result {
                    case .Success:
                        validSchemas.append(result)
                    case .Failure(_):
                        continue
                    }
                }
            }
            
            switch validSchemas.count {
            case 0:
                return .Failure("\(jsonObject) not validated against any of \(schema)")
            case 1:
                return .Success
            default:
                return .Failure("\(jsonObject) validated against multiple of \(schema). Only one expected")
            }
        }
        return .Success
    }
    
    
    //MARK: 5.5.6.  not
    func notValidation<T>(jsonObject: T, withSchema schema:JSONSchema) -> validationResult {
    
        if let notSchema = schema["not"] as? JSONSchema {
        
            let result = validateJSON(jsonObject, withSchema: notSchema)
            switch result {
            case .Success :
                return .Failure("\(jsonObject) is valid against the schema \(notSchema), it should not validate")
            case .Failure(_):
                return .Success
            }
        }
        return .Success
        
    }

    
}

