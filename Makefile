.PHONY: build run run-json

build:
	@echo "Building Lung Lang"
	@zig build

run: build
	@echo "Running Lung Lang"
	@./zig-out/bin/lung-lang example.ln 2&> result.json

run-json: build
	@echo "Running Lung Lang"
	@./zig-out/bin/lung-lang example.ln 1>&2