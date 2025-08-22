#!/bin/bash

# Multilingual Edge TTS Demo - Master Script
# Generates audio files for 12 languages using 4 programming implementations

set -e

echo "Multilingual Edge TTS Demo"
echo "========================="
echo "Generating audio for 12 languages with 4 implementations"
echo

# Check config file
if [ ! -f "shared/multilingual_demo_config.json" ]; then
    echo "ERROR: Configuration file not found: shared/multilingual_demo_config.json"
    exit 1
fi

# Initialize counters
python_success=0
dart_success=0
java_success=0
rust_success=0

# Run Python Implementation
echo "Running Python Implementation..."
cd hello-edge-tts-python
if command -v python3 >/dev/null 2>&1; then
    if python3 multilingual_demo.py; then
        python_success=1
        echo "✓ Python completed successfully"
    else
        echo "✗ Python failed"
    fi
else
    echo "✗ Python not found"
fi
cd ..

# Run Dart Implementation  
echo "Running Dart Implementation..."
cd hello-edge-tts-dart
if command -v dart >/dev/null 2>&1; then
    dart pub get >/dev/null 2>&1
    if dart run bin/multilingual_demo.dart; then
        dart_success=1
        echo "✓ Dart completed successfully"
    else
        echo "✗ Dart failed"
    fi
else
    echo "✗ Dart not found"
fi
cd ..

# Run Java Implementation
echo "Running Java Implementation..."
cd hello-edge-tts-java
if command -v java >/dev/null 2>&1 && command -v mvn >/dev/null 2>&1; then
    mvn compile >/dev/null 2>&1
    if java -cp target/classes:$(mvn dependency:build-classpath -q -Dmdep.outputFile=/dev/stdout) com.example.hellotts.MultilingualDemo; then
        java_success=1
        echo "✓ Java completed successfully"
    else
        echo "✗ Java failed"
    fi
else
    echo "✗ Java or Maven not found"
fi
cd ..

# Run Rust Implementation
echo "Running Rust Implementation..."
cd hello-edge-tts-rust
if command -v cargo >/dev/null 2>&1; then
    cargo build --example multilingual_demo >/dev/null 2>&1
    if cargo run --example multilingual_demo; then
        rust_success=1
        echo "✓ Rust completed successfully"
    else
        echo "✗ Rust failed"
    fi
else
    echo "✗ Rust not found"
fi
cd ..

# Summary
echo
echo "Summary"
echo "======="
total=$((python_success + dart_success + java_success + rust_success))
echo "Python: $([[ $python_success -eq 1 ]] && echo "✓" || echo "✗")"
echo "Dart:   $([[ $dart_success -eq 1 ]] && echo "✓" || echo "✗")"
echo "Java:   $([[ $java_success -eq 1 ]] && echo "✓" || echo "✗")"
echo "Rust:   $([[ $rust_success -eq 1 ]] && echo "✓" || echo "✗")"
echo "Total:  $total/4 implementations successful"

# Check generated files
echo
echo "Generated Files:"
echo "Python: $(find hello-edge-tts-python/output -name "multilingual_*.mp3" 2>/dev/null | wc -l) files"
echo "Dart:   $(find hello-edge-tts-dart/output -name "multilingual_*.mp3" 2>/dev/null | wc -l) files"
echo "Java:   $(find hello-edge-tts-java -name "multilingual_*.mp3" 2>/dev/null | wc -l) files"
echo "Rust:   $(find hello-edge-tts-rust -name "multilingual_*.mp3" 2>/dev/null | wc -l) files"

if [ $total -gt 0 ]; then
    echo "Demo completed successfully!"
    exit 0
else
    echo "All implementations failed!"
    exit 1
fi