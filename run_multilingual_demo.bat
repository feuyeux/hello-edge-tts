@echo off
REM Multilingual Edge TTS Demo - Master Script
REM Generates audio files for 12 languages using 4 programming implementations

setlocal enabledelayedexpansion

echo Multilingual Edge TTS Demo
echo =========================
echo Generating audio for 12 languages with 4 implementations
echo.

REM Check config file
if not exist "shared\multilingual_demo_config.json" (
    echo ERROR: Configuration file not found: shared\multilingual_demo_config.json
    exit /b 1
)

REM Initialize counters
set python_success=0
set dart_success=0
set java_success=0
set rust_success=0

REM Run Python Implementation
echo Running Python Implementation...
cd hello-edge-tts-python
where python >nul 2>nul
if %errorlevel% equ 0 (
    python multilingual_demo.py
    if %errorlevel% equ 0 (
        set python_success=1
        echo + Python completed successfully
    ) else (
        echo - Python failed
    )
) else (
    echo - Python not found
)
cd ..

REM Run Dart Implementation
echo Running Dart Implementation...
cd hello-edge-tts-dart
where dart >nul 2>nul
if %errorlevel% equ 0 (
    dart pub get >nul 2>nul
    dart run bin/multilingual_demo.dart
    if %errorlevel% equ 0 (
        set dart_success=1
        echo + Dart completed successfully
    ) else (
        echo - Dart failed
    )
) else (
    echo - Dart not found
)
cd ..

REM Run Java Implementation
echo Running Java Implementation...
cd hello-edge-tts-java
where java >nul 2>nul
if %errorlevel% equ 0 (
    where mvn >nul 2>nul
    if %errorlevel% equ 0 (
        mvn compile >nul 2>nul
        java -cp target/classes;target/dependency/* com.example.hellotts.MultilingualDemo
        if %errorlevel% equ 0 (
            set java_success=1
            echo + Java completed successfully
        ) else (
            echo - Java failed
        )
    ) else (
        echo - Maven not found
    )
) else (
    echo - Java not found
)
cd ..

REM Run Rust Implementation
echo Running Rust Implementation...
cd hello-edge-tts-rust
where cargo >nul 2>nul
if %errorlevel% equ 0 (
    cargo build --example multilingual_demo >nul 2>nul
    cargo run --example multilingual_demo
    if %errorlevel% equ 0 (
        set rust_success=1
        echo + Rust completed successfully
    ) else (
        echo - Rust failed
    )
) else (
    echo - Rust not found
)
cd ..

REM Summary
echo.
echo Summary
echo =======
set /a total=!python_success! + !dart_success! + !java_success! + !rust_success!

if !python_success! equ 1 (echo Python: +) else (echo Python: -)
if !dart_success! equ 1 (echo Dart:   +) else (echo Dart:   -)
if !java_success! equ 1 (echo Java:   +) else (echo Java:   -)
if !rust_success! equ 1 (echo Rust:   +) else (echo Rust:   -)
echo Total:  !total!/4 implementations successful

echo.
echo Generated Files:
for /f %%i in ('dir /s /b hello-edge-tts-python\output\multilingual_*.mp3 2^>nul ^| find /c /v ""') do echo Python: %%i files
for /f %%i in ('dir /s /b hello-edge-tts-dart\output\multilingual_*.mp3 2^>nul ^| find /c /v ""') do echo Dart:   %%i files
for /f %%i in ('dir /s /b hello-edge-tts-java\multilingual_*.mp3 2^>nul ^| find /c /v ""') do echo Java:   %%i files
for /f %%i in ('dir /s /b hello-edge-tts-rust\multilingual_*.mp3 2^>nul ^| find /c /v ""') do echo Rust:   %%i files

if !total! gtr 0 (
    echo Demo completed successfully!
    exit /b 0
) else (
    echo All implementations failed!
    exit /b 1
)