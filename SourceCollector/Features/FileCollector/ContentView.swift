import SwiftUI

struct ContentView: View {

    @ObservedObject var projectViewModel: ProjectViewModel
    @ObservedObject var fileScannerViewModel: FileScannerViewModel
    @ObservedObject var fileSelectionViewModel: FileSelectionViewModel

    var body: some View {
        HSplitView {
            sidebar
                .frame(minWidth: 200, idealWidth: 250)

            contentArea
                .frame(minWidth: 450)
        }
        .frame(minWidth: 700, minHeight: 420)
        .toolbar { toolbarContent }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button {
                projectViewModel.openFolderPicker()
            } label: {
                Label("Choose Folder", systemImage: "folder.badge.plus")
            }
            .help("Select a project folder")
        }

        ToolbarItem(placement: .principal) {
            HStack(spacing: 6) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                    .imageScale(.small)
                TextField("Project path", text: $projectViewModel.projectPath)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 200, idealWidth: 320)
                    .help("Enter or paste a directory path")
                Button("Load") {
                    projectViewModel.openProject(path: projectViewModel.projectPath)
                    Task { await fileScannerViewModel.loadFiles() }
                }
                .keyboardShortcut(.return, modifiers: .command)
                .help("Scan files in the specified directory")
                .disabled(projectViewModel.projectPath.isEmpty)
            }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            if !fileScannerViewModel.files.isEmpty {
                Button {
                    if fileSelectionViewModel.selectedFiles.count == fileScannerViewModel.files.count {
                        fileSelectionViewModel.selectedFiles = []
                    } else {
                        fileSelectionViewModel.selectAllFiles()
                    }
                } label: {
                    Label(
                        fileSelectionViewModel.selectedFiles.count == fileScannerViewModel.files.count
                            ? "Deselect All"
                            : "Select All",
                        systemImage: fileSelectionViewModel.selectedFiles.count == fileScannerViewModel.files.count
                            ? "checkmark.circle.fill"
                            : "checkmark.circle"
                    )
                }
                .help("Toggle selection of all files")
            }

            Button {
                fileSelectionViewModel.copySelected()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .disabled(fileSelectionViewModel.selectedFiles.isEmpty)
            .keyboardShortcut("c", modifiers: .command)
            .help("Copy selected files to clipboard")
        }
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebar: some View {
        List(selection: $projectViewModel.selectedRecentProject) {
            Section {
                if projectViewModel.recentProjects.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("No Recent Projects")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Open a folder to get started")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(projectViewModel.recentProjects) { project in
                        HStack(spacing: 8) {
                            Image(systemName: "folder")
                                .foregroundStyle(.tint)
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
                }
            } header: {
                Label("Recent Projects", systemImage: "clock")
            }
        }
        .listStyle(.sidebar)
        .onChange(of: projectViewModel.selectedRecentProject) { _, newValue in
            guard let path = newValue, path != projectViewModel.projectPath else { return }
            let project = projectViewModel.recentProjects.first { $0.path == path }
            projectViewModel.openProject(path: path, bookmarkData: project?.bookmarkData)
            Task { await fileScannerViewModel.loadFiles() }
            DispatchQueue.main.async {
                projectViewModel.selectedRecentProject = nil
            }
        }
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        VStack(spacing: 0) {
            if fileScannerViewModel.isLoading {
                loadingView
            } else if let error = fileScannerViewModel.errorMessage {
                errorView(message: error)
            }

            if !projectViewModel.projectPath.isEmpty {
                fileTypeFilters
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }

            if fileScannerViewModel.files.isEmpty && !projectViewModel.projectPath.isEmpty {
                emptyFilesView
            } else if !fileScannerViewModel.files.isEmpty {
                fileList
            } else {
                emptyWelcomeView
            }

            if !fileScannerViewModel.files.isEmpty {
                Divider()
                statusBar
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("Scanning files…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.3))
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .imageScale(.small)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                fileScannerViewModel.errorMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.yellow.opacity(0.1))
    }

    // MARK: - File Type Filters

    private var fileTypeFilters: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
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
                                Task { await fileScannerViewModel.loadFiles() }
                            }
                        )
                    )
                    .toggleStyle(.button)
                    .controlSize(.small)
                    .buttonStyle(.bordered)
                    .tint(fileScannerViewModel.enabledExtensions.contains(ext) ? .accentColor : .gray)
                    .help("\(fileScannerViewModel.enabledExtensions.contains(ext) ? "Disable" : "Enable") .\(ext) files")
                }
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - File List

    private var fileList: some View {
        List(selection: $fileSelectionViewModel.selectedFiles) {
            ForEach(fileScannerViewModel.files) { file in
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                        .imageScale(.small)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(file.name)
                        Text(file.relativePath(from: fileScannerViewModel.projectPath))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .tag(file)
                .padding(.vertical, 2)
            }
        }
        .listStyle(.bordered)
        .alternatingRowBackgrounds()
        .environment(\.defaultMinListRowHeight, 28)
    }

    // MARK: - Empty States

    private var emptyWelcomeView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("Source Collector")
                .font(.title2)
                .fontWeight(.medium)
            Text("Open a project folder to scan and collect source files")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyFilesView: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text("No Files Found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Try enabling different file types or choosing another folder")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 4) {
            Text("\(fileSelectionViewModel.selectedFiles.count) of \(fileScannerViewModel.files.count) files selected")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Copy Selected") {
                fileSelectionViewModel.copySelected()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(fileSelectionViewModel.selectedFiles.isEmpty)
            .keyboardShortcut("c", modifiers: .command)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
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
