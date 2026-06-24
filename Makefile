SHELL := /usr/bin/env bash
ROOT  := $(shell pwd)

.PHONY: help run test
help: ## Show available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  %-22s %s\n", $$1, $$2}'

run: ## Launch OpenSCAD GUI on a project: make run P=<project>
	@test -n "$(P)" || { echo "Usage: make run P=<project>"; exit 1; }
	@entry="projects/$(P)/assembly.scad"; \
	  [ -f "$$entry" ] || entry="projects/$(P)/$(P).scad"; \
	  [ -f "$$entry" ] || { echo "No entry file for project $(P)"; exit 1; }; \
	  scripts/openscad.sh "$$entry"

test: ## Run the tooling test suite
	@bash tests/run.sh
