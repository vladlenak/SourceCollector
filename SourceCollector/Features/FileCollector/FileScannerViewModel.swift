import Foundation
import Combine

@MainActor
final class FileScannerViewModel: ObservableObject {

    @Published var files: [SourceFile] = []
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

    private let scanner: FileScanningService
    let projectViewModel: ProjectViewModel

    init(
        scanner: FileScanningService,
        projectViewModel: ProjectViewModel
    ) {
        self.scanner = scanner
        self.projectViewModel = projectViewModel
        self.enabledExtensions = Set(supportedExtensions)
    }

    func loadFiles() {
        guard projectViewModel.validateProjectPath() else {
            errorMessage = "Directory does not exist: \(projectViewModel.projectPath)"
            files = []
            return
        }

        let url = URL(fileURLWithPath: projectViewModel.projectPath)

        let project = projectViewModel.recentProjects.first { $0.path == projectViewModel.projectPath }
        let hasBookmark = project?.bookmarkData != nil

        if hasBookmark {
            projectViewModel.restoreSecurityScopedAccess(for: url, bookmarkData: project!.bookmarkData!)
        }

        guard projectViewModel.fileSystem.enumerator(at: url) != nil else {
            if hasBookmark {
                projectViewModel.stopSecurityScopedAccess(for: url)
            }
            errorMessage = "Cannot read directory contents. Use 'Choose Folder' to grant access."
            files = []
            return
        }

        isLoading = true
        errorMessage = nil

        let scannedFiles = scanner.scanFiles(
            at: url,
            allowedExtensions: enabledExtensions
        )
        .sorted { $0.name < $1.name }

        isLoading = false

        files = scannedFiles

        if hasBookmark {
            projectViewModel.stopSecurityScopedAccess(for: url)
        }

        if files.isEmpty {
            errorMessage = "No source files found for selected extensions"
        }
    }
}