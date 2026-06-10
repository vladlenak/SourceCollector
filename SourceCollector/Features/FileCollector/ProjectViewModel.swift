import Foundation
import Combine

@MainActor
final class ProjectViewModel: ObservableObject {

    @Published var projectPath: String = ""
    @Published var recentProjects: [RecentProject] = []
    @Published var selectedRecentProject: String?

    let folderPicker: FolderPickingService
    let fileSystem: FileSystemService
    private let recentProjectsService: RecentProjectsService

    init(
        folderPicker: FolderPickingService,
        fileSystem: FileSystemService,
        recentProjectsService: RecentProjectsService
    ) {
        self.folderPicker = folderPicker
        self.fileSystem = fileSystem
        self.recentProjectsService = recentProjectsService
        self.recentProjects = recentProjectsService.recentProjects
    }

    func openFolderPicker() {
        guard let picked = folderPicker.pickFolder() else { return }
        openProject(path: picked.url.path, bookmarkData: picked.bookmarkData)
    }

    func openProject(path: String, bookmarkData: Data? = nil) {
        guard !path.isEmpty else { return }
        projectPath = path
        if recentProjects.first?.path != path {
            recentProjectsService.addProject(path: path, bookmarkData: bookmarkData)
            recentProjects = recentProjectsService.recentProjects
        }
        selectedRecentProject = path
    }

    func removeRecentProject(path: String) {
        recentProjectsService.removeProject(path: path)
        recentProjects = recentProjectsService.recentProjects
    }

     func validateProjectPath() -> Bool {
         let url = URL(fileURLWithPath: projectPath)
         return fileSystem.fileIsDirectory(at: url)
     }

    func restoreSecurityScopedAccess(for url: URL, bookmarkData: Data) {
        var isStale = false
        guard let resolvedURL = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return
        }

        if isStale {
            return
        }

        _ = resolvedURL.startAccessingSecurityScopedResource()
    }

    func stopSecurityScopedAccess(for url: URL) {
        url.stopAccessingSecurityScopedResource()
    }
}