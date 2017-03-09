//
//  main.swift
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

func showUsage() {
    let executable = NSURL(string:CommandLine.arguments[0])?.lastPathComponent ?? "ColladaMorphAdjuster"
    print("Usage:")
    print("\(executable) collada_file [-o output_file=out.dae]")
    print("or")
    print("\(executable) -h")
    print("")
    print(" Modifies Blender generated Collada (.dae) files.")
}

func showHelp() {
    showUsage()
    print(" Blender shape keys apply to all instances of their geometry.")
    print(" As recently as Blender 2.78, Blender Collada export does not")
    print(" create instance_controllers for its shape keys.")
    print(" Where possible missing instance_controllers will be added.")
    print("")
    print(" The primary purpose of this tool is Apple SceneKit import.")
    print(" This tool will not create nodes with multiple controllers, i.e.")
    print(" no morph on morph, skin on morph or morph on skin.")
    print(" As of XCode Version 8.3 beta 2 (8W120l) Apple SceneKit import")
    print(" does not fully support these use cases.")
}

func main()->Int32 {
    var inputFile:String!
    var outputFile:String!
    
    if CommandLine.arguments.count == 4,
        CommandLine.arguments[2] == "-o"
    {
        inputFile = CommandLine.arguments[1]
        outputFile = CommandLine.arguments[3]
    }
    else if CommandLine.arguments.count == 2,
    CommandLine.arguments[1] == "-h"
    {
        showHelp()
        return EXIT_SUCCESS
    }
    else if CommandLine.arguments.count == 2
    {
        inputFile = CommandLine.arguments[1]
        outputFile = "out.dae"
    }
    else {
        showUsage()
        return EXIT_FAILURE
    }
    
    return ColladaMorphAdjuster.adjust(inputFile: inputFile, outputFile: outputFile)
}

exit(main())



