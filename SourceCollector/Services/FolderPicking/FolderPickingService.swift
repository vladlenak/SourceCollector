//
//  FolderPickingService.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import Foundation
import AppKit

protocol FolderPickingService {
    func pickFolder() -> URL?
}

final class DefaultFolderPickingService: FolderPickingService {

    func pickFolder() -> URL? {

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"

        return panel.runModal() == .OK ? panel.url : nil
    }
}
