//
//  DefaultFileContentService.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import Foundation

final class DefaultFileContentService: FileContentService {

    private let maxFileSize: UInt64 = 100_000_000

    func readFile(at url: URL) throws -> String {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        if let fileSize = resourceValues.fileSize, UInt64(fileSize) > maxFileSize {
            throw FileContentError.fileTooLarge(size: fileSize, maxSize: Int(maxFileSize))
        }

        var encoding: String.Encoding = .utf8
        let content = try String(contentsOf: url, usedEncoding: &encoding)
        return content
    }
}

enum FileContentError: LocalizedError {
    case fileTooLarge(size: Int, maxSize: Int)

    var errorDescription: String? {
        switch self {
        case .fileTooLarge(let size, let maxSize):
            return "File too large (\(size) bytes). Maximum allowed size: \(maxSize) bytes."
        }
    }
}
