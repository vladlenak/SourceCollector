//
//  SourceFile.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import Foundation

struct SourceFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String

    var content: String {
        (try? String(contentsOf: url)) ?? ""
    }

    func relativePath(from root: String) -> String {
        let rootURL = URL(fileURLWithPath: root).standardizedFileURL
        let fileURL = url.standardizedFileURL

        let rootPath = rootURL.path.hasSuffix("/")
            ? rootURL.path
            : rootURL.path + "/"

        if fileURL.path.hasPrefix(rootPath) {
            return String(fileURL.path.dropFirst(rootPath.count))
        } else {
            return fileURL.lastPathComponent
        }
    }
}
