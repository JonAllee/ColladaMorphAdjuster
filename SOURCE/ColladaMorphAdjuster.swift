//
//  ColladaMorphAdjuster.swift
//
//  Copyright (c) 2017 Jonathan Allee
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
import Foundation

/// Modifies Blender-generated Collada files to make morph controllers 
/// available to SceneKit.
/// 
/// Blender's shape keys are global. Blender Collada export maps shape keys to
/// Collada library_controllers. As of version 2.78, Blender doesn't create 
/// instance_controllers in nodes. To properly apply morph library controllers
/// to all nodes that were affected by Blender shape keys, nodes that share 
/// geometry with library_controllers should have an instance controller. This 
/// class will replace instance_geometry nodes with instance_controllers in such
/// cases. 
/// 
/// Not Supported: Nodes that have an armature and a shape key.
///     The target is Apple SceneKit. SceneKit doesn't support the 
///     resulting Collada, so this tool will just leave the morphers off of 
////    nodes that have Blender armature (known as skin controllers in Collada).
///
open class ColladaMorphAdjuster {
    /// Holds data about nodes that need adjustment.
    ///
    /// - instanceGeometry is an instance geometry element which should be
    /// replaced
    ///
    /// - libraryController is the morpher that needs to be instanced in place 
    ///  of instanceGeometry
    ///
    typealias FixItem = (instanceGeometry:XMLElement, libraryController:XMLElement)
    
    // Collada file to load
    let inputFile:String
    
    // Path for adjusted Collada output file.
    let outputFile:String
    
    /// Adds morph instance_controllers to a Collada file.
    ///
    /// - parameter inputFile:  Local path of the input Collada file to parse.
    /// - parameter outputFile: Local path of the modified output file.
    ///
    /// - returns: EXIT_SUCCESS on success or EXIT_FAILURE for any failure.
    ///
    open class func adjust(inputFile : String, outputFile : String)->Int32 {
        return ColladaMorphAdjuster(inputFile: inputFile, outputFile: outputFile).adjust()
    }
    
    init(inputFile : String, outputFile : String) {
        self.inputFile = inputFile
        self.outputFile = outputFile
    }
    
    /// Adds morph instance_controllers to a Collada file.
    ///
    ///- returns: EXIT_SUCCESS on success or EXIT_FAILURE for any failure.
    ///
    func adjust()->Int32 {
        // Load the input file.
        if self.xmlDoc == nil {
            print("Error loading file.\n")
            return EXIT_FAILURE
        }
        
        // Parse the file
        var fixItems = findNodesToFix()
        
        // Print some stats
        print("Morphers in library controllers:\n\(morpherMap.count) ")
        print("Geometries in library geometries:\n\(geometryIds.count) ")
        print("Nodes to modify:\n\(fixItems.count)\n")
    
        // Make changes to the internal XMLDocument
        let count  = addInstanceControllers(fixItems: &fixItems)
        print("Successfully modified nodes:\n\(count)\n")
        
        // Save to the output file.
        do {
            try self.save(filename: self.outputFile)
        } catch {
            print("Error saving \(outputFile).\n \(error.localizedDescription)")
            return EXIT_FAILURE
        }
    
        print("Done")
        return EXIT_SUCCESS
    }
    
    /// Make changes to the internal XMLDocument
    /// 
    /// Replace instance_geometry elements with an instance_controller
    /// pointing to the same geometry. Preserve bind_material if present.
    ///
    /// - Returns: The number of nodes modified
    func addInstanceControllers( fixItems: inout [FixItem])->UInt32 {
        var controllersAdded = UInt32(0)
        for fixItem in fixItems {
            if let instanceController = instanceController(forLibraryController : fixItem.libraryController) {
                //
                fixItem.instanceGeometry.replace(withNewNode: instanceController)
                controllersAdded += 1
            }
            else {
                print("Warning: Unable to create instance controller for: \(fixItem.libraryController.id ?? "<unknown controller>")")
            }
        }
        fixItems.removeAll() // we shouldn't use this list again.
        return controllersAdded
    }
    
    /// Creates a mapping between nodes that should be modifed and 
    /// the appropriate morph controller.
    ///
    func findNodesToFix()->[FixItem] {
        var items = [FixItem]()
        guard self.morpherMap.count > 0 else {  return items   }
        
        for case let instanceGeometry as XMLElement in self.getInstanceGeometries() {
            if  let morpher = morpher(forInstanceGeometry: instanceGeometry) {
                items.append((instanceGeometry, morpher))
            }
        }
        return items
    }

    /// The one and only XMLDocument
    ///
    lazy var xmlDoc:XMLDocument! = {
        do {
            return try self.createDocument(filename: self.inputFile)
        } catch {
            print("\(error.localizedDescription)")
            return nil
        }
    }()
    
    /// List of valid geometries by id.
    lazy var  geometryIds:[String] = {
        var ids = [String]()
        for case let node as XMLElement in self.getGeometryNodes()  {
            if let id = node.id {
                ids.append(id)
            }
        }
        return ids
    }()
    
