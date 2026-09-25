APP := .build/SaaSCosts.app
BIN := $(APP)/Contents/MacOS/SaaSCosts

.PHONY: check lint build test app run stop clean

## Gate for every commit: lint, warning-free build, tests.
check: lint build test

lint:
	swiftlint lint --strict --quiet

build:
	swift build -Xswiftc -warnings-as-errors

test:
	swift test -Xswiftc -warnings-as-errors

app:
	swift build -c release -Xswiftc -warnings-as-errors
	rm -rf "$(APP)"
	mkdir -p "$(APP)/Contents/MacOS"
	cp .build/release/SaaSCosts "$(BIN)"
	cp Info.plist "$(APP)/Contents/Info.plist"
	codesign --force --sign - "$(APP)"

## Launched from the repo root so ./.env.local is picked up as a fallback.
run: app stop
	nohup "$(BIN)" >/dev/null 2>&1 &

stop:
	-pkill -x SaaSCosts

clean:
	rm -rf .build
