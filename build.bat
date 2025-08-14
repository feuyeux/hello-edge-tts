@echo off
setlocal enabledelayedexpansion

echo Hello Edge TTS - Multi-language Build Script for Windows
echo ================================================

set "failed_builds="

REM Check for Python
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python not found. Please install Python 3.8 or later.
    set "failed_builds=!failed_builds! Python"
    goto :skip_python
)

REM Build Python implementation
echo [INFO] Building Python implementation...
cd hello-edge-tts-python

REM Create virtual environment if it doesn't exist
if not exist ".venv" (
    echo [INFO] Creating Python virtual environment...
    python -m venv .venv
)

REM For WSL/Unix-style venv, create Scripts directory and batch files if missing
if exist ".venv\bin" if not exist ".venv\Scripts" (
    echo [INFO] Creating Windows-compatible Scripts directory...
    mkdir ".venv\Scripts"
    copy ".venv\bin\python" ".venv\Scripts\python.exe" >nul 2>&1
    copy ".venv\bin\pip" ".venv\Scripts\pip.exe" >nul 2>&1
    echo @echo off > ".venv\Scripts\activate.bat"
    echo set "VIRTUAL_ENV=%CD%\.venv" >> ".venv\Scripts\activate.bat"
    echo set "PATH=%CD%\.venv\Scripts;%PATH%" >> ".venv\Scripts\activate.bat"
)

REM Activate virtual environment - check both Windows and Unix style
if exist ".venv\Scripts\activate.bat" (
    call .venv\Scripts\activate.bat
) else (
    echo [ERROR] Virtual environment activation script not found
    set "failed_builds=!failed_builds! Python"
    goto :skip_python
)

REM Upgrade pip
python -m pip install --upgrade pip

REM Install dependencies
echo [INFO] Installing Python dependencies...
pip install -r requirements.txt

REM Run basic syntax check
echo [INFO] Running Python syntax check...
for %%f in (*.py) do (
    python -m py_compile "%%f"
    if !errorlevel! neq 0 (
        echo [ERROR] Python syntax check failed for %%f
        set "failed_builds=!failed_builds! Python"
        goto :skip_python_success
    )
)

call deactivate
cd ..
echo [SUCCESS] Python build completed successfully!
goto :dart_build

:skip_python_success
call deactivate
cd ..
goto :dart_build

:skip_python

:dart_build
REM Check for Dart
where dart >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Dart SDK not found. Please install Dart SDK 3.0 or later.
    set "failed_builds=!failed_builds! Dart"
    goto :rust_build
)

REM Build Dart implementation
echo [INFO] Building Dart implementation...
cd hello-edge-tts-dart

REM Get dependencies
echo [INFO] Getting Dart dependencies...
dart pub get

REM Analyze code
echo [INFO] Analyzing Dart code...
dart analyze
if %errorlevel% neq 0 (
    echo [ERROR] Dart analysis failed
    set "failed_builds=!failed_builds! Dart"
    cd ..
    goto :rust_build
)

REM Compile to executable
echo [INFO] Compiling Dart application...
dart compile exe bin/main.dart -o bin/hello_tts.exe
if %errorlevel% neq 0 (
    echo [ERROR] Dart compilation failed
    set "failed_builds=!failed_builds! Dart"
    cd ..
    goto :rust_build
)

cd ..
echo [SUCCESS] Dart build completed successfully!

:rust_build
REM Check for Rust/Cargo
where cargo >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Rust/Cargo not found. Please install Rust 1.70 or later.
    set "failed_builds=!failed_builds! Rust"
    goto :java_build
)

REM Build Rust implementation
echo [INFO] Building Rust implementation...
cd hello-edge-tts-rust

REM Build in release mode
echo [INFO] Building Rust project in release mode...
cargo build --release
if %errorlevel% neq 0 (
    echo [ERROR] Rust build failed
    set "failed_builds=!failed_builds! Rust"
    cd ..
    goto :java_build
)

REM Run tests
echo [INFO] Running Rust tests...
cargo test
if %errorlevel% neq 0 (
    echo [ERROR] Rust tests failed
    set "failed_builds=!failed_builds! Rust"
    cd ..
    goto :java_build
)

cd ..
echo [SUCCESS] Rust build completed successfully!

:java_build
REM Check for Maven
where mvn >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Maven not found. Please install Apache Maven 3.6 or later.
    set "failed_builds=!failed_builds! Java"
    goto :summary
)

REM Build Java implementation
echo [INFO] Building Java implementation...
cd hello-edge-tts-java

REM Clean and compile
echo [INFO] Cleaning and compiling Java project...
call mvn clean compile
if %errorlevel% neq 0 (
    echo [ERROR] Java compilation failed
    set "failed_builds=!failed_builds! Java"
    cd ..
    goto :summary
)

REM Run tests
echo [INFO] Running Java tests...
call mvn test
if %errorlevel% neq 0 (
    echo [ERROR] Java tests failed
    set "failed_builds=!failed_builds! Java"
    cd ..
    goto :summary
)

REM Package
echo [INFO] Packaging Java application...
call mvn package
if %errorlevel% neq 0 (
    echo [ERROR] Java packaging failed
    set "failed_builds=!failed_builds! Java"
    cd ..
    goto :summary
)

cd ..
echo [SUCCESS] Java build completed successfully!

:summary
echo.
echo ================================================
if "!failed_builds!"=="" (
    echo [SUCCESS] All builds completed successfully!
) else (
    echo [ERROR] Some builds failed:!failed_builds!
    exit /b 1
)

endlocal
