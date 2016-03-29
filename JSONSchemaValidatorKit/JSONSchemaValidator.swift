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
        
            for (name, attributes) in properties {
            
                
                
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


typealias validation = Any -> Bool

struct Property {

    var name : String //necesarry?
    let description: String

    var functionValidations :Array<validators>
    
    
    enum validators {
        case typeValidation ( PropertyType -> Bool )
        case minValidation ( Int -> Bool )
        case exclusiveMinimumValidation ( Bool -> Bool )
    }
    
    enum PropertyType {
    
        case String
        case Integer
        case Array
    
    }
    
    init(WithName propertyName: String, attributes: [String:AnyObject]){
    
        name = propertyName
        functionValidations = Array<validators>()
        
        for (attributeName, constraint ) in attributes {
            
            switch(attributeName){
                case "type":
                 functionValidations.append(validators.typeValidation)
                
                
            }
            
        }
        
    }
    
    func type(propertyType: PropertyType) -> Bool{
        return true
    }
    
    func minimum(min: Int) -> Bool{
        return true
    }
    
    func exclusiveMinimum(shouldExclusiveMinimum: Bool) -> Bool{
        return true
    }

}

enum ValidatorType {
    case typeValidation // goes with string
    case minValidation // goes with int
    case exclusiveMinimumValidation // goes with bool
}

enum ConstraintType{

    case String
    case Integer
    case Array
    case Bool

}

struct validatorFactory {


    func createValidator(validation:ValidatorType, contraint: ConstraintType) -> (AnyObject) -> Bool{
    
    
        switch validation{
        case .typeValidation:  (makeTypeValidator(constraint))
        }
    
    
    }

    func makeTypeValidator(constraint: ConstraintType) -> (String) -> Bool {
    
        switch constraint{
            
            case 
            
        }
    
    }
    
    func validateType(property: AnyObject ) -> Bool{
        
        return true
    }
    

}
