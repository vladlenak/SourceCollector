//
//  FilesViewModel.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import Foundation
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

    // MARK: - Enabled filters
    @Published var enabledExtensions: Set<String>

    // MARK: - Dependencies
    private let scanner: FileScanningService
    private let contentService: FileContentService
    private let folderPicker: FolderPickingService
    private let clipboard: ClipboardService

    init(
        scanner: FileScanningService = DefaultFileScanningService(),
        contentService: FileContentService,
        folderPicker: FolderPickingService,
        clipboard: ClipboardService
    ) {
        self.scanner = scanner
        self.contentService = contentService
        self.folderPicker = folderPicker
        self.clipboard = clipboard
        self.enabledExtensions = Set(supportedExtensions)
    }

    func openFolderPicker() {
        guard let url = folderPicker.pickFolder() else { return }
        projectPath = url.path
        loadFiles()
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

        clipboard.copy(combined)
    }

    func selectAllFiles() {
        selectedFiles = Set(files)
    }
}
