//
//  ColladaMorphAdjusterTests.swift
//  ColladaMorphAdjuster
//
//  Created by Jonathan Allee on 3/3/17.
//  Copyright © 2017 Jonathan Allee. All rights reserved.
//

import XCTest

// Linking directly, we're building an executable, not an app bundle.
//@testable import ColladaMorphAdjuster

class ColladaMorphAdjusterTests: XCTestCase {
    var parser:ColladaMorphAdjuster!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let bundle = Bundle(for: type(of: self))
        let inputPath = bundle.path(forResource: "ColladaTest", ofType: "dae")!
        let outputPath = "unused.dae"
        
        parser = ColladaMorphAdjuster(inputFile:inputPath, outputFile: outputPath)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateDocument() {
        XCTAssertNotNil(parser.xmlDoc)
    }
    
    func testcreateURLForController() {
        let xml:String = "<controller id=\"GiveMeAHashTag\"></controller>"
        let element = XMLElement.forTesting(xml)
        
        XCTAssertEqual(parser.createURLForController(element), "#GiveMeAHashTag")
    }
    
    func testIdFromFragment() {
        XCTAssertEqual(parser.id(fromFragment: "#Foo"), "Foo")
    }
    
    func testInstanceController() {
        let xml:String = "<controller id=\"the_id\"></controller>"
        let element = XMLElement.forTesting(xml)
        
        let instanceController = parser.instanceController(forLibraryController: element)
        
        //<instance_controller name="the_id" url="#the_id"></instance_controller>
        XCTAssertEqual(instanceController?.name, "instance_controller")
        XCTAssertEqual(instanceController?.attribute(forLocalName: "name", uri: nil)?.objectValue as? String, "the_id")
        XCTAssertEqual(instanceController?.url,"#the_id")
    }
    
    func testMorpherForInstanceGeometry() {
        let xml = "<instance_geometry url=\"#CubeWithMorpher2-mesh\"></instance_geometry>"
        let element = XMLElement.forTesting(xml)
        
        let libraryController = parser.morpher(forInstanceGeometry: element)
        
        XCTAssertNotNil(libraryController)
        XCTAssertEqual(libraryController?.name, "controller")
        XCTAssertEqual(libraryController?.children?.first?.name, "morph")
        XCTAssertEqual((libraryController?.children?.first as! XMLElement).attribute(forLocalName: "source", uri: nil)?.objectValue as? String, "#CubeWithMorpher2-mesh")
    }
    
    func testFindNodesToFix() {
        XCTAssertEqual(parser.findNodesToFix().count, 4)
    }
    
    func testGetAuthoringTool() {
        let authoringTool = parser.getAuthoringTool() ?? ""
        XCTAssert(authoringTool.hasPrefix("Blender"))
    }
    
    func testGetGeometryNodes() {
        let nodes = parser.getGeometryNodes()
        XCTAssertEqual(nodes.count, 10)
    }
    
    func testGeometryIds() {
        XCTAssertEqual(parser.geometryIds.count, 10)
    }
    
    func testGetMorphers() {
        let nodes = parser.getMorphers()
        XCTAssertEqual(nodes.count, 5)
    }
    
    func testMorpherMap() {
        XCTAssertEqual(parser.morpherMap.count, 5)
    }
    
    func testGetInstanceGeometries() {
        XCTAssertEqual(parser.getInstanceGeometries().count, 4)
    }
    
    func testIsGeometryFalse() {
        XCTAssertFalse(parser.isGeometry(""))
    }
    
    func testIsGeometryTrue() {
        XCTAssert(parser.isGeometry("#CubeWithMorpher2-mesh"))
    }
    
    
    
}


