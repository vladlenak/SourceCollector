//
 //  ContentView.swift
 //  SourceCollector
 //
 //  Created by Vladlen Akhtemov on 07.06.26.
 //

 import SwiftUI

struct ContentView: View {

    @ObservedObject var projectViewModel: ProjectViewModel
    @ObservedObject var fileScannerViewModel: FileScannerViewModel
    @ObservedObject var fileSelectionViewModel: FileSelectionViewModel

    init(
        projectViewModel: ProjectViewModel,
        fileScannerViewModel: FileScannerViewModel,
        fileSelectionViewModel: FileSelectionViewModel
    ) {
        self.projectViewModel = projectViewModel
        self.fileScannerViewModel = fileScannerViewModel
        self.fileSelectionViewModel = fileSelectionViewModel
    }

     var body: some View {
         HSplitView {
             sidebar
                 .frame(minWidth: 180, idealWidth: 220)

             detailView
                 .frame(minWidth: 400)
         }
         .frame(width: 800, height: 500)
     }

     @ViewBuilder
     private var sidebar: some View {
         VStack(alignment: .leading, spacing: 4) {
             Text("Recent Projects")
                 .font(.headline)
                 .padding(.horizontal, 12)
                 .padding(.top, 12)
                 .accessibilityAddTraits(.isHeader)

             if projectViewModel.recentProjects.isEmpty {
                 VStack(spacing: 8) {
                     Text("No recent projects")
                         .font(.headline)
                         .foregroundStyle(.secondary)
                     Text("Choose a folder or type a path\nand click Load")
                         .font(.caption)
                         .foregroundStyle(.tertiary)
                         .multilineTextAlignment(.center)
                 }
                 .frame(maxWidth: .infinity, maxHeight: .infinity)
                 .accessibilityElement(children: .combine)
                 .accessibilityIdentifier("recentProjectsEmptyState")
             } else {
                 List(projectViewModel.recentProjects, selection: $projectViewModel.selectedRecentProject) { project in
                     HStack(spacing: 8) {
                         Image(systemName: "folder")
                             .foregroundStyle(.secondary)
                             .frame(width: 16)
                         VStack(alignment: .leading, spacing: 1) {
                             Text(project.name)
                                 .lineLimit(1)
                             Text(project.path)
                                 .font(.caption)
                                 .foregroundStyle(.tertiary)
                                 .lineLimit(1)
                                 .truncationMode(.middle)
                         }
                     }
                     .tag(project.path)
                     .contextMenu {
                         Button("Remove from Recents") {
                             projectViewModel.removeRecentProject(path: project.path)
                         }
                     }
                 }
                 .listStyle(.plain)
                 .accessibilityIdentifier("recentProjectsList")
             }
         }
          .onChange(of: projectViewModel.selectedRecentProject) { _, newValue in
              if let path = newValue, path != projectViewModel.projectPath {
                  let project = projectViewModel.recentProjects.first { $0.path == path }
                  projectViewModel.openProject(path: path, bookmarkData: project?.bookmarkData)
                  fileScannerViewModel.loadFiles()
              }
              // Reset selection to avoid re-entrancy loop
              projectViewModel.selectedRecentProject = nil
          }
     }