    /// Dictionary mapping geometry source to morph library controller
    lazy var morpherMap:[String:XMLElement] = {
        var map = [String:XMLElement]()
        for case let node as XMLElement in self.getMorphers() {
            guard let morph = node.morph,
                let source = morph.source,
                self.isGeometry(source)
                else {
                    continue
            }
            map[source] = node
        }
        return map
    }()
    
    /// Find a morpher that points to the same geometry as an instance 
    /// geometry if such a morpher exists.
    /// 
    /// - parameter node: The instance geometry
    ///
    /// - returns: A library_controller element representing a morpher or nil
    ///
    func morpher(forInstanceGeometry node:XMLElement)->XMLElement? {
        guard let url = node.url else { return nil }
        
        return self.morpherMap[url]
    }
    
    /// Loads an XMLDocument
    ///
    /// - parameter url: The filename of the xml document to load.
    ///
    /// - returns: An XMLDocument
    ///
    func createDocument(filename:String)throws->XMLDocument? {
        let url = URL(fileURLWithPath: NSString(string: filename).standardizingPath)
        let options:XMLNode.Options = [.nodeLoadExternalEntitiesNever]
        
        return try XMLDocument(contentsOf: url, options: Int(options.rawValue))
    }
    
    /// Adds a '#' to the controller's id to create a uri fragment
    func createURLForController(_ controller: XMLElement)->String? {
        guard let id = controller.id else { return nil }
        
        return "#\(id)"
    }
    
    /// Simplified uri fragment parser. Remove the leading '#'
    func id(fromFragment fragment:String)->String? {
        guard fragment.hasPrefix("#"),
            fragment.characters.count > 1 else {
                return nil
        }
        return fragment.substring(from: fragment.index(after:fragment.startIndex))
    }
    
    /// Creates an instance controller node for a library controller
    ///
    /// - parameter forLibraryController: A library controller from
    ///    library_controllers to be instanced.
    ///
    /// - returns: An instance controller that refers to the passed library
    ///    controller
    ///
    func instanceController(forLibraryController controller:XMLElement)->XMLElement? {
        guard let url = createURLForController(controller),
            let name = controller.id else {
                return nil
        }
        
        let instanceController = XMLElement.element(withName: "instance_controller") as? XMLElement
        instanceController?.setAttributesWith([ "url":url, "name":name ])
        return instanceController
    }
    
    /// Tests a geometry uri fragment
    ///
    /// - parameter uri: local reference to geometry source
    ///
    /// - returns: Returns true if the uri fragment points to a geometry node in 
    ///    library_geometries, returns false if the uri points to an
    ///    instance_controller or something unexpected.
    ///
    func isGeometry(_ uri:String)->Bool {
        if let id = id(fromFragment: uri) {
            return self.geometryIds.contains(id)
        }
        return false
    }
    
    /// Save the XMLDocument to disk.
    ///
    /// Throws on failure.
    ///
    /// - parameter filename: The save file destination.
    ///
    func save(filename:String)throws {
        let string = NSString(string: filename).standardizingPath
        let fileURL = URL(fileURLWithPath: string)
        
        let options:XMLNode.Options = [.nodePrettyPrint]
        let text = self.xmlDoc.xmlString(withOptions: Int(options.rawValue))
        
        print("Writing \(text.lengthOfBytes(using: .utf8)) bytes to")
        print("\(fileURL.path)\n")
        
        try text.write(to: fileURL, atomically: false, encoding: .utf8)
    }
    
    // MARK: - XPath Queries
    
    // XPath queries
    static let xPathLibraryGeometries:String = "/COLLADA/library_geometries/geometry"
    static let xPathInstanceGeometries:String = "*//visual_scene//node/instance_geometry[@url]"
    static let xPathMorphers:String = "/COLLADA/library_controllers/controller[morph]"
    static let xPathAuthoringTool:String = "/COLLADA/asset/contributor/authoring_tool"
    
    /// Return authoring tool if available.
    func getAuthoringTool()->String? {
        return xmlDoc.getNodes(forXPath: ColladaMorphAdjuster.xPathAuthoringTool).first?.objectValue as? String
    }
    
    /// Return nodes in the scene with instance geometries
    func getInstanceGeometries()->[XMLNode] {
        return xmlDoc.getNodes(forXPath: ColladaMorphAdjuster.xPathInstanceGeometries)
    }
    
    /// Return all geometry nodes from libary_geometries
    func getGeometryNodes()->[XMLNode] {
        return xmlDoc.getNodes(forXPath: ColladaMorphAdjuster.xPathLibraryGeometries)
    }
    
    /// Return morph controller nodes from library_controllers
    func getMorphers()->[XMLNode] {
        return xmlDoc.getNodes(forXPath: ColladaMorphAdjuster.xPathMorphers)
    }
}
