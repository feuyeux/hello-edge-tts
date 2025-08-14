@echo off
echo ==============================================
echo  Final Audio Playback Test
echo ==============================================
echo Testing the fixed internal audio players...
echo.
echo Please listen carefully for the audio output!
echo.

REM Test Dart
echo [1/2] Testing Dart internal audio player...
cd hello-edge-tts-dart
.\bin\hello_tts.exe --text "Dart audio is working correctly now!" --voice "en-US-JennyNeural"
echo.
echo Did you hear the Dart audio? [Press any key to continue]
pause >nul
cd ..

REM Test Java  
echo [2/2] Testing Java internal audio player...
cd hello-edge-tts-java
call mvn exec:java "-Dexec.mainClass=com.example.hellotts.HelloTTS" "-Dexec.args=--text 'Java audio is working correctly now!' --voice en-US-AriaNeural" -q
echo.
echo Did you hear the Java audio? [Press any key to continue]  
pause >nul
cd ..

echo.
echo ==============================================
echo Test completed!
echo.
echo If you heard both audio outputs:
echo ✅ Internal audio playback is now working correctly!
echo.
echo If you didn't hear the audio:
echo ❌ There may still be an issue with:
echo   - System volume settings
echo   - Audio device configuration  
echo   - Windows audio services
echo ==============================================
pause
