//
 //  SourceFile.swift
 //  SourceCollector
 //
 //  Created by Vladlen Akhtemov on 07.06.26.
 //

 import Foundation

 struct SourceFile: Identifiable, Hashable {

     var id: String {
         url.path
     }

     let url: URL
     let name: String

     func relativePath(from root: String) -> String {
         let rootURL = URL(fileURLWithPath: root).standardizedFileURL
         let fileURL = url.standardizedFileURL

         let rootPath = rootURL.path.hasSuffix("/") ? rootURL.path : rootURL.path + "/"

         guard fileURL.path == rootURL.path || fileURL.path.hasPrefix(rootPath) else {
             return fileURL.lastPathComponent
         }

         let relativePath = fileURL.path.dropFirst(rootPath.count)
         return String(relativePath).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
     }
 }
