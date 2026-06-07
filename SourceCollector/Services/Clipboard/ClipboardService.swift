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

    func copy(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}
