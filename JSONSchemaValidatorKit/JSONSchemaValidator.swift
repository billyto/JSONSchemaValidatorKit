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
            validation = validateJSON(JSONContent)
            
        } catch {
            validation =  .Failure("serialization issue: \(error)")
        }
        
        return validation;
    }
    
    public func validateJSON(content: AnyObject) -> validationResult {
    
        var validation : validationResult = .Success

        if let jsonObject = content as? JSONObject {
            
            validation = validateJSON(jsonObject)
            
        } else if let jsonArray = content as? JSONArray {
            
            for jsonContent  in jsonArray {
                
                validation = validateJSON(jsonContent)
                
                switch validation {
                case .Failure(_):
                    return validation
                default:
                    continue
                }
            }
        }
        
        return validation
    
    }
    
    public func validateJSON(jsonObject: JSONObject ) -> validationResult {
    
         return validate(jsonObject, withSchema: self.schema)
        
    
    }

        
    //private functions :

    //MARK: Validation keywords for objects
    //also entry point for validations
    func validate(jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult{
        
        //TODO: validate Type attribute constrain
        
        //TODO: same signature and response handling? maybe a map? using a funct type for xxxValidation
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
                    
                    if jsonObject[schemaPropertyKey] is JSONArray {
                        print("Soy un array \(schemaPropertyKey)")
                        
                        if let subJSONArray = jsonObject[schemaPropertyKey] as? JSONArray {
                        
                            if let subSchemaPayload = property.1 as? JSONSchema {
                                
                                let result = constraintsCompliance(subJSONArray, schema: subSchemaPayload)
                                switch result {
                                case .Failure(_):
                                    return result
                                default: break
                                }
                            }
                        }
                    }
                    
                    
                    if jsonObject[schemaPropertyKey] is [String:AnyObject]{
                        
                        print("Soy un objeto \(schemaPropertyKey)")
                        if let subJSONObject = jsonObject[schemaPropertyKey] as? [String:AnyObject]{

                            let result = validate(subJSONObject, withSchema: property.1 as! JSONSchema  )
                            switch result {
                            case .Failure(_):
                                return result
                            default: break
                            }
                        }
                    }
                    
                    if jsonObject[schemaPropertyKey] is String{
                        if let subJSONString = jsonObject[schemaPropertyKey] as? String {
                            if let subSchemaPayload = property.1 as? JSONSchema {
                                
                                let result = constraintsCompliance(subJSONString, schema: subSchemaPayload)
                                switch result {
                                case .Failure(_):
                                    return result
                                default: break
                                }
                            }
                        }
                    }
                    
                    if jsonObject[schemaPropertyKey] is Int{
                        print("Soy un numero \(schemaPropertyKey)")
                        if let subJSONInteger = jsonObject[schemaPropertyKey] as? Int {
                            if let subSchemaPayload = property.1 as? JSONSchema {
                                
                                let result = constraintsCompliance(subJSONInteger, schema: subSchemaPayload)
                                switch result {
                                case .Failure(_):
                                    return result
                                default: break
                                }
                            }
                            
                        }
                    }
                    if jsonObject[schemaPropertyKey] is Bool{
                        print("Soy un Bool \(schemaPropertyKey)")
                    }
                    
                }
                
            }
            
        }
        
        return .Success
    }
    
    
    func isValidStringConstrains(val: String, schema:JSONSchema ) -> validationResult{
        
        var validConstrains = true
        
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
    
    func isValidArrayConstrains(val: AnyObject, schema:JSONSchema ) -> validationResult{
        
        guard val is Array<AnyObject> else {
            
            return .Failure("Type not an array")
        }
        
        let arrayVar = val as! Array<AnyObject>
        
        //MARK: 5.3.1.  additionalItems and items
        if let additionalItems = schema["additionalItems"] as?  Bool {
            
            if !additionalItems {
                
                if let items = schema["items"] as? JSONArray {
                    let validConstrains = arrayVar.count <= items.count
                    if !validConstrains {
                        return .Failure("additionalItems \(additionalItems) not passing to \(items.count) vs. \(arrayVar.count)")
                    }
                    
                }
            }
            
        }
        
        //MARK: 5.3.2.  maxItems
        if let maxItems = schema["maxItems"] as? Int {
            
            if maxItems > 0 { //5.3.2.1.  Valid values
                let validConstrains = arrayVar.count <= maxItems
                if !validConstrains {
                    return .Failure("maxItems \(maxItems) not passing to \(arrayVar.count)")
                }
            }
        }
        
        //MARK: 5.3.3.  minItems
        if let minItems = schema["minItems"] as? Int {
            
            if minItems > 0 { //5.3.3.1.  Valid values
                let validConstrains = arrayVar.count >= minItems
                if !validConstrains {
                    return .Failure("minItems \(minItems) not passing to \(arrayVar.count)")
                }
            }
        }
        
        //MARK: 5.3.4.  uniqueItems
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
    
    
    func constraintsCompliance(value: AnyObject, schema: JSONSchema) -> validationResult{
        
        var validConstrains : validationResult!
        
        guard let rawSchemaType = schema["type"] as? String else{
            
            return .Failure("Type attribute is mandatory")
        }
        
        if let schemaType = JSONDataType(rawValue: rawSchemaType) {

            switch schemaType {
            case .JSONString:
                if let stringValue = value as? String {
                    validConstrains = enumValidation(stringValue, withSchema: schema)
                    validConstrains = isValidStringConstrains(stringValue, schema: schema)
                } else {
                    return .Failure("\(value) is not a String")
                }
            case .JSONInteger, .JSONNumber:
                if let doubleValue = value as? Double {
                    
                    validConstrains = enumValidation(doubleValue, withSchema: schema)
                    validConstrains = isValidNumberConstrains(doubleValue, schema: schema)
                } else {
                    return .Failure("\(value) is not a Number")
                }
            case .JSONArray:
                    //TODO: enum validation?
                validConstrains = isValidArrayConstrains(value, schema: schema)
            case .JSONBoolean:
                if (value is Bool) {
                    return .Success
                }else{
                    return .Failure("\(value) is not a boolean")
                }
            default:
                validConstrains = .Success
            }
        
    
        }
        return validConstrains
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
                        
                        
                        let validConstrains = constraintsCompliance(jsonObject[k]!, schema: schemaDependecy)
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
    
    //TODO: Type can be a subschema
    
    //MARK: 5.5.3.  allOf
    func allOfValidation(jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult {
    
        if let combinedSchemas = schema["allOf"] as? JSONArray {
        
            for schm in combinedSchemas {
                
                if let subSchema = schm as? JSONSchema {
                    
                    let result = validate(jsonObject, withSchema: subSchema)
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
    func anyOfValidation(jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult {
        
        if let combinedSchemas = schema["anyOf"] as? JSONArray {
            
            for schm in combinedSchemas {
                
                if let subSchema = schm as? JSONSchema {
                    
                    let result = validate(jsonObject, withSchema: subSchema)
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
    func oneOfValidation(jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult {
        
        if let combinedSchemas = schema["oneOf"] as? JSONArray {
            
            var validSchemas = Array<validationResult>()
            
            for schm in combinedSchemas {
                
                if let subSchema = schm as? JSONSchema {
                    
                    let result = validate(jsonObject, withSchema: subSchema)
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
    func notValidation(jsonObject: JSONObject, withSchema schema:JSONSchema) -> validationResult {
    
        if let notSchema = schema["not"] as? JSONSchema {
        
            let result = validate(jsonObject, withSchema: notSchema)
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

