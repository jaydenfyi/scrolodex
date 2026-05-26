.PHONY: build test app run clean release app-release zip

APP_NAME := Scrolodex
BUILD_DIR := .build/arm64-apple-macosx/debug
RELEASE_DIR := .build/arm64-apple-macosx/release
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
RELEASE_APP_DIR := $(RELEASE_DIR)/$(APP_NAME).app

test:
	swift test

build:
	swift build

release:
	swift build -c release

app: build
	rm -rf "$(APP_DIR)"
	mkdir -p "$(APP_DIR)/Contents/MacOS" "$(APP_DIR)/Contents/Resources"
	cp "$(BUILD_DIR)/$(APP_NAME)" "$(APP_DIR)/Contents/MacOS/$(APP_NAME)"
	cp "Resources/Info.plist" "$(APP_DIR)/Contents/Info.plist"
	cp "Sources/Scrolodex/Resources/MenuBarIcon.svg" "$(APP_DIR)/Contents/Resources/"
	codesign --force --sign "Scrolodex Dev" "$(APP_DIR)"

app-release: release
	rm -rf "$(RELEASE_APP_DIR)"
	mkdir -p "$(RELEASE_APP_DIR)/Contents/MacOS" "$(RELEASE_APP_DIR)/Contents/Resources"
	cp "$(RELEASE_DIR)/$(APP_NAME)" "$(RELEASE_APP_DIR)/Contents/MacOS/$(APP_NAME)"
	cp "Resources/Info.plist" "$(RELEASE_APP_DIR)/Contents/Info.plist"
	cp "Sources/Scrolodex/Resources/MenuBarIcon.svg" "$(RELEASE_APP_DIR)/Contents/Resources/"
	codesign --force --sign - "$(RELEASE_APP_DIR)"

zip: app-release
	ditto -c -k --keepParent "$(RELEASE_APP_DIR)" "$(RELEASE_DIR)/$(APP_NAME)-$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist).zip"

run: app
	open "$(APP_DIR)"

clean:
	rm -rf .build
