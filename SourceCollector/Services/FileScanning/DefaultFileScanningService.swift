//
//  DefaultFileScanningService.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import Foundation

final class DefaultFileScanningService: FileScanningService {

    private let fileSystem: FileSystemService

    init(fileSystem: FileSystemService) {
        self.fileSystem = fileSystem
    }

    func scanFiles(at url: URL, allowedExtensions: Set<String>) -> [SourceFile] {
        let enumerator = fileSystem.enumerator(at: url, options: [.skipsHiddenFiles])

        var result: [SourceFile] = []

        while let fileURL = enumerator?.nextObject() as? URL {
            guard allowedExtensions.contains(fileURL.pathExtension) else { continue }

            result.append(
                SourceFile(url: fileURL, name: fileURL.lastPathComponent)
            )
        }

        return result
    }
}
