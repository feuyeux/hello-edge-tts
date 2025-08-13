#!/bin/bash

# Dart TTS Client Build Script

set -e

echo "🎯 Building Dart TTS Client"
echo "==========================="

# Check Dart version
if ! command -v dart &> /dev/null; then
    echo "❌ Dart SDK not found. Please install Dart SDK 3.0 or later."
    exit 1
fi

DART_VERSION=$(dart --version 2>&1 | head -n1 | cut -d' ' -f4)
echo "✅ Found Dart $DART_VERSION"

# Get dependencies
echo "📥 Getting dependencies..."
dart pub get

# Analyze code
echo "🔍 Analyzing code..."
dart analyze

# Format code
echo "🎨 Formatting code..."
dart format --set-exit-if-changed lib/ bin/

# Run tests if they exist
if [ -d "test" ] && [ "$(ls -A test)" ]; then
    echo "🧪 Running tests..."
    dart test
fi

# Compile to native executable
echo "🔨 Compiling to native executable..."
dart compile exe bin/main.dart -o bin/hello_tts

# Create AOT snapshot for faster startup
echo "⚡ Creating AOT snapshot..."
dart compile aot-snapshot bin/main.dart -o bin/hello_tts.aot

echo "✅ Dart build completed successfully!"
echo "💡 To run: ./dart/bin/hello_tts"
echo "💡 Or: dart run bin/main.dart"