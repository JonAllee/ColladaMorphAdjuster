# ColladaMorphAdjuster
ColladaMorphAdjuster makes shape key / morphers in Blender-exported Collada (.dae) available to Apple SceneKit.

 As recently as Blender 2.78, Blender Collada export does not
 create instance_controllers for its shape keys.
 Where possible missing instance_controllers will be added.

 The primary purpose of this tool is Apple SceneKit import.
 This tool will not create nodes with multiple controllers, i.e.
 no morph on morph, skin on morph or morph on skin.
 As of XCode Version 8.3 beta 2 (8W120l) Apple SceneKit import
 does not fully support these use cases.

## Usage:
ColladaMorphAdjuster collada_file [-o output_file]

or

ColladaMorphAdjuster -h

## License
This tool is released under the MIT License. See LICENSE file for details.

 
