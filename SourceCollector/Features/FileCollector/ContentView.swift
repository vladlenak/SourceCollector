//
//  ContentView.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var vm = FilesViewModel()

    var body: some View {
        VStack(spacing: 12) {

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

            List(vm.files, id: \.self, selection: $vm.selectedFiles) { file in
                Text(file.name)
            }
            .frame(minHeight: 400)

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
        .frame(width: 700, height: 500)
    }
}

#Preview {
    ContentView()
}
