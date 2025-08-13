#!/bin/bash

# Python TTS Client Build Script

set -e

echo "🐍 Building Python TTS Client"
echo "=============================="

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3.8 or later."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "✅ Found Python $PYTHON_VERSION"

# Create virtual environment
if [ ! -d ".venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source .venv/bin/activate

# Upgrade pip
echo "⬆️  Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "📥 Installing dependencies..."
pip install -r requirements.txt

# Run syntax check
echo "🔍 Running syntax check..."
python -m py_compile *.py

# Run basic import test
echo "🧪 Testing imports..."
python -c "
import hello_tts
import tts_client
import audio_player
import voice
import config
import ssml_utils
print('✅ All imports successful')
"

# Create distribution package (optional)
if command -v build &> /dev/null; then
    echo "📦 Creating distribution package..."
    python -m build
fi

deactivate

echo "✅ Python build completed successfully!"
echo "💡 To run: cd python && source .venv/bin/activate && python hello_tts.py"