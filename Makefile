.PHONY: build run package check

build:
	bash scripts/build.sh

run:
	bash scripts/build.sh --restart

package:
	bash scripts/build.sh --package

check:
	swift build
	bash -n scripts/build.sh
	plutil -lint Info.plist
