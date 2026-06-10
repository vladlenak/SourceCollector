//
 //  FolderPickingService.swift
 //  SourceCollector
 //
 //  Created by Vladlen Akhtemov on 07.06.26.
 //

 import Foundation
 import AppKit

 struct PickedFolder {
     let url: URL
     let bookmarkData: Data?
 }

 protocol FolderPickingService {
     func pickFolder() -> PickedFolder?
 }

 final class DefaultFolderPickingService: FolderPickingService {

     func pickFolder() -> PickedFolder? {
         let panel = NSOpenPanel()
         panel.canChooseFiles = false
         panel.canChooseDirectories = true
         panel.allowsMultipleSelection = false
         panel.prompt = "Select"

         guard panel.runModal() == .OK, let url = panel.url else { return nil }

         let bookmarkData = try? url.bookmarkData(
             options: .withSecurityScope,
             includingResourceValuesForKeys: nil,
             relativeTo: nil
         )

         return PickedFolder(url: url, bookmarkData: bookmarkData)
     }
 }
