//
//  ClipboardService.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import AppKit

protocol ClipboardService {
    func copy(_ string: String)
}

final class DefaultClipboardService: ClipboardService {

    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func copy(_ string: String) {
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
}
