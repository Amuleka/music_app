# 🎵 Music Idea Capture App

A lightweight Flutter app designed for musicians and producers to **quickly capture song ideas** on the go.  
Instead of losing creative sparks, you can record audio snippets instantly, store them with metadata, and build a library of musical sketches.

---

## 🚀 Features
- 🎙️ Record audio ideas with one tap  
- ⏱️ Display recording time and elapsed duration  
- 💾 Save audio files locally with unique IDs  
- 🌌 Animated backgrounds for a creative vibe  
- 🔒 Handles microphone permissions gracefully  
- 🗂️ Organize and store multiple recordings for later review  

---

## 📦 Packages Used
This project uses several Flutter/Dart packages to handle recording, permissions, and storage:

- [`flutter_sound`](https://pub.dev/packages/flutter_sound) → Audio recording/playback  
- [`permission_handler`](https://pub.dev/packages/permission_handler) → Requesting microphone/storage permissions  
- [`path_provider`](https://pub.dev/packages/path_provider) → Accessing device storage for saving files  
- [`uuid`](https://pub.dev/packages/uuid) → Generating unique IDs for each recording/idea  

---

## 🛠️ Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Android Studio / Xcode (for emulator or device testing)

### Installation
```bash
# Clone the repo
git clone https://github.com/your-username/music-idea-app.git
cd music-idea-app

# Get dependencies
flutter pub get

# Run on device
flutter run
