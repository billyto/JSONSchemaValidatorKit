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
    
    override func setUp() {
        super.setUp()

        let testBundle = NSBundle(forClass: self.dynamicType)
        let schemaURL = testBundle.URLForResource("basic-schema", withExtension: "json")
        let jsonURL = testBundle.URLForResource("person", withExtension: "json")

        schema = NSData(contentsOfURL: schemaURL!)
        person = NSData(contentsOfURL: jsonURL!)
    
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testValidateGoodJSON() {
        XCTAssertNotNil(schema)
        XCTAssertNotNil(person)
        

        let validator  = SchemaValidator(withSchema: schema!)
        
        let result : validationResult = validator.validateJSON(person!)
        
        XCTAssertTrue(result.isValid)
        
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
