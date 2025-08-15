#!/bin/bash

echo "Hello Edge TTS - Multi-language Run Script for Linux/macOS"
echo "================================================"

# Default values
language="english"
voice_gender="female"

# Function to show help
show_help() {
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -l, --language LANG    Language to use (chinese, french, russian, german, etc.)"
    echo "  -g, --gender GENDER    Voice gender (male/female, default: female)"
    echo "  -h, --help            Show this help message"
    echo
    echo "Available languages:"
    echo "  chinese, french, russian, german, arabic, hindi, greek, japanese, korean"
    echo
    echo "Examples:"
    echo "  $0 --language chinese --gender male"
    echo "  $0 -l french -g female"
    echo "  $0 --language japanese"
    echo
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--language)
            language="$2"
            shift 2
            ;;
        -g|--gender)
            voice_gender="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Function to get configuration from JSON
get_config() {
    local lang="$1"
    local gender="$2"
    local config_file="shared/language_test_config.json"
    
    if [[ ! -f "$config_file" ]]; then
        echo "ERROR: Configuration file not found: $config_file"
        exit 1
    fi
    
    # Use python to parse JSON (more reliable than jq which might not be installed)
    python3 -c "
import json
import sys

try:
    with open('$config_file', 'r', encoding='utf-8') as f:
        config = json.load(f)
    
    if '$lang' not in config:
        print('ERROR: Language \"$lang\" not found in configuration', file=sys.stderr)
        sys.exit(1)
    
    lang_config = config['$lang']
    voice = lang_config['${gender}_voice'] if '$gender' in ['male', 'female'] else lang_config['female_voice']
    text = lang_config['test_text']
    name = lang_config['name']
    
    print(f'{voice}|{text}|{name}')
except Exception as e:
    print(f'ERROR: Failed to parse configuration: {e}', file=sys.stderr)
    sys.exit(1)
"
}

echo "[INFO] Loading configuration for language: $language"

# Get configuration
config_line=$(get_config "$language" "$voice_gender")
if [[ $? -ne 0 ]]; then
    echo "$config_line"
    exit 1
fi

# Parse the configuration line
IFS='|' read -r voice text language_name <<< "$config_line"

echo "[INFO] Using voice: $voice"
echo "[INFO] Text: $text"
echo "[INFO] Language: $language_name"
echo

failed_runs=""

# Run Dart implementation
echo "[INFO] Running Dart implementation..."
cd hello-edge-tts-dart

# Use dart run directly instead of building executable
echo "[INFO] Executing Dart application..."
dart run bin/main.dart --text "$text" --voice "$voice"
if [[ $? -ne 0 ]]; then
    echo "[ERROR] Dart execution failed"
    failed_runs="$failed_runs Dart"
fi
cd ..

# Run Python implementation
echo "[INFO] Running Python implementation..."
cd hello-edge-tts-python

# Check if virtual environment exists
if [[ ! -d ".venv" ]]; then
    echo "[INFO] Virtual environment not found, building first..."
    bash build.sh
    if [[ $? -ne 0 ]]; then
        echo "[ERROR] Python build failed"
        failed_runs="$failed_runs Python"
        cd ..
    else
        echo "[INFO] Executing Python application..."
        source .venv/bin/activate
        python hello_tts.py --text "$text" --voice "$voice"
        if [[ $? -ne 0 ]]; then
            echo "[ERROR] Python execution failed"
            failed_runs="$failed_runs Python"
        fi
        deactivate
        cd ..
    fi
else
    echo "[INFO] Executing Python application..."
    source .venv/bin/activate
    python hello_tts.py --text "$text" --voice "$voice"
    if [[ $? -ne 0 ]]; then
        echo "[ERROR] Python execution failed"
        failed_runs="$failed_runs Python"
    fi
    deactivate
    cd ..
fi

# Run Java implementation
echo "[INFO] Running Java implementation..."
cd hello-edge-tts-java

# Check if jar file exists
if [[ ! -f "target/hello-edge-tts-1.0-SNAPSHOT.jar" ]]; then
    echo "[INFO] Java jar not found, building first..."
    bash build.sh
    if [[ $? -ne 0 ]]; then
        echo "[ERROR] Java build failed"
        failed_runs="$failed_runs Java"
        cd ..
    else
        echo "[INFO] Executing Java application..."
        mvn exec:java -Dexec.mainClass="com.example.hellotts.HelloTTS" -Dexec.args="--text '$text' --voice $voice"
        if [[ $? -ne 0 ]]; then
            echo "[ERROR] Java execution failed"
            failed_runs="$failed_runs Java"
        fi
        cd ..
    fi
else
    echo "[INFO] Executing Java application..."
    mvn exec:java -Dexec.mainClass="com.example.hellotts.HelloTTS" -Dexec.args="--text '$text' --voice $voice"
    if [[ $? -ne 0 ]]; then
        echo "[ERROR] Java execution failed"
        failed_runs="$failed_runs Java"
    fi
    cd ..
fi

# Run Rust implementation
echo "[INFO] Running Rust implementation..."
cd hello-edge-tts-rust

# Check if Rust executable exists
if [[ ! -f "target/release/hello-edge-tts" ]]; then
    echo "[INFO] Rust executable not found, building first..."
    bash build.sh
    if [[ $? -ne 0 ]]; then
        echo "[ERROR] Rust build failed"
        failed_runs="$failed_runs Rust"
        cd ..
    else
        echo "[INFO] Executing Rust application..."
        cargo run -- speak --text "$text" --voice "$voice" --play
        if [[ $? -ne 0 ]]; then
            echo "[ERROR] Rust execution failed"
            failed_runs="$failed_runs Rust"
        fi
        cd ..
    fi
else
    echo "[INFO] Executing Rust application..."
    cargo run -- speak --text "$text" --voice "$voice" --play
    if [[ $? -ne 0 ]]; then
        echo "[ERROR] Rust execution failed"
        failed_runs="$failed_runs Rust"
    fi
    cd ..
fi

# Summary
echo
echo "================================================"
if [[ -z "$failed_runs" ]]; then
    echo "[SUCCESS] All applications ran successfully!"
    echo "[SUCCESS] Language: $language_name"
    echo "[SUCCESS] Voice: $voice"
else
    echo "[ERROR] Some applications failed to run:$failed_runs"
    exit 1
fi

echo
echo "Configuration loaded from shared/language_test_config.json"