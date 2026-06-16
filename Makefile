# Convenience test runner.
#
# The project is split across two test surfaces that xcodebuild cannot run in a
# single invocation: the app target's unit tests and the NeugelbKit package's
# foundation tests. `make test` runs both.
#
# Override the simulator if needed, e.g.:
#   make test DESTINATION='platform=iOS Simulator,name=iPhone 16 Pro'

DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
DESTINATION   ?= platform=iOS Simulator,name=iPhone 17 Pro
APP_SCHEME     = NeugelbCodingChallenge-iOS-FarazAhmed
PKG_SCHEME     = NeugelbKit-Package

export DEVELOPER_DIR

.PHONY: test test-app test-package

test: test-package test-app ## Run every test (package + app)

test-app: ## Run the app target's unit tests
	xcodebuild test -scheme "$(APP_SCHEME)" -destination "$(DESTINATION)"

test-package: ## Run the NeugelbKit foundation tests
	cd Packages/NeugelbKit && xcodebuild test -scheme "$(PKG_SCHEME)" -destination "$(DESTINATION)"
