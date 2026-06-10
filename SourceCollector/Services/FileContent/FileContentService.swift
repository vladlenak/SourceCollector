//
//  FileContentService.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import Foundation

protocol FileContentService {

    func readFile(at url: URL) throws -> String

}
