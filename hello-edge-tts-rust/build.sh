#!/bin/bash

# Rust TTS Client Build Script

set -e

echo "🦀 Building Rust TTS Client"
echo "==========================="

# Check Rust version
if ! command -v cargo &> /dev/null; then
    echo "❌ Rust/Cargo not found. Please install Rust 1.70 or later."
    exit 1
fi

RUST_VERSION=$(rustc --version | cut -d' ' -f2)
echo "✅ Found Rust $RUST_VERSION"

# Format code
echo "🎨 Formatting code..."
cargo fmt --check

# Lint code
echo "🔍 Running Clippy lints..."
cargo clippy -- -D warnings

# Build in debug mode
echo "🔨 Building in debug mode..."
cargo build

# Run tests
echo "🧪 Running tests..."
cargo test

# Build in release mode
echo "🚀 Building in release mode..."
cargo build --release

# Run benchmarks if they exist
if grep -q "\[\[bench\]\]" Cargo.toml 2>/dev/null; then
    echo "⏱️  Running benchmarks..."
    cargo bench
fi

# Generate documentation
echo "📚 Generating documentation..."
cargo doc --no-deps

echo "✅ Rust build completed successfully!"
echo "💡 Debug binary: ./target/debug/hello-edge-tts"
echo "💡 Release binary: ./target/release/hello-edge-tts"
echo "💡 Documentation: ./target/doc/hello_edge_tts/index.html"