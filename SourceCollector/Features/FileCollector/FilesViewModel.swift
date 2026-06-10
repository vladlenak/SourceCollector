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
         guard let picked = folderPicker.pickFolder() else { return }
         openProject(path: picked.url.path, bookmarkData: picked.bookmarkData)
     }

     func openProject(path: String, bookmarkData: Data? = nil) {
         guard !path.isEmpty else { return }
         errorMessage = nil
         projectPath = path
         if recentProjects.first?.path != path {
             recentProjectsService.addProject(path: path, bookmarkData: bookmarkData)
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

          let project = recentProjects.first { $0.path == projectPath }
          let hasBookmark = project?.bookmarkData != nil

          if hasBookmark {
              restoreSecurityScopedAccess(for: url, bookmarkData: project!.bookmarkData!)
          }

          guard fileSystem.enumerator(at: url) != nil else {
              if hasBookmark {
                  url.stopAccessingSecurityScopedResource()
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
              url.stopAccessingSecurityScopedResource()
          }

          if files.isEmpty {
              errorMessage = "No source files found for selected extensions"
          }
      }

     private func restoreSecurityScopedAccess(for url: URL, bookmarkData: Data) {
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

      func copySelected() {
          var combined = ""
          for file in selectedFiles.sorted(by: { $0.name < $1.name }) {
              let content: String
              do {
                  content = try contentService.readFile(at: file.url)
              } catch {
                  content = "// Error reading file: \(error.localizedDescription)"
              }
              let relativePath = file.relativePath(from: projectPath)
              combined += "// MARK: - \(relativePath)\n\n\(content)\n\n"
          }
          clipboard.copy(combined.trimmingCharacters(in: .whitespacesAndNewlines))
      }

     func selectAllFiles() {
         selectedFiles = Set(files)
     }
 }
