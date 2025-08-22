# Multilingual Edge TTS Demo

Generates audio files for 12 languages using 4 programming implementations (Python, Dart, Java, Rust).

## Languages

1. 🇨🇳 Chinese: 你好，我可以为你朗读。
2. 🇺🇸 English: Hello, I can read for you.
3. 🇩🇪 German: Hallo, ich kann es für dich vorlesen.
4. 🇫🇷 French: Bonjour, je peux vous lire ce texte.
5. 🇪🇸 Spanish: Hola, puedo leer esto para ti.
6. 🇮🇹 Italian: Ciao, posso leggerlo per te.
7. 🇷🇺 Russian: Здравствуйте, я могу прочитать это для вас.
8. 🇬🇷 Greek: Γεια σας, μπορώ να το διαβάσω για εσάς.
9. 🇸🇦 Arabic: مرحبًا، أستطيع قراءة هذا لك.
10. 🇮🇳 Hindi: नमस्ते, मैं आपके लिए इसे पढ़ कर सुना सकता हूँ.
11. 🇯🇵 Japanese: こんにちは、これを読み上げることができます。
12. 🇰🇷 Korean: 안녕하세요, 제가 읽어 드릴 수 있습니다.

## Quick Start

**Run All Implementations:**

Linux/macOS:
```bash
./run_multilingual_demo.sh
```

Windows:
```batch
run_multilingual_demo.bat
```

**Run Individual Implementations:**

```bash
# Python
cd hello-edge-tts-python && python3 multilingual_demo.py

# Dart  
cd hello-edge-tts-dart && dart run bin/multilingual_demo.dart

# Java
cd hello-edge-tts-java && java -cp target/classes:$(mvn dependency:build-classpath -q -Dmdep.outputFile=/dev/stdout) com.example.hellotts.MultilingualDemo

# Rust
cd hello-edge-tts-rust && cargo run --example multilingual_demo
```

## Output

Each implementation generates 12 audio files (one per language):
- **Python**: `hello-edge-tts-python/output/multilingual_{lang}_python_{timestamp}.mp3`
- **Dart**: `hello-edge-tts-dart/output/multilingual_{lang}_dart_{timestamp}.mp3`
- **Java**: `hello-edge-tts-java/multilingual_{lang}_java_{timestamp}.mp3`
- **Rust**: `hello-edge-tts-rust/multilingual_{lang}_rust_{timestamp}.mp3`

Total: 48 audio files (12 languages × 4 implementations)

## Requirements

- **Python**: Python 3.7+
- **Dart**: Dart SDK 2.17+
- **Java**: Java 11+, Maven 3.6+
- **Rust**: Rust 1.60+, Cargo

## Configuration

Language settings are in `shared/multilingual_demo_config.json` with voice configurations and custom sentences for each language.