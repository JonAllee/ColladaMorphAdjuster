//
//  ExtensionsTest.swift
//  ColladaMorphAdjuster
//
//  Created by Jonathan Allee on 3/6/17.
//  Copyright © 2017 Jonathan Allee. All rights reserved.
//

import XCTest

class ExtensionsTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testId() {
        let xml:String = "<Bar id=\"Foo\"></Bar>"
        let element = XMLElement.forTesting(xml)
        
        XCTAssertEqual(element.id, "Foo")
    }
    
    func testIdNil() {
        let xml:String = "<Bar></Bar>"
        let element = XMLElement.forTesting(xml)

        XCTAssertNil(element.id)
    }
    
    func testMorph() {
        let child = XMLElement.element(withName: "morph", children: nil, attributes: nil) as! XMLElement
        let element = XMLElement.element(withName: "Bar", children: [child], attributes: nil) as! XMLElement
    
        let morph:XMLElement? = element.morph
        XCTAssertEqual(morph, child)
    }
    
    func testMorphNil() {
        let xml:String = "<Bar><not_morph></not_morph></Bar>"
        let element = XMLElement.forTesting(xml)
        
        let morph:XMLElement? = element.morph
        XCTAssertNil(morph)
    }
    
    func testUrl() {
        let xml:String = "<Bar url=\"Foo\"></Bar>"
        let element = XMLElement.forTesting(xml)
        
        let url:String? = element.url
        XCTAssertEqual(url, "Foo")
    }
    
    func testUrlNil() {
        let xml:String = "<Bar not_url=\"Foo\"></Bar>"
        let element = XMLElement.forTesting(xml)

        let url:String? = element.url
        XCTAssertNil(url)
    }
    
    func testReplaceElement() {
        let grandchild = XMLElement.element(withName: "morph", children: nil, attributes: nil) as! XMLElement
        let child = XMLElement.element(withName: "child1", children: [grandchild], attributes: nil) as! XMLElement
        // <Parent><child1><morph></morph></child1></Parent>
        let element = XMLElement.element(withName: "Parent", children: [child], attributes: nil) as! XMLElement
        
        let attributes = [XMLNode.attribute(withName: "id", stringValue: "replacement") as! XMLNode]
        //<child2 id="replacement"></child2>
        let replacementChild = XMLElement.element(withName: "child2", children: nil, attributes: attributes) as! XMLElement
        
        child.replace(withNewNode: replacementChild)
    
        XCTAssertEqual(element.children?.first!, replacementChild, "Failed to replace node.")
        XCTAssertEqual(element.children?.first!.children?.first!, grandchild, "Failed to replace children.")
    }
    
    func testGetNodes() {
        let xml:String = "<root><parent><child><grandchild id=\"Foo\"></grandchild><grandchild id=\"NotFoo\"></grandchild></child></parent></root>"
        let element = XMLElement.forTesting(xml)
    
        let xPathQuery = "parent//grandchild[@id=\"Foo\"]"
        var nodes:[XMLNode]?
        do {
            nodes = try element.nodes(forXPath: xPathQuery)
        } catch { }
        
        XCTAssertNotNil(nodes)
        XCTAssertEqual(nodes?.count, 1)
        XCTAssertEqual(nodes?.first?.name, "grandchild")
        XCTAssertEqual((nodes?.first as? XMLElement)?.id, "Foo")
    }
}

extension XMLElement {
    class func forTesting(_ xmlString:String)->XMLElement {
        do {
            return try XMLElement(xmlString: xmlString)
        }
        catch {
            XCTFail("Failed to create xml for test")
        }
        return XMLElement()
    }
}

