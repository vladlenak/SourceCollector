# SourceCollector

SourceCollector is a simple macOS application for collecting source code from projects and quickly copying selected files to the clipboard.

## ✨ Features

- Select a project folder via Finder
- Recursive file scanning
- Filter files by programming language (enable/disable extensions)
- Support for popular programming languages:
  - Swift
  - Kotlin
  - Java
  - Dart
  - JavaScript
  - TypeScript
- Select files from a list
- Bulk copy of selected files to the clipboard
- Automatic `// MARK: - relative/path` insertion

## 🧠 How it works

1. You select a project folder
2. The app scans files by supported extensions
3. You select the files you need
4. You click **Copy Selected**
5. You get a combined code block in your clipboard

## 📦 Project Structure

```text
SourceCollector/
├── App/
│   └── SourceCollectorApp.swift
├── Domain/
│   ├── RecentProject.swift
│   └── SourceFile.swift
├── Features/
│   └── FileCollector/
│       ├── ContentView.swift
│       └── FilesViewModel.swift
├── Services/
│   ├── Clipboard/
│   ├── FileContent/
│   ├── FileScanning/
│   ├── FileSystem/
│   ├── FolderPicking/
│   └── RecentProjects/
├── SourceCollectorTests/
└── SourceCollectorUITests/
```

## 🚀 Installation & Run

```bash
git clone https://github.com/YOUR_USERNAME/SourceCollector.git
cd SourceCollector
open SourceCollector.xcodeproj
```

Then run the project in Xcode (⌘R).

## 🔧 Requirements

- macOS 13+
- Xcode 15+
- Swift 5.9+

## 📄 License

MIT
