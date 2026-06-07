//
//  FileScanningService.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import Foundation

// MARK: - Abstraction

protocol FileScanningService {
    func scanFiles(at url: URL, allowedExtensions: Set<String>) -> [SourceFile]
}

// MARK: - Default implementation

final class DefaultFileScanningService: FileScanningService {

    func scanFiles(at url: URL, allowedExtensions: Set<String>) -> [SourceFile] {
        let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: nil
        )

        var result: [SourceFile] = []

        while let fileURL = enumerator?.nextObject() as? URL {
            guard allowedExtensions.contains(fileURL.pathExtension) else {
                continue
            }

            let file = SourceFile(
                url: fileURL,
                name: fileURL.lastPathComponent
            )

            result.append(file)
        }

        return result
    }
}
