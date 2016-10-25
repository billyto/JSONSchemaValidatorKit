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

    case success
    case failure(String)

}

extension Data {
    
    func isValid(forSchema schema:SchemaValidator) -> validationResult{
        
        return schema.validateJSON(self)
    }
    
}

open class SchemaValidator {

    var schema: JSONSchema!
    
    public init(withSchema schema:Data) throws {
    
        do {
        
            self.schema = try JSONSerialization.jsonObject(with: schema, options: JSONSerialization.ReadingOptions()) as? JSONSchema
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
    open func isValidSchema() -> Bool {
    
        return true //TODO
    }
    
    
    
    open func validateJSON(_ data: Data ) -> validationResult {
        
        let validation : validationResult
        
        do {
            
            let JSONContent = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
            validation = validateJSON(JSONContent, withSchema: self.schema)
            
        } catch {
            validation =  .failure("serialization issue: \(error)")
        }
        
        return validation;
    }
    
    // entry point, decide what to validate
    open func validateJSON<T>(_ content: T, withSchema schema:JSONSchema) -> validationResult {
    
        var validation : validationResult = .success
    
        validation = validateInstance(content, withSchema: schema) //Apply to all type of instances
        
        switch validation {
        case .failure(_):
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
    
    
    func validateInstance<T>(_ jsonObject: T, withSchema schema:JSONSchema) -> validationResult{
    
        var validation : validationResult = .success
        
        validation = typeValidation(jsonObject, withSchema: schema)
        switch validation {
        case .failure(_):
            return validation
        default:
            break
        }
        
        validation = allOfValidation(jsonObject, withSchema: schema)
        switch validation {
        case .failure(_):
            return validation
        default:
            break
        }
        
        validation = anyOfValidation(jsonObject, withSchema: schema)
        switch validation {
        case .failure(_):
            return validation
        default:
            break
        }
        
        validation = oneOfValidation(jsonObject, withSchema: schema)
        switch validation {
        case .failure(_):
            return validation
        default:
            break
        }
        
        validation = notValidation(jsonObject, withSchema: schema)
        switch validation {
        case .failure(_):
            return validation
        default:
            break
        }
        
        return validation
    }

    //MARK: 5.4.  Validation keywords for objects
    func validateObject(_ jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult{
        
        
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
        case .failure(_):
            return minProperties
        default: break
        }
        
        let maxProperties = maxPropertiesValidation(jsonObject, withSchema:schema)
        switch maxProperties {
        case .failure(_):
            return maxProperties
        default: break
        }
        
        let required = requiredPropertiesValidation(jsonObject, withSchema:schema)
        switch required {
        case .failure(_):
            return required
        default: break
        }
        
        let propertiesPresence = propertiesPresenceValidation(jsonObject, withSchema:schema)
        switch propertiesPresence {
        case .failure(_):
            return propertiesPresence
        default: break
        }
        
        let propertiesDependecy = dependecyValidation(jsonObject, withSchema: schema)
        switch propertiesDependecy {
        case .failure(_):
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
                        case .failure(_):
                            return result
                        default: break
                        }
                    }
                }
            }
        }
        return .success
    }
    
    
   open func isValidStringConstrains(_ val: String, schema:JSONSchema ) -> validationResult{
        
        var validConstrains = true
    
        // Enum for Strings
        let validation = enumValidation(val, withSchema: schema)
        switch validation {
        case .failure(_):
            return validation
        default:
            break
        }
    
        //MARK: 5.2.1. maxLength
        if let maxLength = schema["maxLength"] as? Int {
            
            if maxLength > 0 { //5.2.1.1.  Valid values
                validConstrains = val.characters.count <= maxLength
                if !validConstrains {
                    return .failure("Max length \(maxLength) not passing to \(val).")
                }
            }
        }
        
        //MARK: 5.2.2.  minLength
        if let minLength = schema["minLength"] as? Int {
            
            if minLength > 0 { //5.2.2.1.  Valid values
                validConstrains = val.characters.count >= minLength
                if !validConstrains {
                    return .failure("Min length \(minLength) not passing to \(val).")
                }
            }
        }
        
        //MARK: 5.2.3.  pattern
        if let pattern = schema["pattern"] as? String {
            
            if val.range(of: pattern, options: .regularExpression) == nil {
                    return .failure("Pattern \(pattern) not passing to \(val).")
            }
            
        }
        
        return .success
    }
    
    
    func isValidNumberConstrains(_ val: Double, schema:JSONSchema ) -> validationResult{
        
        var validConstrains = true
        
        // Enum for Numbers
        let validation = enumValidation(val, withSchema: schema)
        switch validation {
        case .failure(_):
            return validation
        default:
            break
        }
        
        
        //MARK: 5.1.1.  multipleOf
        if let multipleOf = schema["multipleOf"] as? Double {
            
            if multipleOf > 0 { //5.1.1.1.  Valid values
                validConstrains = (val.truncatingRemainder(dividingBy: multipleOf)) == 0
                if !validConstrains {
                    return .failure("multipleOf \(multipleOf) not passing to \(val).")
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
                return .failure("maximum/exclusiveMaximum \(maximumConstraint) not passing to \(val).") //TODO: Separate maximum and maxExclusive
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
                return .failure("minimumConstraint/exclusiveMim \(minimumConstraint) not passing to \(val).") //TODO: Separate maximum and maxExclusive
            }
        }
        return .success
    }
    
    func isValidArrayConstrains(_ val: JSONArray, schema:JSONSchema ) -> validationResult{
        
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
                        return .failure("additionalItems \(additionalItems) not passing to \(items.count) vs. \(val.count)")
                    }
                    
                }
            }
            
        }
        
        //MARK: 5.3.2.  maxItems
        if let maxItems = schema["maxItems"] as? Int {
            
            if maxItems > 0 { //5.3.2.1.  Valid values
                let validConstrains = val.count <= maxItems
                if !validConstrains {
                    return .failure("maxItems \(maxItems) not passing to \(val.count)")
                }
            }
        }
        
        //MARK: 5.3.3.  minItems
        if let minItems = schema["minItems"] as? Int {
            
            if minItems > 0 { //5.3.3.1.  Valid values
                let validConstrains = val.count >= minItems
                if !validConstrains {
                    return .failure("minItems \(minItems) not passing to \(val.count)")
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
                        return .failure("uniqueItems \(uniqueItems) not passing to \(anies) vs \(uniques)")
                    }
                }
            }
        }
        
        return .success
    }

    //MARK: 5.4.1.  maxProperties
    func maxPropertiesValidation(_ jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult {
        
        if let maxProperties = schema["maxProperties"] as? Int {
            
            if maxProperties >= 0 { //5.4.1.1.  Valid values
                
                let propertiesCount = jsonObject.keys.count
                
                if  !(propertiesCount <= maxProperties) {
                    
                    return .failure("Number of properties \(propertiesCount) exceeds maxProperties \(maxProperties).")
                    
                }
            }
        }
        return .success
    }
    
    //MARK: 5.4.2.  minProperties
    func minPropertiesValidation(_ jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult {
        
        if let minProperties = schema["minProperties"] as? Int {
            
            if minProperties >= 0 { //5.4.2.1.  Valid values
                
                let propertiesCount = jsonObject.keys.count
                
                if  !(propertiesCount >= minProperties) {
                    
                    return .failure("Number of properties \(propertiesCount) is inferior to maxProperties \(minProperties).")
                    
                }
            }
        }
        return .success
    }
    
    //MARK: 5.4.3.  required
    func requiredPropertiesValidation(_ jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult {
        
        if let requiredProperties = schema["required"] as? Array<String> {
            
            let requiredPropertiesSet = Set(requiredProperties)
            let schemaPropertiesSet = Set(jsonObject.keys)
            
            let missingRequired = requiredPropertiesSet.subtracting(schemaPropertiesSet)
            
            if missingRequired.count > 0 {
                
                let missed = missingRequired.joined(separator: ", ")
                
                return .failure("missing \(missingRequired.count) element(s) [\(missed)] for required = [\(requiredProperties.joined(separator: ", "))].")
            }
        }
        
        return .success
        
    }
    
    //MARK: 5.4.4. additionalProperties, properties and patternProperties
    func propertiesPresenceValidation(_ jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult {
        
        
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
                                    
                                    $0.range(of: regex, options: .regularExpression) == nil
                                }
                            }
                            //                        print("\(sSansP.count) left for dead")
                        }
                    }
                    
                    if sSansP.count > 0 {
                        
                        return .failure("Invalid additional properties are present [\(sSansP.joined(separator: ", "))].")
                    }
                }
            } // additionalProperties = true will validate constraint
        }
        
        return .success
        
    }
    
    //MARK: 5.4.5. dependencies
    func dependecyValidation(_ jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult {
        
        
        if let dependencies = schema["dependencies"] as? JSONSchema {
            
            for (k,v) in dependencies {
                
                if let propertyDepencies = v as? Array<String> { //Property dependency
                    print (propertyDepencies)
                    let s = Set(jsonObject.keys)
                    let dependeciesSet = Set(propertyDepencies)
                    
                    if s.contains(k) && !dependeciesSet.isSubset(of: s)  {
                        
                        return .failure("Dependency \(k) not found")
                        
                    }
                } else if let schemaDependecy = v as? JSONSchema  {  // Schema dependency
                    
                    print("schema? \(schemaDependecy)")
                    
                    let s = Array(jsonObject.keys)
                    if s.contains(k) {
                        
                        
                        let validConstrains = validateJSON(jsonObject[k]!, withSchema: schemaDependecy)
                        switch validConstrains {
                        case .failure(_):
                            return validConstrains
                        default: break
                        }
                    }
                    
                }
            } // end for
        }
        return .success
    }
    
    
    //MARK: 5.5.1.  enum
    func enumValidation<T>(_ val: T, withSchema schema:JSONSchema) -> validationResult where T: Equatable {
    
        if let enumArray = schema["enum"] as? Array<T> {
        
            let index = enumArray.index {
                $0 == val
            }
            
            if index == nil {
                return .failure("\(val) not found in \(enumArray)")
            } else {
                return .success
            }
        
        } else {
            return .success
        }
    }
    
    
    
    
    //MARK: Combining schemas
    
    
    //Mark 5.5.2.  type
    func typeValidation<T>(_ jsonObject: T, withSchema schema:JSONSchema) -> validationResult {
    
        let validation: validationResult = .success
        
        if let rawSchemaType = schema["type"] as? String {
        
            if let schemaType = JSONDataType(rawValue: rawSchemaType) {
            
                switch schemaType {
                case .JSONString:
                    if !(jsonObject is String) {
                        return .failure("\(jsonObject) is not a \(rawSchemaType)")
                    }
                case .JSONInteger, .JSONNumber:
                    if !(jsonObject is Double) {
                        return .failure("\(jsonObject) is not a \(rawSchemaType)")
                    }
                case .JSONArray:
                    if !(jsonObject is JSONArray) {
                        return .failure("\(jsonObject) is not a \(rawSchemaType)")
                    }
                case .JSONBoolean:
                    if !(jsonObject is Bool) {
                        return .failure("\(jsonObject) is not a \(rawSchemaType)")
                    }
                case .JSONObject:
                    if !(jsonObject is JSONObject) {
                        return .failure("\(jsonObject) is not a \(rawSchemaType)")
                    }
                case .JSONNull:
                    if !(jsonObject is ExpressibleByNilLiteral) {
                        return .failure("\(jsonObject) is not a \(rawSchemaType)")
                    }
                }
            } else {
                return .failure("Type \(rawSchemaType) not recognized")
            }
        } else {
            return .failure("Type validation not found is schema \(schema)")

        }
        
        return validation
    }
    
    //MARK: 5.5.3.  allOf
    func allOfValidation<T>(_ jsonObject: T, withSchema schema:JSONSchema) -> validationResult {
    
        if let combinedSchemas = schema["allOf"] as? JSONArray {
        
            for schm in combinedSchemas {
                
                if let subSchema = schm as? JSONSchema {
                    
                    let result = validateJSON(jsonObject, withSchema: subSchema)
                    switch result {
                    case .success:
                        continue
                    case .failure(_):
                        return result
                    }
                }
            }
        }
        return .success
    }
    
    //MARK: 5.5.4.  anyOf
    func anyOfValidation<T>(_ jsonObject: T, withSchema schema:JSONSchema) -> validationResult {
        
        if let combinedSchemas = schema["anyOf"] as? JSONArray {
            
            for schm in combinedSchemas {
                
                if let subSchema = schm as? JSONSchema {
                    
                    let result = validateJSON(jsonObject, withSchema: subSchema)
                    switch result {
                    case .success:
                         return result
                    case .failure(_):
                        continue
                    }
                }
            }
            return .failure("\(jsonObject) not validated against any of \(schema)")
        }
        return .success
    }
    
    
    //MARK: 5.5.5.  oneOf
    func oneOfValidation<T>(_ jsonObject: T, withSchema schema:JSONSchema) -> validationResult {
        
        if let combinedSchemas = schema["oneOf"] as? JSONArray {
            
            var validSchemas = Array<validationResult>()
            
            for schm in combinedSchemas {
                
                if let subSchema = schm as? JSONSchema {
                    
                    let result = validateJSON(jsonObject, withSchema: subSchema)
                    switch result {
                    case .success:
                        validSchemas.append(result)
                    case .failure(_):
                        continue
                    }
                }
            }
            
            switch validSchemas.count {
            case 0:
                return .failure("\(jsonObject) not validated against any of \(schema)")
            case 1:
                return .success
            default:
                return .failure("\(jsonObject) validated against multiple of \(schema). Only one expected")
            }
        }
        return .success
    }
    
    
    //MARK: 5.5.6.  not
    func notValidation<T>(_ jsonObject: T, withSchema schema:JSONSchema) -> validationResult {
    
        if let notSchema = schema["not"] as? JSONSchema {
        
            let result = validateJSON(jsonObject, withSchema: notSchema)
            switch result {
            case .success :
                return .failure("\(jsonObject) is valid against the schema \(notSchema), it should not validate")
            case .failure(_):
                return .success
            }
        }
        return .success
        
    }

    
}

