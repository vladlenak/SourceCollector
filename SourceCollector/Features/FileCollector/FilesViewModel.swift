//
//  FilesViewModel.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import Foundation
import AppKit
import Combine

// MARK: - File content abstraction

protocol FileContentService {
    func readFile(at url: URL) -> String
}

// MARK: - Default implementation

final class DefaultFileContentService: FileContentService {
    func readFile(at url: URL) -> String {
        (try? String(contentsOf: url)) ?? ""
    }
}

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

    // MARK: - Dependencies
    private let scanner: FileScanningService
    private let contentService: FileContentService

    init(
        scanner: FileScanningService = DefaultFileScanningService(),
        contentService: FileContentService = DefaultFileContentService()
    ) {
        self.scanner = scanner
        self.contentService = contentService
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

        files = scanner.scanFiles(
            at: url,
            allowedExtensions: enabledExtensions
        )
        .sorted { $0.name < $1.name }
    }

    func copySelected() {
        let combined = selectedFiles
            .sorted { $0.name < $1.name }
            .map { file in

                let content = contentService.readFile(at: file.url)
                let relativePath = file.relativePath(from: projectPath)

                return """
                // MARK: - \(relativePath)

                \(content)
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
