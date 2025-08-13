#!/bin/bash

# Java TTS Client Build Script

set -e

echo "☕ Building Java TTS Client"
echo "==========================="

# Check Java version
if ! command -v java &> /dev/null; then
    echo "❌ Java not found. Please install Java 11 or later."
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
echo "✅ Found Java $JAVA_VERSION"

# Check Maven version
if ! command -v mvn &> /dev/null; then
    echo "❌ Maven not found. Please install Apache Maven 3.6 or later."
    exit 1
fi

MAVEN_VERSION=$(mvn --version | head -n1 | cut -d' ' -f3)
echo "✅ Found Maven $MAVEN_VERSION"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
mvn clean

# Validate project
echo "🔍 Validating project..."
mvn validate

# Compile source code
echo "🔨 Compiling source code..."
mvn compile

# Compile test code
echo "🧪 Compiling test code..."
mvn test-compile

# Run tests
echo "🧪 Running tests..."
mvn test

# Package application
echo "📦 Packaging application..."
mvn package

# Install to local repository
echo "📥 Installing to local repository..."
mvn install

# Generate site documentation
echo "📚 Generating site documentation..."
mvn site

# Create executable JAR with dependencies
echo "🚀 Creating executable JAR..."
mvn assembly:single

echo "✅ Java build completed successfully!"
echo "💡 JAR file: ./target/hello-tts-1.0-SNAPSHOT.jar"
echo "💡 Executable JAR: ./target/hello-tts-1.0-SNAPSHOT-jar-with-dependencies.jar"
echo "💡 To run: java -jar target/hello-tts-1.0-SNAPSHOT-jar-with-dependencies.jar"
echo "💡 Documentation: ./target/site/index.html"