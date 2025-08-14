@echo off
setlocal enabledelayedexpansion

echo Hello Edge TTS - Multi-language Run Script for Windows
echo ================================================

REM Parse command line arguments
set "language=english"
set "voice_gender=female"

:parse_args
if "%~1"=="" goto :args_parsed
if "%~1"=="-l" set "language=%~2" && shift && shift && goto :parse_args
if "%~1"=="--language" set "language=%~2" && shift && shift && goto :parse_args
if "%~1"=="-g" set "voice_gender=%~2" && shift && shift && goto :parse_args
if "%~1"=="--gender" set "voice_gender=%~2" && shift && shift && goto :parse_args
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help
shift
goto :parse_args

:args_parsed

REM Load configuration from shared\language_test_config.json
echo [INFO] Loading configuration for language: %language%

REM Use PowerShell script to parse JSON and get the configuration
for /f "delims=" %%i in ('powershell -ExecutionPolicy Bypass -File "scripts\get-config.ps1" -Language "%language%" -Gender "%voice_gender%"') do (
    set "config_line=%%i"
)

REM Parse the configuration line
for /f "tokens=1,2,3 delims=|" %%a in ("!config_line!") do (
    set "voice=%%a"
    set "text=%%b"
    set "language_name=%%c"
)

echo [INFO] Using voice: !voice!
echo [INFO] Text: !text!
echo [INFO] Language: !language_name!
echo.

set "failed_runs="

REM Run Dart implementation
echo [INFO] Running Dart implementation...
cd hello-edge-tts-dart

REM Check if Dart executable exists
if not exist "bin\hello_tts.exe" (
    echo [INFO] Dart executable not found, building first...
    call build.sh
    if !errorlevel! neq 0 (
        echo [ERROR] Dart build failed
        set "failed_runs=!failed_runs! Dart"
        cd ..
        goto :python_run
    )
)

REM Run Dart application with configuration
echo [INFO] Executing Dart application...
bin\hello_tts.exe --text "!text!" --voice "!voice!"
if !errorlevel! neq 0 (
    echo [ERROR] Dart execution failed
    set "failed_runs=!failed_runs! Dart"
)

cd ..

:python_run
REM Run Python implementation
echo [INFO] Running Python implementation...
cd hello-edge-tts-python

REM Check if virtual environment exists
if not exist ".venv" (
    echo [INFO] Virtual environment not found, building first...
    call build.sh
    if !errorlevel! neq 0 (
        echo [ERROR] Python build failed
        set "failed_runs=!failed_runs! Python"
        cd ..
        goto :java_run
    )
)

REM Activate virtual environment - check both Windows and Unix style
if exist ".venv\Scripts\activate.bat" (
    call .venv\Scripts\activate.bat
) else if exist ".venv\bin\activate" (
    REM For WSL/Git Bash style venv on Windows
    call .venv\bin\activate
) else (
    echo [ERROR] Virtual environment activation script not found
    set "failed_runs=!failed_runs! Python"
    cd ..
    goto :java_run
)

REM Run Python application with configuration
echo [INFO] Executing Python application...
python hello_tts.py --text "!text!" --voice "!voice!"
if !errorlevel! neq 0 (
    echo [ERROR] Python execution failed
    set "failed_runs=!failed_runs! Python"
)

call deactivate
cd ..

:java_run
REM Run Java implementation
echo [INFO] Running Java implementation...
cd hello-edge-tts-java

REM Check if jar file exists
if not exist "target\hello-edge-tts-1.0-SNAPSHOT.jar" (
    echo [INFO] Java jar not found, building first...
    call build.sh
    if !errorlevel! neq 0 (
        echo [ERROR] Java build failed
        set "failed_runs=!failed_runs! Java"
        cd ..
        goto :rust_run
    )
)

REM Run Java application with configuration
echo [INFO] Executing Java application...
call mvn exec:java -Dexec.mainClass="com.example.hellotts.HelloTTS" -Dexec.args="--text '!text!' --voice !voice!"
if !errorlevel! neq 0 (
    echo [ERROR] Java execution failed
    set "failed_runs=!failed_runs! Java"
)

cd ..

:rust_run
REM Run Rust implementation
echo [INFO] Running Rust implementation...
cd hello-edge-tts-rust

REM Check if Rust executable exists
if not exist "target\release\hello-edge-tts.exe" (
    echo [INFO] Rust executable not found, building first...
    call build.sh
    if !errorlevel! neq 0 (
        echo [ERROR] Rust build failed
        set "failed_runs=!failed_runs! Rust"
        cd ..
        goto :summary
    )
)

REM Run Rust application with configuration
echo [INFO] Executing Rust application...
cargo run -- speak --text "!text!" --voice "!voice!" --play
if !errorlevel! neq 0 (
    echo [ERROR] Rust execution failed
    set "failed_runs=!failed_runs! Rust"
)

cd ..

:summary
echo.
echo ================================================
if "!failed_runs!"=="" (
    echo [SUCCESS] All applications ran successfully!
    echo [SUCCESS] Language: !language_name!
    echo [SUCCESS] Voice: !voice!
) else (
    echo [ERROR] Some applications failed to run:!failed_runs!
    exit /b 1
)

echo.
echo Configuration loaded from shared\language_test_config_clean.json

endlocal
goto :eof

:show_help
echo.
echo Usage: %0 [options]
echo.
echo Options:
echo   -l, --language LANG    Language to use (chinese, french, russian, german, etc.)
echo   -g, --gender GENDER    Voice gender (male/female, default: female)
echo   -h, --help            Show this help message
echo.
echo Available languages:
echo   chinese, french, russian, german, arabic, hindi, greek, japanese, korean
echo.
echo Examples:
echo   %0 --language chinese --gender male
echo   %0 -l french -g female
echo   %0 --language japanese
echo.
goto :eof
