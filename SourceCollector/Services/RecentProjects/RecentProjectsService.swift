//
 //  RecentProjectsService.swift
 //  SourceCollector
 //
 //  Created by Vladlen Akhtemov on 07.06.26.
 //

 import Foundation
 import os

 protocol RecentProjectsService {
     var recentProjects: [RecentProject] { get }
     func addProject(path: String, bookmarkData: Data?)
     func removeProject(path: String)
 }

 final class DefaultRecentProjectsService: RecentProjectsService {

     private let maxCount = 10
     private let userDefaultsKey = "recentProjects"
     private let userDefaults: UserDefaults

     init(userDefaults: UserDefaults = .standard) {
         self.userDefaults = userDefaults
     }

     var recentProjects: [RecentProject] {
         loadProjects()
     }

     func addProject(path: String, bookmarkData: Data?) {
         var projects = loadProjects()
         projects.removeAll { $0.path == path }
         let project = RecentProject(
             path: path,
             name: URL(fileURLWithPath: path).lastPathComponent,
             lastOpened: Date(),
             bookmarkData: bookmarkData
         )
         projects.insert(project, at: 0)
         if projects.count > maxCount {
             projects = Array(projects.prefix(maxCount))
         }
         saveProjects(projects)
     }

     func removeProject(path: String) {
         var projects = loadProjects()
         projects.removeAll { $0.path == path }
         saveProjects(projects)
     }

     private func loadProjects() -> [RecentProject] {
         guard let data = userDefaults.data(forKey: userDefaultsKey) else {
             return []
         }
         do {
             return try JSONDecoder().decode([RecentProject].self, from: data)
         } catch {
             os_log("Failed to decode recent projects: %@", type: .error, error.localizedDescription)
             userDefaults.removeObject(forKey: userDefaultsKey)
             return []
         }
     }

     private func saveProjects(_ projects: [RecentProject]) {
         do {
             let data = try JSONEncoder().encode(projects)
             userDefaults.set(data, forKey: userDefaultsKey)
         } catch {
             os_log("Failed to encode recent projects: %@", type: .error, error.localizedDescription)
         }
     }
 }
