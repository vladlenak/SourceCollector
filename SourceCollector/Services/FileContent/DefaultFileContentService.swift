//
//  DefaultFileContentService.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import Foundation

final class DefaultFileContentService: FileContentService {

    func readFile(at url: URL) throws -> String {
        try String(contentsOf: url)
    }

}
