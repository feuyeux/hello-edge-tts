#!/bin/bash

# Hello Edge TTS - Multi-language Build Script
# This script builds all language implementations

set -e  # Exit on any error

echo "🚀 Hello Edge TTS - Multi-language Build Script"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Build Python implementation
build_python() {
    print_status "Building Python implementation..."
    
    if ! command_exists python3; then
        print_error "Python 3 not found. Please install Python 3.8 or later."
        return 1
    fi
    
    cd hello-edge-tts-python
    
    # Create virtual environment if it doesn't exist
    if [ ! -d ".venv" ]; then
        print_status "Creating Python virtual environment..."
        python3 -m venv .venv
    fi
    
    # Setup venv executables without sourcing
    print_status "Configuring Python virtual environment executables..."
    if [ -f ".venv/Scripts/python.exe" ]; then
        VENV_PYTHON=".venv/Scripts/python.exe"
        VENV_PIP=".venv/Scripts/pip.exe"
    else
        VENV_PYTHON=".venv/bin/python"
        VENV_PIP=".venv/bin/pip"
    fi

    # Upgrade pip
    "$VENV_PIP" install --upgrade pip

    # Install dependencies
    print_status "Installing Python dependencies..."
    "$VENV_PIP" install -r requirements.txt

    # Run basic syntax check
    print_status "Running Python syntax check..."
    "$VENV_PYTHON" -m py_compile *.py
    cd ..
    
    print_success "Python build completed successfully!"
}

# Build Dart implementation
build_dart() {
    print_status "Building Dart implementation..."
    
    if ! command_exists dart; then
        print_error "Dart SDK not found. Please install Dart SDK 3.0 or later."
        return 1
    fi
    
    cd hello-edge-tts-dart
    
    # Get dependencies
    print_status "Getting Dart dependencies..."
    dart pub get
    
    # Analyze code
    print_status "Analyzing Dart code..."
    dart analyze
    
    # Compile to executable
    print_status "Compiling Dart application..."
    dart compile exe bin/main.dart -o bin/hello_tts
    
    cd ..
    
    print_success "Dart build completed successfully!"
}

# Build Rust implementation
build_rust() {
    print_status "Building Rust implementation..."
    
    if ! command_exists cargo; then
        print_error "Rust/Cargo not found. Please install Rust 1.70 or later."
        return 1
    fi
    
    cd hello-edge-tts-rust
    
    # Build in release mode
    print_status "Building Rust project in release mode..."
    cargo build --release
    
    # Run tests
    print_status "Running Rust tests..."
    cargo test
    
    cd ..
    
    print_success "Rust build completed successfully!"
}

# Build Java implementation
build_java() {
    print_status "Building Java implementation..."
    
    if ! command_exists mvn; then
        print_error "Maven not found. Please install Apache Maven 3.6 or later."
        return 1
    fi
    
    cd hello-edge-tts-java
    
    # Clean and compile
    print_status "Cleaning and compiling Java project..."
    mvn clean compile
    
    # Run tests
    print_status "Running Java tests..."
    mvn test
    
    # Package
    print_status "Packaging Java application..."
    mvn package
    
    cd ..
    
    print_success "Java build completed successfully!"
}

# Main build function
main() {
    local build_all=true
    local build_python=false
    local build_dart=false
    local build_rust=false
    local build_java=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --python)
                build_all=false
                build_python=true
                shift
                ;;
            --dart)
                build_all=false
                build_dart=true
                shift
                ;;
            --rust)
                build_all=false
                build_rust=true
                shift
                ;;
            --java)
                build_all=false
                build_java=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --python    Build only Python implementation"
                echo "  --dart      Build only Dart implementation"
                echo "  --rust      Build only Rust implementation"
                echo "  --java      Build only Java implementation"
                echo "  --help, -h  Show this help message"
                echo ""
                echo "If no options are specified, all implementations will be built."
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information."
                exit 1
                ;;
        esac
    done
    
    local failed_builds=()
    
    # Build implementations
    if [[ "$build_all" == true || "$build_python" == true ]]; then
        if ! build_python; then
            failed_builds+=("Python")
        fi
    fi
    
    if [[ "$build_all" == true || "$build_dart" == true ]]; then
        if ! build_dart; then
            failed_builds+=("Dart")
        fi
    fi
    
    if [[ "$build_all" == true || "$build_rust" == true ]]; then
        if ! build_rust; then
            failed_builds+=("Rust")
        fi
    fi
    
    if [[ "$build_all" == true || "$build_java" == true ]]; then
        if ! build_java; then
            failed_builds+=("Java")
        fi
    fi
    
    # Summary
    echo ""
    echo "================================================"
    if [[ ${#failed_builds[@]} -eq 0 ]]; then
        print_success "All builds completed successfully! 🎉"
    else
        print_error "Some builds failed:"
        for build in "${failed_builds[@]}"; do
            echo "  - $build"
        done
        exit 1
    fi
}

# Run main function with all arguments
main "$@"