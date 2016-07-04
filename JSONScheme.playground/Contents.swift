//: JSONSchema : Playground to explore how to use JSONSchemaValidatorKit

import Foundation
import JSONSchemaValidatorKit

//Grab JSONDocument
let jsonPath = NSBundle.mainBundle().pathForResource("person", ofType: "json")
let jsonData = NSData(contentsOfFile: jsonPath!)
let jsonDocument = try NSJSONSerialization.JSONObjectWithData(jsonData!, options: .AllowFragments) as? [String: AnyObject]

//Grab JSONSchema
let jsonXPath = NSBundle.mainBundle().pathForResource("basic-schema", ofType: "json")
let jsonXData = NSData(contentsOfFile: jsonXPath!)
let jsonSchema = try NSJSONSerialization.JSONObjectWithData(jsonXData!, options: .AllowFragments) as? [String: AnyObject]


    
let validator : SchemaValidator?  = try SchemaValidator(withSchema: jsonSchema!)
let result = validator!.validateJSON(jsonDocument!)
print("do we have a valid json? \(result.isValid)")

    