     @ViewBuilder
     private var detailView: some View {
         VStack(alignment: .leading, spacing: 12) {

             if let error = fileScannerViewModel.errorMessage {
                 HStack {
                     Image(systemName: "exclamationmark.triangle.fill")
                         .foregroundStyle(.yellow)
                     Text(error)
                         .font(.callout)
                     Spacer()
                     Button {
                         fileScannerViewModel.errorMessage = nil
                     } label: {
                         Image(systemName: "xmark.circle.fill")
                             .foregroundStyle(.secondary)
                     }
                     .buttonStyle(.plain)
                 }
                 .padding(8)
                 .background(.yellow.opacity(0.15))
                 .clipShape(RoundedRectangle(cornerRadius: 6))
                 .accessibilityIdentifier("errorBanner")
             }

             HStack {
                 TextField("Path to project", text: $projectViewModel.projectPath)
                     .textFieldStyle(RoundedBorderTextFieldStyle())
                     .accessibilityIdentifier("projectPathField")

                 Button("Choose Folder") {
                     projectViewModel.openFolderPicker()
                 }
                 .accessibilityIdentifier("chooseFolderButton")

                 Button("Load") {
                     projectViewModel.openProject(path: projectViewModel.projectPath)
                     fileScannerViewModel.loadFiles()
                 }
                 .accessibilityIdentifier("loadButton")
             }

             VStack(alignment: .leading, spacing: 8) {
                 Text("File Types")
                     .font(.headline)
                     .accessibilityAddTraits(.isHeader)

                 LazyVGrid(
                     columns: [
                         GridItem(.adaptive(minimum: 80), spacing: 8)
                     ],
                     alignment: .leading,
                     spacing: 8
                 ) {
                     ForEach(fileScannerViewModel.supportedExtensions, id: \.self) { ext in
                         Toggle(
                             ext,
                             isOn: Binding(
                                 get: { fileScannerViewModel.enabledExtensions.contains(ext) },
                                 set: { isOn in
                                     if isOn {
                                         fileScannerViewModel.enabledExtensions.insert(ext)
                                     } else {
                                         fileScannerViewModel.enabledExtensions.remove(ext)
                                     }
                                     fileScannerViewModel.loadFiles()
                                 }
                             )
                         )
                         .toggleStyle(.checkbox)
                         .accessibilityIdentifier("toggle_\(ext)")
                     }
                 }
             }
             .accessibilityElement(children: .contain)
             .accessibilityIdentifier("fileTypeFilters")

             if fileScannerViewModel.files.isEmpty && !projectViewModel.projectPath.isEmpty {
                 VStack(spacing: 8) {
                     Image(systemName: "doc.text.magnifyingglass")
                         .font(.largeTitle)
                         .foregroundStyle(.tertiary)
                     Text("No files found")
                         .font(.headline)
                         .foregroundStyle(.secondary)
                     Text("Try different file types or a different folder")
                         .font(.caption)
                         .foregroundStyle(.tertiary)
                 }
                 .frame(maxWidth: .infinity, maxHeight: .infinity)
                 .accessibilityElement(children: .combine)
                 .accessibilityIdentifier("filesEmptyState")
             } else {
                 List(fileScannerViewModel.files, id: \.self, selection: $fileSelectionViewModel.selectedFiles) { file in
                     Text(file.name)
                         .accessibilityLabel("\(file.name), \(file.url.path)")
                 }
                 .frame(maxHeight: .infinity)
                 .accessibilityIdentifier("fileList")
             }

             HStack {
                 Button("Select All") {
                     fileSelectionViewModel.selectAllFiles()
                 }
                 .accessibilityIdentifier("selectAllButton")

                 Spacer()

                 Button("Copy Selected (\(fileSelectionViewModel.selectedFiles.count))") {
                     fileSelectionViewModel.copySelected()
                 }
                 .disabled(fileSelectionViewModel.selectedFiles.isEmpty)
                 .accessibilityIdentifier("copySelectedButton")
             }
         }
         .padding(24)
         .overlay {
             if fileScannerViewModel.isLoading {
                 ProgressView("Scanning files…")
                     .padding(20)
                     .background(.regularMaterial)
                     .clipShape(RoundedRectangle(cornerRadius: 10))
             }
         }
     }
 }

 #Preview {
     let fileSystem = DefaultFileSystemService()
     let scanner = DefaultFileScanningService(fileSystem: fileSystem)
     let projectVM = ProjectViewModel(
         folderPicker: DefaultFolderPickingService(),
         fileSystem: fileSystem,
         recentProjectsService: DefaultRecentProjectsService()
     )
     let fileScannerVM = FileScannerViewModel(scanner: scanner, projectViewModel: projectVM)
     let fileSelectionVM = FileSelectionViewModel(
         contentService: DefaultFileContentService(),
         clipboard: DefaultClipboardService(),
         fileScannerViewModel: fileScannerVM
     )
     ContentView(
         projectViewModel: projectVM,
         fileScannerViewModel: fileScannerVM,
         fileSelectionViewModel: fileSelectionVM
     )
 }