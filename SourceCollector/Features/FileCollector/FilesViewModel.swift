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
    @Published var files: [SourceFile] = [] {
        didSet {
            selectedFiles = Set(files)
        }
    }
    @Published var selectedFiles: Set<SourceFile> = []
    @Published var recentProjects: [RecentProject] = []
    @Published var selectedRecentProject: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let supportedExtensions: [String] = [
        "swift",
        "kt",
        "java",
        "dart",
        "js",
        "ts"
    ]

    @Published var enabledExtensions: Set<String>

    // MARK: - Dependencies
    private let scanner: FileScanningService
    private let contentService: FileContentService
    private let folderPicker: FolderPickingService
    private let clipboard: ClipboardService
    private let fileSystem: FileSystemService
    private let recentProjectsService: RecentProjectsService

    init(
        scanner: FileScanningService,
        contentService: FileContentService,
        folderPicker: FolderPickingService,
        clipboard: ClipboardService,
        fileSystem: FileSystemService,
        recentProjectsService: RecentProjectsService
    ) {
        self.scanner = scanner
        self.contentService = contentService
        self.folderPicker = folderPicker
        self.clipboard = clipboard
        self.fileSystem = fileSystem
        self.recentProjectsService = recentProjectsService
        self.enabledExtensions = Set(supportedExtensions)
        self.recentProjects = recentProjectsService.recentProjects
    }

    func openFolderPicker() {
        guard let url = folderPicker.pickFolder() else { return }
        openProject(path: url.path)
    }

    func openProject(path: String) {
        guard !path.isEmpty else { return }
        errorMessage = nil
        projectPath = path
        if recentProjects.first?.path != path {
            recentProjectsService.addProject(path: path)
            recentProjects = recentProjectsService.recentProjects
        }
        selectedRecentProject = path
        loadFiles()
    }

    func removeRecentProject(path: String) {
        recentProjectsService.removeProject(path: path)
        recentProjects = recentProjectsService.recentProjects
    }

    func loadFiles() {
        let url = URL(fileURLWithPath: projectPath)

        guard fileSystem.fileExists(at: url) else {
            errorMessage = "Directory does not exist: \(projectPath)"
            files = []
            return
        }

        isLoading = true
        errorMessage = nil

        files = scanner.scanFiles(
            at: url,
            allowedExtensions: enabledExtensions
        )
        .sorted { $0.name < $1.name }

        isLoading = false

        if files.isEmpty {
            errorMessage = "No source files found for selected extensions"
        }
    }

    func copySelected() {
        let combined = selectedFiles
            .sorted { $0.name < $1.name }
            .map { file in
                let content = contentService.readFile(at: file.url)
                let relativePath = file.relativePath(from: projectPath)
                return "// MARK: - \(relativePath)\n\n\(content)"
            }
            .joined(separator: "\n\n")
        clipboard.copy(combined)
    }

    func selectAllFiles() {
        selectedFiles = Set(files)
    }
}
