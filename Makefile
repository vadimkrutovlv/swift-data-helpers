CONFIG ?= debug
IOS_SIMULATOR_DEVICE = iPhone 17 Pro
IOS_SIMULATOR_OS = 26.2

PLATFORM_IOS_SIM = platform=iOS Simulator,name=$(IOS_SIMULATOR_DEVICE),OS=$(IOS_SIMULATOR_OS)
PLATFORM_IOS_GENERIC = generic/platform=iOS
PLATFORM_MAC = platform=macOS
PLATFORM_MAC_CATALYST = platform=macOS,variant=Mac Catalyst
PLATFORM_WATCHOS = generic/platform=watchOS
PLATFORM_TVOS = generic/platform=tvOS
PLATFORM_VISIONOS = generic/platform=visionOS

.PHONY: build-all-platforms build-for-library-evolution test test-exampleApp

build-all-platforms:
	set -euo pipefail; \
	for platform in \
	  "$(PLATFORM_IOS_GENERIC)" \
	  "$(PLATFORM_MAC)" \
	  "$(PLATFORM_MAC_CATALYST)" \
	  "$(PLATFORM_WATCHOS)" \
	  "$(PLATFORM_TVOS)" \
	  "$(PLATFORM_VISIONOS)"; \
	do \
		xcodebuild build \
			-scheme SwiftDataHelpers \
			-configuration $(CONFIG) \
			-destination "$$platform"; \
	done;

build-for-library-evolution:
	swift build \
		-c release \
		--target SwiftDataHelpers \
		-Xswiftc -emit-module-interface \
		-Xswiftc -enable-library-evolution

test:
	swift test

test-exampleApp:
	xcodebuild test \
		-project SwiftDataHelpersExample/SwiftDataHelpersExample.xcodeproj \
		-scheme SwiftDataHelpersExample \
		-destination "$(PLATFORM_IOS_SIM)"
