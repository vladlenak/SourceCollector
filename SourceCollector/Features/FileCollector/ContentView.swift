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
        VStack(alignment: .leading, spacing: 12) {

            // MARK: - Top controls
            HStack {
                TextField("Path to project", text: $vm.projectPath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Choose Folder") {
                    vm.openFolderPicker()
                }

                Button("Load") {
                    vm.loadFiles()
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
        .frame(width: 700, height: 500, alignment: .topLeading)
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
        fileSystem: DefaultFileSystemService()
    ))
}
