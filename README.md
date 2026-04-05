# TDD - Todo & Diary Cross-Platform App

![TDD Logo](https://img.shields.io/badge/TDD-Todo%20%26%20Diary-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.41.5-blue)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Web-green)

A feature-rich, cross-platform To-Do and Diary application that works on both desktop (Windows) and mobile (Android). It enables seamless data synchronization via file sync and offers powerful customization features.

## ✨ Key Features

### 📝 To-Do Management

* Create, edit, and delete tasks
* Mark tasks as complete/incomplete
* Set descriptions
* Smart sorting and filtering

### 📔 Diary Logging

* Rich-text diary editor
* Mood tags (😊 Happy, 😢 Sad, 🤩 Excited, etc.)
* Tagging, categorization, and search
* Favorite important entries

### 🎨 Powerful Customization

* **Font Customization**: Supports multiple font choices and downloads
* **Theme Customization**: Rich color theme selector
* **UI Customization**: Adjust font size, spacing, and layout
* **Personalization**: Customize app name and interface elements

### 🔄 Cross-Platform Data Sync

* Automatically detect sync folders
* One-click data synchronization
* Multi-device data sync
* Backup and restore data

### 🔒 Data Security

* Local encrypted data storage
* Secure synchronization mechanism
* Data export/import functionality

## 📱 Supported Platforms

| Platform | Status             | Installation Method                       |
| -------- | ------------------ | ----------------------------------------- |
| Android  | ✅ Fully Supported  | APK installation or in development mode   |
| Windows  | ✅ Fully Supported  | EXE file or in development mode           |
| Web      | ⚠️ Limited Support | Browser access (limited desktop features) |

## 🚀 Quick Start

### 1. Install Flutter Environment

Make sure Flutter SDK (version 3.0.0+) is installed.

```bash
flutter doctor
```

### 2. Get Project Dependencies

```bash
cd todo_diary
flutter pub get
```

### 3. Run the App

* **Android**: `flutter run -d android`
* **Windows**: `flutter run -d windows`
* **Web**: `flutter run -d chrome`

### 4. Build the Release Version

```bash
# Android APK
flutter build apk --release

# Windows EXE
flutter build windows --release

# Web version
flutter build web --release
```

## 🛠️ Detailed User Guide

### To-Do Feature

1. Tap the "To-Do" tab on the homepage
2. Fill in the title and description in the input area
3. Tap the "Add To-Do" button
4. Tap the checkbox on the left of the task to mark it as completed
5. Tap the delete icon to remove a task

### Diary Feature

1. Tap the "Diary" tab on the homepage
2. Tap the "Write Diary" button
3. Enter a title, choose a mood, and write the content
4. Tap the save button
5. Tap the heart icon to favorite important diaries

### Sync Feature

1. Tap the "Sync" tab on the homepage
2. The app will automatically detect and create a sync folder
3. Tap the "Sync Now" button
4. Run the app on other devices and repeat steps 1-3
5. Data will automatically sync between devices

**Default Sync Directory**:

* Windows: `Documents\TDD_Sync`
* Android: `Internal Storage\Documents\TDD_Sync`

### Customization Features

#### Font Customization

1. Go to the "Settings" page
2. Browse available fonts in the "Font and UI Customization" section
3. Tap the font preview to select it
4. If the font is not downloaded, tap the "Download" button

#### Theme Customization

1. Go to the "Settings" page
2. Select a theme color (blue, green, purple, orange) in the "App Settings" section
3. Changes take effect immediately

#### UI Customization

1. Go to the "Settings" page
2. In the "Font and UI Customization" section, adjust font size, line spacing, and item spacing
3. Choose UI density (compact, standard, relaxed)

## ⚙️ Project Structure

```
todo_diary/
├── lib/                     # Dart source code
│   ├── main.dart            # Main entry point (full version)
│   ├── services/            # Business services
│   │   └── font_service.dart    # Font management service
│   ├── pages/               # Page components
│   ├── models/              # Data models
│   ├── core/                # Core functionality
│   └── theme/               # Theme configurations
├── android/                 # Android platform configuration
├── windows/                 # Windows platform configuration
├── web/                     # Web platform configuration
├── assets/                  # Static resources
│   ├── fonts/               # Font files
│   └── images/              # Image resources
└── pubspec.yaml             # Project dependencies configuration
```

## 🔧 Technical Architecture

### Core Technologies

* **Flutter 3.41.5**: Cross-platform UI framework
* **Dart 3.0.0+**: Programming language
* **Material Design 3**: Design system

### State Management

* Provider pattern
* Local configuration persistence
* Real-time data updates

### Data Storage

* SharedPreferences (local key-value storage)
* JSON file format (for sync and backup)
* AES encryption (for sensitive data)

### Sync Mechanism

* File system read/write
* Auto-detect platform differences
* Simple and efficient data exchange

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # UI & Design
  cupertino_icons: ^1.0.6
  provider: ^6.1.1
  google_fonts: ^6.1.0
  
  # Data & Storage
  shared_preferences: ^2.5.5
  path_provider: ^2.1.1
  path: ^1.9.0
  
  # Encryption
  encrypt: ^5.0.3
  
  # Permissions
  permission_handler: ^12.0.1
```

## 🧪 Testing Guide

### Feature Testing Checklist

* [ ] CRUD operations for to-do tasks
* [ ] Diary creation and editing
* [ ] Font switching functionality
* [ ] Theme color changes
* [ ] Data synchronization
* [ ] Configuration persistence
* [ ] Cross-platform compatibility

## 🔄 Sync Configuration Details

### How it Works

1. The app creates a local sync folder on each device
2. Data is exported to the sync folder in JSON format
3. Other devices import data from the sync folder
4. One-click sync operation is supported

## 🚨 Troubleshooting

### Common Issues

#### 1. App Won't Start

```bash
# Clean build cache
flutter clean

# Fetch dependencies again
flutter pub get

# Run diagnostics
flutter doctor
```

#### 2. Sync Feature Not Working

1. Check the sync folder permissions
2. Make sure there is enough storage space
3. Verify if the file is in use
4. Restart the app and retry

#### 3. Fonts Not Loading

1. Check the network connection (when downloading fonts)
2. Verify storage permissions
3. Redownload the font files
4. Check the font file format

#### 4. Limited Web Platform Features

* Web platform does not support file sync
* Use Android or Windows versions for syncing data
* Web version is suitable for temporary viewing and editing

## 📋 Version History

### v3.0.0 (2026-03-31)

* ✅ Updated app name to "TDD"
* ✅ Added complete font customization functionality
* ✅ New theme and UI customization options
* ✅ Optimized synchronization mechanism
* ✅ Unified configuration for all platform install packages
* ✅ Cleaned up redundant files, optimized project structure

### v2.0.0 (2026-03-30)

* ✅ Implemented basic data synchronization
* ✅ Added diary management feature
* ✅ Enhanced to-do system
* ✅ Supported multi-platform builds

### v1.0.0 (2026-03-29)

* ✅ Basic to-do feature
* ✅ Basic UI framework
* ✅ Cross-platform support

## 🤝 Contribution Guidelines

We welcome code contributions! Please follow these steps:

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -m 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

### Code Standards

* Follow Dart code standards
* Add necessary comments
* Write unit tests
* Update relevant documentation

## 📄 License

MIT License

## 📞 Contact and Support

* **Issue Reporting**: Please submit a GitHub Issue
* **Feature Suggestions**: Feel free to submit a Pull Request
* **Technical Inquiries**: Check the documentation or contact the developers

---

**TDD - Organize your life and record every amazing moment**

*Last updated: March 31, 2026*
