//
//  FileSystemService.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import Foundation

protocol FileSystemService {

    func enumerator(at url: URL, options: FileManager.DirectoryEnumerationOptions) -> FileManager.DirectoryEnumerator?
    func enumerator(at url: URL) -> FileManager.DirectoryEnumerator?

    func fileExists(at url: URL) -> Bool
}

extension FileSystemService {
    func enumerator(at url: URL) -> FileManager.DirectoryEnumerator? {
        enumerator(at: url, options: [])
    }
}
