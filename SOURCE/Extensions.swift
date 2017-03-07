//
//  Extensions.swift
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

// Convenience for common attributes
extension XMLElement {
    
    var id:String? {
        return self.attribute(forName: "id")?.objectValue as? String
    }
    
    var morph:XMLElement? {
        return self.elements(forName: "morph").first
    }
    
    var source:String? {
        return self.attribute(forName: "source")?.objectValue as? String
    }
    
    var url:String? {
        return self.attribute(forName: "url")?.objectValue as? String
    }
}

extension XMLElement {
    /// Replace one XML element with another, moving
    /// any children from the old node to the new.
    func replace(withNewNode newNode:XMLElement) {
        if let children = self.children {
            for child in children {
                child.detach()
                newNode.addChild(child)
            }
        }
        let parent = self.parent as? XMLElement
        self.detach()
        parent?.addChild(newNode)
    }
}


extension XMLDocument {
    /// Helper method for XPath queries on the XMLDocument
    ///
    /// - parameter string: An XPath query string
    ///
    /// - returns: The query result in an array containing zero or more XMLNodes
    ///
    func getNodes(forXPath string: String)->[XMLNode] {
        var nodes = [XMLNode]()
        do {
            nodes.append(contentsOf: try self.nodes(forXPath: string))
        } catch {
            print("Warning: XPath query failed")
            print(string)
            print(error.localizedDescription)
        }
        return nodes
    }
}

