//
 //  RecentProject.swift
 //  SourceCollector
 //
 //  Created by Vladlen Akhtemov on 07.06.26.
 //

 import Foundation

 struct RecentProject: Identifiable, Hashable, Codable {
     var id: String { path }
     let path: String
     let name: String
     let lastOpened: Date
     let bookmarkData: Data?
 }
