EXECUTABLE := SaaS-Costs
BUNDLE_ID := com.cesarzea.sass-costs
BUILD_DIR := .build
RELEASE_DIR := $(BUILD_DIR)/release
APP_NAME := SaaS\ Costs\ Monitor
INSTALL_PATH := /Applications

.PHONY: build release clean install lint help

help:
	@echo "SaaS Costs Monitor - Makefile targets"
	@echo ""
	@echo "  make build      - Build debug executable"
	@echo "  make release    - Build optimized release"
	@echo "  make lint       - Run SwiftLint validation"
	@echo "  make clean      - Remove build artifacts"
	@echo "  make install    - Build and install to /Applications"
	@echo "  make help       - Show this help message"

build:
	@echo "Building $(EXECUTABLE)..."
	swift build -Xswiftc -suppress-warnings

release:
	@echo "Building optimized release..."
	swift build -c release -Xswiftc -suppress-warnings

lint:
	@echo "Running SwiftLint..."
	swiftlint Sources/

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	swift package clean

install: release lint
	@echo "Installing $(APP_NAME) to $(INSTALL_PATH)..."
	@echo "Note: Run manually to create .app bundle in Xcode"

.DEFAULT_GOAL := help
