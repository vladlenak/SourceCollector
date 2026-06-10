import Foundation
import Combine

@MainActor
final class FileSelectionViewModel: ObservableObject {

    @Published var selectedFiles: Set<SourceFile> = []

    private let contentService: FileContentService
    private let clipboard: ClipboardService
    private let fileScannerViewModel: FileScannerViewModel

    init(
        contentService: FileContentService,
        clipboard: ClipboardService,
        fileScannerViewModel: FileScannerViewModel
    ) {
        self.contentService = contentService
        self.clipboard = clipboard
        self.fileScannerViewModel = fileScannerViewModel
    }

    func selectAllFiles() {
        selectedFiles = Set(fileScannerViewModel.files)
    }

    func copySelected() {
        var combined = ""
        for file in selectedFiles.sorted(by: { $0.name < $1.name }) {
            let content: String
            do {
                content = try contentService.readFile(at: file.url)
            } catch {
                content = "// Error reading file: \(error.localizedDescription)"
            }
            let relativePath = file.relativePath(from: fileScannerViewModel.projectViewModel.projectPath)
            combined += "// MARK: - \(relativePath)\n\n\(content)\n\n"
        }
        clipboard.copy(combined.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}