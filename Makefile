SHELL := /usr/bin/env bash

.PHONY: help run test render render-all new-lib new-project check list
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

render: ## Render a project to PNG: make render P=<project>
	@test -n "$(P)" || { echo "Usage: make render P=<project>"; exit 1; }
	@scripts/render.sh "$(P)"

render-all: ## Render every project
	@for d in projects/*/; do \
	  [ -d "$$d" ] || continue; \
	  p="$$(basename "$$d")"; \
	  scripts/render.sh "$$p" || exit 1; \
	done

new-lib: ## Scaffold a library: make new-lib NAME=<x>
	@test -n "$(NAME)" || { echo "Usage: make new-lib NAME=<x>"; exit 1; }
	@scripts/new-lib.sh "$(NAME)"

new-project: ## Scaffold a project: make new-project NAME=<x> [MULTIPART=1]
	@test -n "$(NAME)" || { echo "Usage: make new-project NAME=<x> [MULTIPART=1]"; exit 1; }
	@if [ -n "$(MULTIPART)" ]; then scripts/new-project.sh "$(NAME)" --multipart; \
	 else scripts/new-project.sh "$(NAME)"; fi

check: ## Lint conventions and compile-check all .scad
	@scripts/check.sh

list: ## List libraries and projects
	@echo "Libraries:"; for d in libraries/*/; do [ -d "$$d" ] || continue; echo "  $$(basename "$$d")"; done
	@echo "Projects:";  for d in projects/*/;  do [ -d "$$d" ] || continue; echo "  $$(basename "$$d")"; done
