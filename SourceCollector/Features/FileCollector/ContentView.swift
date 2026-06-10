//
//  ContentView.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var vm: FilesViewModel

    init(vm: FilesViewModel) {
        _vm = StateObject(wrappedValue: vm)
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

            if vm.recentProjects.isEmpty {
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
                List(vm.recentProjects, selection: $vm.selectedRecentProject) { project in
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
                            vm.removeRecentProject(path: project.path)
                        }
                    }
                }
                .listStyle(.plain)
                .accessibilityIdentifier("recentProjectsList")
            }
        }
        .onChange(of: vm.selectedRecentProject) { _, newValue in
            if let path = newValue, path != vm.projectPath {
                let project = vm.recentProjects.first { $0.path == path }
                vm.openProject(path: path, bookmarkData: project?.bookmarkData)
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        VStack(alignment: .leading, spacing: 12) {

            if let error = vm.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.callout)
                    Spacer()
                    Button {
                        vm.errorMessage = nil
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
                TextField("Path to project", text: $vm.projectPath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .accessibilityIdentifier("projectPathField")

                Button("Choose Folder") {
                    vm.openFolderPicker()
                }
                .accessibilityIdentifier("chooseFolderButton")

                Button("Load") {
                    vm.openProject(path: vm.projectPath)
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
                    ForEach(vm.supportedExtensions, id: \.self) { ext in
                        Toggle(
                            ext,
                            isOn: Binding(
                                get: { vm.enabledExtensions.contains(ext) },
                                set: { isOn in
                                    if isOn {
                                        vm.enabledExtensions.insert(ext)
                                    } else {
                                        vm.enabledExtensions.remove(ext)
                                    }
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

            if vm.files.isEmpty && !vm.projectPath.isEmpty {
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
                List(vm.files, id: \.self, selection: $vm.selectedFiles) { file in
                    Text(file.name)
                        .accessibilityLabel("\(file.name), \(file.url.path)")
                }
                .frame(maxHeight: .infinity)
                .accessibilityIdentifier("fileList")
            }

            HStack {
                Button("Select All") {
                    vm.selectAllFiles()
                }
                .accessibilityIdentifier("selectAllButton")

                Spacer()

                Button("Copy Selected (\(vm.selectedFiles.count))") {
                    vm.copySelected()
                }
                .disabled(vm.selectedFiles.isEmpty)
                .accessibilityIdentifier("copySelectedButton")
            }
        }
        .padding(24)
        .overlay {
            if vm.isLoading {
                ProgressView("Scanning files…")
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

#Preview {
    ContentView(vm: FilesViewModel(
        scanner: DefaultFileScanningService(
            fileSystem: DefaultFileSystemService()
        ),
        contentService: DefaultFileContentService(),
        folderPicker: DefaultFolderPickingService(),
        clipboard: DefaultClipboardService(),
        fileSystem: DefaultFileSystemService(),
        recentProjectsService: DefaultRecentProjectsService()
    ))
}
