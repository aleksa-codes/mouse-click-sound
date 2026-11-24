.PHONY: build run package check

# Swift 6.4.3 standalone toolchain in ~/Library/Developer/Toolchains.
TOOLCHAINS ?= org.swift.643202611191a
export TOOLCHAINS

build:
	bash scripts/build.sh

run:
	bash scripts/build.sh --restart

package:
	bash scripts/build.sh --package

check:
	swift build
	swiftc -typecheck scripts/app-control.swift
	bash -n scripts/build.sh
	plutil -lint Info.plist
