.PHONY: build
build: 
	@xcodebuild build

.PHONY: install
install: build
	sh install.sh