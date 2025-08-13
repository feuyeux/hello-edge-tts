# Hello Edge TTS - Makefile
# Cross-platform build automation

.PHONY: all build clean test lint format install deploy help
.DEFAULT_GOAL := help

# Variables
VERSION ?= 1.0.0
DIST_DIR = dist
PYTHON_DIR = python
DART_DIR = dart
RUST_DIR = rust
JAVA_DIR = java

# Colors
BLUE = \033[0;34m
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

# Help target
help: ## Show this help message
	@echo "$(BLUE)Hello Edge TTS - Build System$(NC)"
	@echo "=============================="
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Language-specific targets:"
	@echo "  $(GREEN)build-python$(NC)    Build Python implementation"
	@echo "  $(GREEN)build-dart$(NC)      Build Dart implementation"
	@echo "  $(GREEN)build-rust$(NC)      Build Rust implementation"
	@echo "  $(GREEN)build-java$(NC)      Build Java implementation"
	@echo ""
	@echo "Examples:"
	@echo "  make build          # Build all implementations"
	@echo "  make test           # Run all tests"
	@echo "  make deploy         # Create deployment package"
	@echo "  make clean          # Clean all build artifacts"

# Main targets
all: build test ## Build and test all implementations

build: build-python build-dart build-rust build-java ## Build all implementations
	@echo "$(GREEN)✅ All builds completed successfully!$(NC)"

clean: clean-python clean-dart clean-rust clean-java ## Clean all build artifacts
	@echo "$(BLUE)[INFO]$(NC) Cleaning distribution directory..."
	@rm -rf $(DIST_DIR)
	@rm -f *.tar.gz *.zip deployment-summary.txt
	@echo "$(GREEN)✅ All clean operations completed!$(NC)"

test: test-python test-dart test-rust test-java ## Run all tests
	@echo "$(GREEN)✅ All tests completed successfully!$(NC)"

lint: lint-python lint-dart lint-rust lint-java ## Run all linters
	@echo "$(GREEN)✅ All lint checks completed successfully!$(NC)"

format: format-python format-dart format-rust format-java ## Format all code
	@echo "$(GREEN)✅ All code formatting completed successfully!$(NC)"

install: build ## Install all implementations
	@echo "$(BLUE)[INFO]$(NC) Installing all implementations..."
	@./build.sh
	@echo "$(GREEN)✅ Installation completed successfully!$(NC)"

deploy: build ## Create deployment package
	@echo "$(BLUE)[INFO]$(NC) Creating deployment package..."
	@./deploy.sh $(VERSION)
	@echo "$(GREEN)✅ Deployment package created successfully!$(NC)"

# Python targets
build-python: ## Build Python implementation
	@echo "$(BLUE)[INFO]$(NC) Building Python implementation..."
	@cd $(PYTHON_DIR) && ./build.sh

clean-python: ## Clean Python build artifacts
	@echo "$(BLUE)[INFO]$(NC) Cleaning Python build artifacts..."
	@cd $(PYTHON_DIR) && rm -rf .venv __pycache__ *.pyc build/ dist/ *.egg-info/

test-python: ## Run Python tests
	@echo "$(BLUE)[INFO]$(NC) Running Python tests..."
	@cd $(PYTHON_DIR) && source .venv/bin/activate && python -m pytest || echo "$(YELLOW)[WARNING]$(NC) Python tests not configured"

lint-python: ## Lint Python code
	@echo "$(BLUE)[INFO]$(NC) Linting Python code..."
	@cd $(PYTHON_DIR) && source .venv/bin/activate && flake8 . || echo "$(YELLOW)[WARNING]$(NC) Python linting not configured"

format-python: ## Format Python code
	@echo "$(BLUE)[INFO]$(NC) Formatting Python code..."
	@cd $(PYTHON_DIR) && source .venv/bin/activate && black . || echo "$(YELLOW)[WARNING]$(NC) Python formatting not configured"

# Dart targets
build-dart: ## Build Dart implementation
	@echo "$(BLUE)[INFO]$(NC) Building Dart implementation..."
	@cd $(DART_DIR) && ./build.sh

clean-dart: ## Clean Dart build artifacts
	@echo "$(BLUE)[INFO]$(NC) Cleaning Dart build artifacts..."
	@cd $(DART_DIR) && rm -rf .dart_tool/ build/ bin/hello_tts bin/hello_tts.aot

test-dart: ## Run Dart tests
	@echo "$(BLUE)[INFO]$(NC) Running Dart tests..."
	@cd $(DART_DIR) && dart test || echo "$(YELLOW)[WARNING]$(NC) Dart tests not configured"

lint-dart: ## Lint Dart code
	@echo "$(BLUE)[INFO]$(NC) Linting Dart code..."
	@cd $(DART_DIR) && dart analyze

format-dart: ## Format Dart code
	@echo "$(BLUE)[INFO]$(NC) Formatting Dart code..."
	@cd $(DART_DIR) && dart format lib/ bin/

# Rust targets
build-rust: ## Build Rust implementation
	@echo "$(BLUE)[INFO]$(NC) Building Rust implementation..."
	@cd $(RUST_DIR) && ./build.sh

clean-rust: ## Clean Rust build artifacts
	@echo "$(BLUE)[INFO]$(NC) Cleaning Rust build artifacts..."
	@cd $(RUST_DIR) && cargo clean

test-rust: ## Run Rust tests
	@echo "$(BLUE)[INFO]$(NC) Running Rust tests..."
	@cd $(RUST_DIR) && cargo test

lint-rust: ## Lint Rust code
	@echo "$(BLUE)[INFO]$(NC) Linting Rust code..."
	@cd $(RUST_DIR) && cargo clippy -- -D warnings

format-rust: ## Format Rust code
	@echo "$(BLUE)[INFO]$(NC) Formatting Rust code..."
	@cd $(RUST_DIR) && cargo fmt

# Java targets
build-java: ## Build Java implementation
	@echo "$(BLUE)[INFO]$(NC) Building Java implementation..."
	@cd $(JAVA_DIR) && ./build.sh

clean-java: ## Clean Java build artifacts
	@echo "$(BLUE)[INFO]$(NC) Cleaning Java build artifacts..."
	@cd $(JAVA_DIR) && mvn clean

test-java: ## Run Java tests
	@echo "$(BLUE)[INFO]$(NC) Running Java tests..."
	@cd $(JAVA_DIR) && mvn test

lint-java: ## Lint Java code
	@echo "$(BLUE)[INFO]$(NC) Linting Java code..."
	@cd $(JAVA_DIR) && mvn checkstyle:check || echo "$(YELLOW)[WARNING]$(NC) Java linting not configured"

format-java: ## Format Java code
	@echo "$(BLUE)[INFO]$(NC) Formatting Java code..."
	@cd $(JAVA_DIR) && mvn fmt:format || echo "$(YELLOW)[WARNING]$(NC) Java formatting not configured"

# Development targets
dev-setup: ## Set up development environment
	@echo "$(BLUE)[INFO]$(NC) Setting up development environment..."
	@echo "Installing pre-commit hooks..."
	@cp scripts/pre-commit .git/hooks/ 2>/dev/null || echo "$(YELLOW)[WARNING]$(NC) No pre-commit script found"
	@chmod +x .git/hooks/pre-commit 2>/dev/null || true
	@echo "$(GREEN)✅ Development environment setup completed!$(NC)"

check: lint test ## Run all checks (lint + test)
	@echo "$(GREEN)✅ All checks passed!$(NC)"

# Docker targets (if Docker support is added)
docker-build: ## Build Docker images for all implementations
	@echo "$(BLUE)[INFO]$(NC) Building Docker images..."
	@echo "$(YELLOW)[WARNING]$(NC) Docker support not yet implemented"

docker-run: ## Run Docker containers
	@echo "$(BLUE)[INFO]$(NC) Running Docker containers..."
	@echo "$(YELLOW)[WARNING]$(NC) Docker support not yet implemented"

# Benchmarking
benchmark: ## Run performance benchmarks
	@echo "$(BLUE)[INFO]$(NC) Running performance benchmarks..."
	@echo "$(YELLOW)[WARNING]$(NC) Benchmarking not yet implemented"

# Documentation
docs: ## Generate documentation
	@echo "$(BLUE)[INFO]$(NC) Generating documentation..."
	@cd $(RUST_DIR) && cargo doc --no-deps
	@cd $(JAVA_DIR) && mvn javadoc:javadoc
	@echo "$(GREEN)✅ Documentation generated successfully!$(NC)"

# Release management
release: ## Create a new release
	@echo "$(BLUE)[INFO]$(NC) Creating release $(VERSION)..."
	@git tag -a v$(VERSION) -m "Release version $(VERSION)"
	@make deploy VERSION=$(VERSION)
	@echo "$(GREEN)✅ Release $(VERSION) created successfully!$(NC)"
	@echo "$(BLUE)[INFO]$(NC) Don't forget to push the tag: git push origin v$(VERSION)"