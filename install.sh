# build the project
xcodebuild build

# move it to /usr/local/bin
cp build/Release/ColladaMorphAdjuster /usr/local/bin/cma 

# run it
cma -h