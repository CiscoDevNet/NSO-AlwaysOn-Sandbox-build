HOME := $(shell echo $$HOME)
export HOME

include sandbox_env_vars.sh
-include .env

export

# Detect if docker or podman is available and use the one that is available
CONTAINER_ENGINE := $(shell which docker 2>/dev/null || which podman 2>/dev/null)
ifeq ($(CONTAINER_ENGINE),)
$(error Neither Docker nor Podman is installed or in PATH)
endif
CONTAINER_ENGINE_NAME := $(shell basename $(CONTAINER_ENGINE))
export CONTAINER_ENGINE CONTAINER_ENGINE_NAME

# Adjust tag based on env vars
TAG = $(TAG_IMAGE):$(NSO_VERSION)

# ===========================================================================
# Local development targets
# ===========================================================================

all: build run

# ===========================================================================
# NSO Image Management
# ===========================================================================

extract-nso-image:
	@echo "=== Extracting NSO container image from signed binary ==="
	chmod +x ./deploy-to-sandbox/extract_nso_image.sh
	./deploy-to-sandbox/extract_nso_image.sh

load-nso-image:
	@echo "=== Loading NSO container image ==="
	chmod +x ./deploy-to-sandbox/load_nso_image.sh
	./deploy-to-sandbox/load_nso_image.sh

check-image-info:
	chmod +x ./deploy-to-sandbox/check_image_info.sh
	./deploy-to-sandbox/check_image_info.sh

cleanup-temp-files:
	@echo "=== Cleaning up temporary NSO files ==="
	chmod +x ./deploy-to-sandbox/cleanup_temp_files.sh
	./deploy-to-sandbox/cleanup_temp_files.sh

# ===========================================================================
# Local Container Development
# ===========================================================================

build: clean
	$(CONTAINER_ENGINE) build --build-arg BASE_IMAGE=$(BASE_IMAGE) --build-arg NSO_VERSION=$(NSO_VERSION) --platform linux/amd64 --tag $(TAG) .

run: clean
	$(CONTAINER_ENGINE) run -itd --name $(CONTAINER_NAME) --platform linux/amd64 -v $(PWD)/packages:/home/developer/packages -p 50022:22 -p 443:443 -p 2024:2024 -p 8080:8080 -e ADMIN_PASSWORD=admin -u $(SANDBOX_USER) $(TAG)

cli:
	$(CONTAINER_ENGINE) exec -it $(CONTAINER_NAME) /bin/bash

clean:
	-$(CONTAINER_ENGINE) rm --force $(CONTAINER_NAME)

follow:
	$(CONTAINER_ENGINE) logs --follow $(CONTAINER_NAME)

# ===========================================================================
# Build and deploy to sandbox
# ===========================================================================

build-sandbox:
	$(CONTAINER_ENGINE) build --build-arg BASE_IMAGE=$(BASE_IMAGE) --build-arg NSO_VERSION=$(NSO_VERSION) --platform linux/amd64 --no-cache --tag $(TAG) .
	
deploy-sandbox:
	@echo "=== Launching NSO container on sandbox VM ==="
	chmod +x ./deploy-to-sandbox/deploy_nso.sh
	./deploy-to-sandbox/deploy_nso.sh

verify-sandbox:
	@echo "=== Verifying NSO deployment on sandbox VM ==="
	@echo "=== NSO Direct Deployment completed successfully! ==="
	chmod +x ./deploy-to-sandbox/verify_nso.sh
	./deploy-to-sandbox/verify_nso.sh

post-cleanup:
	chmod +x ./deploy-to-sandbox/post_cleanup_nso.sh
	./deploy-to-sandbox/post_cleanup_nso.sh

build-deploy-sandbox: build-sandbox deploy-sandbox verify-sandbox post-cleanup

# ===========================================================================
# Project help
# ===========================================================================

help:
	@echo "🚀 NSO Always-On Sandbox - Available Make Targets"
	@echo ""
	@echo "📋 Setup & Management:"
	@echo "  cleanup-temp-files     - Clean temporary NSO files" 
	@echo "  install-git-hooks      - Install git pre-commit hooks (manual)"
	@echo ""
	@echo "🔧 Development:"
	@echo "  all                    - Build and run container locally"
	@echo "  build                  - Build container image"
	@echo "  run                    - Run container locally"
	@echo "  cli                    - Enter running container"
	@echo "  clean                  - Remove local container"
	@echo "  follow                 - Follow container logs"
	@echo ""
	@echo "📦 NSO Image Management:"
	@echo "  extract-nso-image      - Extract NSO container from signed binary"
	@echo "  load-nso-image         - Load NSO container image"
	@echo "  check-image-info       - Check container image information"
	@echo ""
	@echo "☁️ Sandbox Deployment:"
	@echo "  build-sandbox          - Build container for sandbox deployment"
	@echo "  deploy-sandbox         - Deploy to sandbox environment"
	@echo "  verify-sandbox         - Verify sandbox deployment"
	@echo "  post-cleanup           - Post-deployment cleanup"
	@echo ""
	@echo "🔒 Security:"
	@echo "  Git hooks prevent accidental commits of proprietary files"
	@echo "  See docs/GIT_HOOK_PROTECTION.md for details"
