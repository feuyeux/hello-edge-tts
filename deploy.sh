#!/bin/bash

# Hello Edge TTS - Deployment Script
# This script packages and deploys all language implementations

set -e

echo "🚀 Hello Edge TTS - Deployment Script"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Configuration
VERSION=${1:-"1.0.0"}
DIST_DIR="dist"
ARCHIVE_NAME="hello-edge-tts-v${VERSION}"

print_status "Deploying Hello Edge TTS version $VERSION"

# Clean and create distribution directory
if [ -d "$DIST_DIR" ]; then
    print_status "Cleaning existing distribution directory..."
    rm -rf "$DIST_DIR"
fi

mkdir -p "$DIST_DIR"

# Build all implementations
print_status "Building all implementations..."
./build.sh

# Package Python implementation
print_status "Packaging Python implementation..."
mkdir -p "$DIST_DIR/python"
cp -r python/*.py python/requirements.txt python/README.md "$DIST_DIR/python/"
if [ -d "python/.venv" ]; then
    print_warning "Skipping virtual environment directory"
fi

# Package Dart implementation
print_status "Packaging Dart implementation..."
mkdir -p "$DIST_DIR/dart"
cp -r dart/lib dart/bin dart/pubspec.yaml dart/README.md "$DIST_DIR/dart/"
if [ -f "dart/bin/hello_tts" ]; then
    cp dart/bin/hello_tts "$DIST_DIR/dart/bin/"
fi

# Package Rust implementation
print_status "Packaging Rust implementation..."
mkdir -p "$DIST_DIR/rust"
cp -r rust/src rust/examples rust/Cargo.toml rust/README.md "$DIST_DIR/rust/"
if [ -f "rust/target/release/hello-edge-tts" ]; then
    mkdir -p "$DIST_DIR/rust/bin"
    cp rust/target/release/hello-edge-tts "$DIST_DIR/rust/bin/"
fi

# Package Java implementation
print_status "Packaging Java implementation..."
mkdir -p "$DIST_DIR/java"
cp -r java/src java/pom.xml java/README.md "$DIST_DIR/java/"
if [ -f "java/target/hello-tts-1.0-SNAPSHOT-jar-with-dependencies.jar" ]; then
    mkdir -p "$DIST_DIR/java/bin"
    cp java/target/hello-tts-1.0-SNAPSHOT-jar-with-dependencies.jar "$DIST_DIR/java/bin/hello-tts.jar"
fi

# Copy shared resources
print_status "Copying shared resources..."
cp -r shared "$DIST_DIR/"
cp -r tutorials "$DIST_DIR/"
cp -r examples "$DIST_DIR/"
cp README.md LICENSE* "$DIST_DIR/" 2>/dev/null || true

# Copy build scripts
print_status "Copying build scripts..."
cp build.sh build.bat "$DIST_DIR/"
cp python/build.sh "$DIST_DIR/python/"
cp dart/build.sh "$DIST_DIR/dart/"
cp rust/build.sh "$DIST_DIR/rust/"
cp java/build.sh "$DIST_DIR/java/"

# Create installation script
print_status "Creating installation script..."
cat > "$DIST_DIR/install.sh" << 'EOF'
#!/bin/bash

echo "🚀 Hello Edge TTS - Installation Script"
echo "======================================="

# Make build scripts executable
chmod +x build.sh build.bat
chmod +x python/build.sh
chmod +x dart/build.sh
chmod +x rust/build.sh
chmod +x java/build.sh

echo "✅ Installation completed!"
echo ""
echo "Next steps:"
echo "1. Choose your preferred language implementation:"
echo "   - Python: cd python && ./build.sh"
echo "   - Dart: cd dart && ./build.sh"
echo "   - Rust: cd rust && ./build.sh"
echo "   - Java: cd java && ./build.sh"
echo ""
echo "2. Or build all implementations:"
echo "   ./build.sh"
echo ""
echo "3. Check the tutorials/ directory for usage examples"
EOF

chmod +x "$DIST_DIR/install.sh"

# Create version info
print_status "Creating version info..."
cat > "$DIST_DIR/VERSION" << EOF
Hello Edge TTS
Version: $VERSION
Build Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Git Commit: $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

Language Implementations:
- Python: Text-to-speech with asyncio support
- Dart: Cross-platform TTS with native compilation
- Rust: High-performance TTS with zero-cost abstractions
- Java: Enterprise-ready TTS with Maven build system

For more information, see README.md
EOF

# Create checksums
print_status "Creating checksums..."
cd "$DIST_DIR"
find . -type f -exec sha256sum {} \; > CHECKSUMS.sha256
cd ..

# Create archive
print_status "Creating distribution archive..."
tar -czf "${ARCHIVE_NAME}.tar.gz" -C "$DIST_DIR" .
zip -r "${ARCHIVE_NAME}.zip" "$DIST_DIR" > /dev/null

# Generate deployment summary
print_status "Generating deployment summary..."
cat > "deployment-summary.txt" << EOF
Hello Edge TTS Deployment Summary
=================================

Version: $VERSION
Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

Distribution Files:
- ${ARCHIVE_NAME}.tar.gz ($(du -h "${ARCHIVE_NAME}.tar.gz" | cut -f1))
- ${ARCHIVE_NAME}.zip ($(du -h "${ARCHIVE_NAME}.zip" | cut -f1))

Directory Structure:
$(tree "$DIST_DIR" 2>/dev/null || find "$DIST_DIR" -type d | head -20)

File Count: $(find "$DIST_DIR" -type f | wc -l)
Total Size: $(du -sh "$DIST_DIR" | cut -f1)

Checksums: See CHECKSUMS.sha256 in the distribution

Installation:
1. Extract the archive
2. Run ./install.sh
3. Follow the build instructions for your preferred language

EOF

print_success "Deployment completed successfully!"
echo ""
echo "📦 Distribution files:"
echo "  - ${ARCHIVE_NAME}.tar.gz"
echo "  - ${ARCHIVE_NAME}.zip"
echo "  - deployment-summary.txt"
echo ""
echo "📁 Distribution directory: $DIST_DIR"
echo ""
echo "🔍 To verify integrity:"
echo "  cd $DIST_DIR && sha256sum -c CHECKSUMS.sha256"