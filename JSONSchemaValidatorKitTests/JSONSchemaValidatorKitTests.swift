//
//  JSONSchemaValidatorKitTests.swift
//  JSONSchemaValidatorKitTests
//
//  Created by Billy Tobon on 3/13/16.
//
//

import XCTest
@testable import JSONSchemaValidatorKit

class JSONSchemaValidatorKitTests: XCTestCase {
    
    var schema: NSData?
    var person: NSData?
    var badData: NSData?
    var schemaV4: NSData?
    
    override func setUp() {
        super.setUp()

        let testBundle = NSBundle(forClass: self.dynamicType)
        let badDataURL = testBundle.URLForResource("not-an-schema", withExtension: "txt")
        let schemaURL = testBundle.URLForResource("basic-schema", withExtension: "json")
        let jsonURL = testBundle.URLForResource("person", withExtension: "json")
        let schemaV4URL = testBundle.URLForResource("schema-v4", withExtension: "json")

        badData = NSData(contentsOfURL: badDataURL!)
        schema = NSData(contentsOfURL: schemaURL!)
        person = NSData(contentsOfURL: jsonURL!)
        schemaV4 = NSData(contentsOfURL: schemaV4URL!)
    
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testInvalidNSDATAforSchema() {
    
        XCTAssertThrowsError(try SchemaValidator(withSchema: badData!))
        
    
    }
    
    func testNSDataExtensionIsValid() {
    
        do {
            let validator  = try SchemaValidator(withSchema: schema!)
            let result = person!.isValid(forSchema: validator)
            XCTAssertNotNil(result)
        } catch{
            XCTFail()
        }
    }
    
    func testSchemaFromDictionary() {
    
        let tinySchema : [String:AnyObject] = ["title": "Tiniest schema", "type": "object"]
        let validator = SchemaValidator(withSchema: tinySchema)
        XCTAssertNotNil(validator)
        
        
    }
    
    func isValid(result: validationResult) -> Bool {
    
        switch result {
        case .Failure(_):
            return false
        default:
            return true
        }
    
    }
    
    func testValidateBadJSON()  {
        XCTAssertNotNil(schema)
        XCTAssertNotNil(badData)
        
        do {
            let validator  = try SchemaValidator(withSchema: schema!)
            
            let result : validationResult = validator.validateJSON(badData!)
            XCTAssertFalse(isValid(result))
            
        }catch {
            
            XCTFail()
        }
        
    
    }
    
    func testValidateGoodJSON() {
        XCTAssertNotNil(schema)
        XCTAssertNotNil(person)
        
        do {
            let validator  = try SchemaValidator(withSchema: schema!)
            let result : validationResult = validator.validateJSON(person!)
            XCTAssertTrue(isValid(result))
        }catch {
        
            XCTFail()
        }
        
        
    }
    
    func testValidateV4itself() {
        
        XCTAssertNotNil(schemaV4)

        
        do {
            
            let validator = try SchemaValidator(withSchema: schemaV4!)
            let result : validationResult = validator.validateJSON(schemaV4!)
            XCTAssertTrue(isValid(result))
            
        } catch {
          
            XCTFail()
            
        }
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
            do {
            
                let validator  = try SchemaValidator(withSchema: self.schema!)
                validator.validateJSON(self.person!)
            }catch{
            
            }
        }
    }
    
}
