# Container-first development workflow.
# All Crystal/shards commands run inside the official crystallang/crystal image
# via podman or docker. No native Crystal install required on the host.

CRYSTAL_IMAGE ?= docker.io/crystallang/crystal:latest

# Auto-detect container runtime; prefer podman.
RUNTIME := $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null)

ifeq ($(RUNTIME),)
$(error Neither podman nor docker was found on PATH. Install one to continue.)
endif

# Rootless podman needs --userns=keep-id to map the host user, and :Z to relabel
# the volume for SELinux. Docker uses neither.
ifeq ($(notdir $(RUNTIME)),podman)
RUN_FLAGS := --userns=keep-id
VOL_SUFFIX := :Z
else
RUN_FLAGS :=
VOL_SUFFIX :=
endif

CRYSTAL_RUN := $(RUNTIME) run --rm $(RUN_FLAGS) -v $(CURDIR):/work$(VOL_SUFFIX) -w /work $(CRYSTAL_IMAGE)
CRYSTAL_IT  := $(RUNTIME) run --rm -it $(RUN_FLAGS) -v $(CURDIR):/work$(VOL_SUFFIX) -w /work $(CRYSTAL_IMAGE)

.DEFAULT_GOAL := help
.PHONY: help install spec fmt check shell pull clean

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*?## "}; /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install shard dependencies into ./lib
	$(CRYSTAL_RUN) shards install

spec: ## Run specs. Override with FILE=spec/path/to_spec.cr to run a single file
	$(CRYSTAL_RUN) crystal spec $(FILE)

fmt: ## Format Crystal sources in place
	$(CRYSTAL_RUN) crystal tool format

check: ## Verify formatting without writing changes
	$(CRYSTAL_RUN) crystal tool format --check

shell: ## Drop into an interactive shell inside the Crystal container
	$(CRYSTAL_IT) sh

pull: ## Pull the latest Crystal image
	$(RUNTIME) pull $(CRYSTAL_IMAGE)

clean: ## Remove build artifacts (keeps shard.lock)
	rm -rf lib/ bin/ .crystal/
