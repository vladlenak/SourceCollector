//
 //  SourceCollectorApp.swift
 //  SourceCollector
 //
 //  Created by Vladlen Akhtemov on 07.06.26.
 //

 import SwiftUI
 import Combine

 @MainActor
 final class AppDependencies: ObservableObject {
     let fileSystem: FileSystemService
     let scanner: FileScanningService
     let projectViewModel: ProjectViewModel
     let fileScannerViewModel: FileScannerViewModel
     let fileSelectionViewModel: FileSelectionViewModel

     init() {
         let fs = DefaultFileSystemService()
         let sc = DefaultFileScanningService(fileSystem: fs)
         let pvm = ProjectViewModel(
             folderPicker: DefaultFolderPickingService(),
             fileSystem: fs,
             recentProjectsService: DefaultRecentProjectsService()
         )
         let fsvm = FileScannerViewModel(scanner: sc, projectViewModel: pvm)
         let selv = FileSelectionViewModel(
             contentService: DefaultFileContentService(),
             clipboard: DefaultClipboardService(),
             fileScannerViewModel: fsvm
         )
         self.fileSystem = fs
         self.scanner = sc
         self.projectViewModel = pvm
         self.fileScannerViewModel = fsvm
         self.fileSelectionViewModel = selv
     }
 }

 @main
 struct SourceCollectorApp: App {

     @StateObject private var dependencies = AppDependencies()

     var body: some Scene {
         WindowGroup {
             ContentView(
                 projectViewModel: dependencies.projectViewModel,
                 fileScannerViewModel: dependencies.fileScannerViewModel,
                 fileSelectionViewModel: dependencies.fileSelectionViewModel
             )
         }
     }
 }
