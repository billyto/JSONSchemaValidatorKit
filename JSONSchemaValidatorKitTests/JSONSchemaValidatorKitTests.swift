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
    
    var schema: Data?
    var person: Data?
    var badData: Data?
    
    override func setUp() {
        super.setUp()

        let testBundle = Bundle(for: type(of: self))
        let badDataURL = testBundle.url(forResource: "not-an-schema", withExtension: "txt")
        let schemaURL = testBundle.url(forResource: "basic-schema", withExtension: "json")
        let jsonURL = testBundle.url(forResource: "person", withExtension: "json")

        do {
            
            badData = try Data(contentsOf: badDataURL!)
            schema = try Data(contentsOf: schemaURL!)
            person = try Data(contentsOf: jsonURL!)
            
        } catch { }
    
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
    
        let tinySchema : [String:AnyObject] = ["title": "Tiniest schema" as AnyObject, "type": "object" as AnyObject]
        let validator = SchemaValidator(withSchema: tinySchema)
        XCTAssertNotNil(validator)
        
        
    }
    
    func isValid(result: validationResult) -> Bool {
    
        switch result {
        case .failure(_):
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
            XCTAssertFalse(isValid(result: result))
            
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
            XCTAssertTrue(isValid(result: result))
        }catch {
        
            XCTFail()
        }
        
        
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            do {
                let validator  = try SchemaValidator(withSchema: self.schema!)
                validator.validateJSON(self.person!)
            }catch{
            
            }
        }
    }
    
}
