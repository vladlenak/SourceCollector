//
//  DefaultFileSystemService.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import Foundation

final class DefaultFileSystemService: FileSystemService {

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func enumerator(at url: URL) -> FileManager.DirectoryEnumerator? {
        fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: nil
        )
    }

    func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
}
