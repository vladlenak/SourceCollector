//
//  FileScanningService.swift
//  SourceCollector
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import Foundation

protocol FileScanningService {

    func scanFiles(at url: URL, allowedExtensions: Set<String>) -> [SourceFile]

}
