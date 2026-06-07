//
//  SourceCollectorApp.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import SwiftUI

@main
struct SourceCollectorApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView(vm: makeViewModel())
        }
    }

    private func makeViewModel() -> FilesViewModel {

        let fileSystem = DefaultFileSystemService()

        let scanner = DefaultFileScanningService(
            fileSystem: fileSystem
        )

        return FilesViewModel(
            scanner: scanner,
            contentService: DefaultFileContentService(),
            folderPicker: DefaultFolderPickingService(),
            clipboard: DefaultClipboardService(),
            fileSystem: fileSystem
        )
    }
}
