#!/bin/bash

cd hello-edge-tts-dart/
sh build.sh
dart run bin/main.dart --text 'Hello from Dart!' --voice 'en-US-JennyNeural'

cd ../hello-edge-tts-python/
sh build.sh
source .venv/bin/activate
python hello_tts.py --text 'Hello from Python!' --voice 'en-US-JennyNeural'

cd ../hello-edge-tts-java/    
sh build.sh
mvn exec:java -Dexec.mainClass='com.example.hellotts.HelloTTS' -Dexec.args='--text '\''Hello from Java 21!'\'' --voice en-US-GuyNeural'

cd ../hello-edge-tts-rust/
sh build.sh
cargo run -- --text 'Hello from Rust!' --voice 'en-US-AriaNeural'


# shared\language_test_config.json