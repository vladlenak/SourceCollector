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
            }
        }
        .onChange(of: vm.selectedRecentProject) { _, newValue in
            if let path = newValue, path != vm.projectPath {
                vm.openProject(path: path)
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: - Top controls
            HStack {
                TextField("Path to project", text: $vm.projectPath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Choose Folder") {
                    vm.openFolderPicker()
                }

                Button("Load") {
                    vm.openProject(path: vm.projectPath)
                }
            }

            // MARK: - File type filters
            VStack(alignment: .leading, spacing: 8) {
                Text("File Types")
                    .font(.headline)

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
                    }
                }
            }

            // MARK: - File list
            List(vm.files, id: \.self, selection: $vm.selectedFiles) { file in
                Text(file.name)
            }
            .frame(maxHeight: .infinity)

            // MARK: - Actions
            HStack {
                Button("Select All") {
                    vm.selectAllFiles()
                }

                Button("Copy Selected") {
                    vm.copySelected()
                }
                .disabled(vm.selectedFiles.isEmpty)
            }
        }
        .padding(24)
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
