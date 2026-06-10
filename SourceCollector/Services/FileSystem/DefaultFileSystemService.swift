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

      func enumerator(at url: URL, options: FileManager.DirectoryEnumerationOptions) -> DirectoryEnumerator? {
          fileManager.enumerator(at: url, includingPropertiesForKeys: nil, options: options)
      }

     func fileExists(at url: URL) -> Bool {
         fileManager.fileExists(atPath: url.path)
     }

     func startAccessingSecurityScopedResource(for url: URL) -> Bool {
         url.startAccessingSecurityScopedResource()
     }

     func stopAccessingSecurityScopedResource(for url: URL) {
         url.stopAccessingSecurityScopedResource()
     }
 }
