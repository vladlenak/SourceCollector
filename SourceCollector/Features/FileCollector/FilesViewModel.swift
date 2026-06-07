//
//  FilesViewModel.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import Foundation
import AppKit
import Combine

@MainActor
final class FilesViewModel: ObservableObject {

    @Published var projectPath: String = ""
    @Published var files: [SourceFile] = []
    @Published var selectedFiles: Set<SourceFile> = []

    // MARK: - Supported file types
    let supportedExtensions: [String] = [
        "swift",
        "kt",
        "java",
        "dart",
        "js",
        "ts"
    ]

    // MARK: - Enabled filters (default = all ON)
    @Published var enabledExtensions: Set<String>

    init() {
        self.enabledExtensions = Set(supportedExtensions)
    }

    func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"

        if panel.runModal() == .OK {
            if let url = panel.url {
                projectPath = url.path
                loadFiles()
            }
        }
    }

    func loadFiles() {
        let url = URL(fileURLWithPath: projectPath)
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: nil
        )

        var result: [SourceFile] = []

        while let fileURL = enumerator?.nextObject() as? URL {
            guard enabledExtensions.contains(fileURL.pathExtension) else {
                continue
            }

            let file = SourceFile(
                url: fileURL,
                name: fileURL.lastPathComponent
            )

            result.append(file)
        }

        files = result.sorted { $0.name < $1.name }
    }

    func copySelected() {
        let combined = selectedFiles
            .sorted { $0.name < $1.name }
            .map { file in
                let relativePath = file.relativePath(from: projectPath)

                return """
                // MARK: - \(relativePath)

                \(file.content)
                """
            }
            .joined(separator: "\n\n")

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(combined, forType: .string)
    }

    func selectAllFiles() {
        selectedFiles = Set(files)
    }
}
