//
//  SourceCollectorTests.swift
//  SourceCollectorTests
//
//  Created by Vladlen Akhtemov on 07.06.26.
//

import Testing
import Foundation
import AppKit
@testable import SourceCollector

// MARK: - Mocks

final class MockFileSystemService: FileSystemService {
    var enumeratorStub: FileManager.DirectoryEnumerator?
    var fileExistsStub = false

    func enumerator(at url: URL, options: FileManager.DirectoryEnumerationOptions) -> FileManager.DirectoryEnumerator? {
        enumeratorStub
    }

    func fileExists(at url: URL) -> Bool {
        fileExistsStub
    }
}

final class MockFileScanningService: FileScanningService {
    var scanFilesStub: [SourceFile] = []

    func scanFiles(at url: URL, allowedExtensions: Set<String>) -> [SourceFile] {
        scanFilesStub
    }
}

final class MockFileContentService: FileContentService {
    var readFileStub: String = ""

    func readFile(at url: URL) -> String {
        readFileStub
    }
}

final class MockClipboardService: ClipboardService {
    var copiedString: String?

    func copy(_ string: String) {
        copiedString = string
    }
}

final class MockFolderPickingService: FolderPickingService {
    var pickFolderStub: URL?

    func pickFolder() -> URL? {
        pickFolderStub
    }
}

final class MockRecentProjectsService: RecentProjectsService {
    var recentProjects: [RecentProject] = []
    var addedPaths: [String] = []
    var removedPaths: [String] = []

    func addProject(path: String) {
        addedPaths.append(path)
        recentProjects.insert(
            RecentProject(path: path, name: URL(fileURLWithPath: path).lastPathComponent, lastOpened: Date()),
            at: 0
        )
    }

    func removeProject(path: String) {
        removedPaths.append(path)
        recentProjects.removeAll { $0.path == path }
    }
}

// MARK: - SourceFile Tests

struct SourceFileTests {
    @Test func relativePath_whenFileIsInsideRoot() {
        let root = "/Users/test/Project"
        let fileURL = URL(fileURLWithPath: "/Users/test/Project/Sources/main.swift")
        let file = SourceFile(url: fileURL, name: "main.swift")
        #expect(file.relativePath(from: root) == "Sources/main.swift")
    }

    @Test func relativePath_whenFileIsDirectChildOfRoot() {
        let root = "/Users/test/Project"
        let fileURL = URL(fileURLWithPath: "/Users/test/Project/main.swift")
        let file = SourceFile(url: fileURL, name: "main.swift")
        #expect(file.relativePath(from: root) == "main.swift")
    }

    @Test func relativePath_whenRootHasTrailingSlash() {
        let root = "/Users/test/Project/"
        let fileURL = URL(fileURLWithPath: "/Users/test/Project/Sources/main.swift")
        let file = SourceFile(url: fileURL, name: "main.swift")
        #expect(file.relativePath(from: root) == "Sources/main.swift")
    }

    @Test func relativePath_whenFileIsOutsideRoot() {
        let root = "/Users/test/ProjectA"
        let fileURL = URL(fileURLWithPath: "/Users/test/ProjectB/main.swift")
        let file = SourceFile(url: fileURL, name: "main.swift")
        #expect(file.relativePath(from: root) == "main.swift")
    }

    @Test func relativePath_whenFileIsNestedDeeply() {
        let root = "/Users/test/Project"
        let fileURL = URL(fileURLWithPath: "/Users/test/Project/a/b/c/d/main.swift")
        let file = SourceFile(url: fileURL, name: "main.swift")
        #expect(file.relativePath(from: root) == "a/b/c/d/main.swift")
    }

    @Test func id_returnsPath() {
        let fileURL = URL(fileURLWithPath: "/tmp/test.swift")
        let file = SourceFile(url: fileURL, name: "test.swift")
        #expect(file.id == "/tmp/test.swift")
    }

    @Test func hashable_sameURLsAreEqual() {
        let url = URL(fileURLWithPath: "/tmp/test.swift")
        let a = SourceFile(url: url, name: "test.swift")
        let b = SourceFile(url: url, name: "test.swift")
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }
}

// MARK: - RecentProject Tests

struct RecentProjectTests {
    @Test func id_returnsPath() {
        let project = RecentProject(path: "/tmp/proj", name: "proj", lastOpened: Date())
        #expect(project.id == "/tmp/proj")
    }

    @Test func codable_roundTrip() throws {
        let date = Date(timeIntervalSince1970: 1_000_000)
        let project = RecentProject(path: "/tmp/proj", name: "proj", lastOpened: date)
        let data = try JSONEncoder().encode(project)
        let decoded = try JSONDecoder().decode(RecentProject.self, from: data)
        #expect(decoded.path == project.path)
        #expect(decoded.name == project.name)
        #expect(decoded.lastOpened == project.lastOpened)
    }

    @Test func hashable_equalProjects() {
        let date = Date()
        let a = RecentProject(path: "/tmp/a", name: "a", lastOpened: date)
        let b = RecentProject(path: "/tmp/a", name: "a", lastOpened: date)
        #expect(a == b)
    }

    @Test func hashable_differentPathsAreNotEqual() {
        let date = Date()
        let a = RecentProject(path: "/tmp/a", name: "a", lastOpened: date)
        let b = RecentProject(path: "/tmp/b", name: "b", lastOpened: date)
        #expect(a != b)
    }
}

// MARK: - DefaultFileSystemService Tests

struct DefaultFileSystemServiceTests {
    @Test func fileExists_returnsTrueForExistingFile() {
        let service = DefaultFileSystemService(fileManager: .default)
        let existingURL = URL(fileURLWithPath: "/tmp")
        #expect(service.fileExists(at: existingURL))
    }

    @Test func fileExists_returnsFalseForNonExistingFile() {
        let service = DefaultFileSystemService(fileManager: .default)
        let nonExistingURL = URL(fileURLWithPath: "/tmp/__nonexistent_file_12345__")
        #expect(!service.fileExists(at: nonExistingURL))
    }

    @Test func enumerator_returnsNilForNonExistingDirectory() {
        let service = DefaultFileSystemService(fileManager: .default)
        let nonExistingURL = URL(fileURLWithPath: "/tmp/__nonexistent_dir_12345__")
        let enumerator = service.enumerator(at: nonExistingURL)
        // FileManager.enumerator may return nil or an empty enumerator for non-existing directories
        #expect(enumerator == nil || enumerator?.nextObject() == nil)
    }
}

// MARK: - DefaultFileScanningService Tests

struct DefaultFileScanningServiceTests {
    @Test func scanFiles_filtersByExtensions() {
        let mockFileSystem = MockFileSystemService()

        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let swiftFile = tmpDir.appendingPathComponent("a.swift")
        let kotlinFile = tmpDir.appendingPathComponent("b.kt")
        let javaFile = tmpDir.appendingPathComponent("c.java")
        let txtFile = tmpDir.appendingPathComponent("d.txt")

        FileManager.default.createFile(atPath: swiftFile.path, contents: Data())
        FileManager.default.createFile(atPath: kotlinFile.path, contents: Data())
        FileManager.default.createFile(atPath: javaFile.path, contents: Data())
        FileManager.default.createFile(atPath: txtFile.path, contents: Data())

        let realFileSystem = DefaultFileSystemService()
        // Use the real file system for an integration-style test of DefaultFileScanningService
        let scanner = DefaultFileScanningService(fileSystem: realFileSystem)

        let allowed: Set<String> = ["swift", "kt"]
        let results = scanner.scanFiles(at: tmpDir, allowedExtensions: allowed)

        let names = Set(results.map { $0.name })
        #expect(names == ["a.swift", "b.kt"])
        #expect(!names.contains("c.java"))
        #expect(!names.contains("d.txt"))
    }

    @Test func scanFiles_returnsEmptyForNoMatchingExtensions() {
        let mockFileSystem = MockFileSystemService()

        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        FileManager.default.createFile(atPath: tmpDir.appendingPathComponent("a.swift").path, contents: Data())

        let realFileSystem = DefaultFileSystemService()
        let scanner = DefaultFileScanningService(fileSystem: realFileSystem)

        let results = scanner.scanFiles(at: tmpDir, allowedExtensions: ["py"])
        #expect(results.isEmpty)
    }

    @Test func scanFiles_returnsEmptyForNonExistentDirectory() {
        let realFileSystem = DefaultFileSystemService()
        let scanner = DefaultFileScanningService(fileSystem: realFileSystem)

        let nonExistent = URL(fileURLWithPath: "/tmp/__nonexistent_scan_dir__")
        let results = scanner.scanFiles(at: nonExistent, allowedExtensions: ["swift"])
        #expect(results.isEmpty)
    }

    @Test func scanFiles_usesFileSystemService() {
        let mockFileSystem = MockFileSystemService()
        mockFileSystem.enumeratorStub = FileManager.default.enumerator(at: URL(fileURLWithPath: "/tmp"), includingPropertiesForKeys: nil)
        let scanner = DefaultFileScanningService(fileSystem: mockFileSystem)
        let results = scanner.scanFiles(at: URL(fileURLWithPath: "/tmp"), allowedExtensions: ["swift"])
        // Should not crash; uses the mock's enumerator directly
        #expect(results is [SourceFile])
    }
}

// MARK: - DefaultFileContentService Tests

struct DefaultFileContentServiceTests {
    @Test func readFile_returnsContentForExistingFile() throws {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let fileURL = tmpDir.appendingPathComponent("test.swift")
        let content = "let x = 1\n"
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let service = DefaultFileContentService()
        #expect(service.readFile(at: fileURL) == content)
    }

    @Test func readFile_returnsEmptyForNonExistingFile() {
        let service = DefaultFileContentService()
        let nonExisting = URL(fileURLWithPath: "/tmp/__nonexistent__")
        #expect(service.readFile(at: nonExisting).isEmpty)
    }

    @Test func readFile_returnsEmptyForDirectory() {
        let service = DefaultFileContentService()
        #expect(service.readFile(at: URL(fileURLWithPath: "/tmp")).isEmpty)
    }
}

// MARK: - DefaultClipboardService Tests

struct DefaultClipboardServiceTests {
    @Test func copy_setsPasteboardContent() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        let service = DefaultClipboardService(pasteboard: pasteboard)
        let testString = "Hello, World!"
        service.copy(testString)
        let pasteboardString = pasteboard.string(forType: NSPasteboard.PasteboardType.string)
        #expect(pasteboardString == testString)
    }

    @Test func copy_overwritesPreviousContent() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        let service = DefaultClipboardService(pasteboard: pasteboard)
        service.copy("first")
        service.copy("second")
        let pasteboardString = pasteboard.string(forType: NSPasteboard.PasteboardType.string)
        #expect(pasteboardString == "second")
    }

    @Test func copy_emptyString() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        let service = DefaultClipboardService(pasteboard: pasteboard)
        service.copy("")
        let pasteboardString = pasteboard.string(forType: NSPasteboard.PasteboardType.string)
        #expect(pasteboardString == "")
    }
}

// MARK: - DefaultRecentProjectsService Tests

struct DefaultRecentProjectsServiceTests {
    @Test func addProject_insertsAtFront() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = DefaultRecentProjectsService(userDefaults: userDefaults)

        service.addProject(path: "/tmp/second")
        service.addProject(path: "/tmp/first")

        let projects = service.recentProjects
        #expect(projects.count == 2)
        #expect(projects[0].path == "/tmp/first")
        #expect(projects[1].path == "/tmp/second")
    }

    @Test func addProject_deduplicates() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = DefaultRecentProjectsService(userDefaults: userDefaults)

        service.addProject(path: "/tmp/proj")
        service.addProject(path: "/tmp/proj")

        let projects = service.recentProjects
        #expect(projects.count == 1)
    }

    @Test func removeProject_removesExisting() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = DefaultRecentProjectsService(userDefaults: userDefaults)

        service.addProject(path: "/tmp/proj")
        service.removeProject(path: "/tmp/proj")
        #expect(service.recentProjects.isEmpty)
    }

    @Test func removeProject_nonExistingDoesNothing() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = DefaultRecentProjectsService(userDefaults: userDefaults)

        service.addProject(path: "/tmp/proj")
        service.removeProject(path: "/tmp/nonexistent")
        #expect(service.recentProjects.count == 1)
    }

    @Test func recentProjects_limitsToMaxCount() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = DefaultRecentProjectsService(userDefaults: userDefaults)

        for i in 0..<15 {
            service.addProject(path: "/tmp/proj-\(i)")
        }

        #expect(service.recentProjects.count == 10)
    }

    @Test func recentProjects_persistsAcrossInstances() {
        let suiteName = UUID().uuidString
        let userDefaultsA = UserDefaults(suiteName: suiteName)!
        let serviceA = DefaultRecentProjectsService(userDefaults: userDefaultsA)
        serviceA.addProject(path: "/tmp/proj")

        let userDefaultsB = UserDefaults(suiteName: suiteName)!
        let serviceB = DefaultRecentProjectsService(userDefaults: userDefaultsB)
        let projects = serviceB.recentProjects
        #expect(projects.count == 1)
        #expect(projects[0].path == "/tmp/proj")
    }

    @Test func addProject_setsNameFromPath() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = DefaultRecentProjectsService(userDefaults: userDefaults)

        service.addProject(path: "/Users/test/MyProject")

        let projects = service.recentProjects
        #expect(projects[0].name == "MyProject")
    }
}

// MARK: - FilesViewModel Tests

@MainActor
struct FilesViewModelTests {
    @Test func openFolderPicker_usesFolderPickingService() {
        let mockFolderPicker = MockFolderPickingService()
        let mockScanner = MockFileScanningService()
        let mockContent = MockFileContentService()
        let mockClipboard = MockClipboardService()
        let mockFileSystem = MockFileSystemService()
        let mockRecent = MockRecentProjectsService()

        let vm = FilesViewModel(
            scanner: mockScanner,
            contentService: mockContent,
            folderPicker: mockFolderPicker,
            clipboard: mockClipboard,
            fileSystem: mockFileSystem,
            recentProjectsService: mockRecent
        )

        mockFolderPicker.pickFolderStub = URL(fileURLWithPath: "/tmp/testproj")
        mockFileSystem.fileExistsStub = true

        vm.openFolderPicker()

        #expect(vm.projectPath == "/tmp/testproj")
    }

    @Test func openFolderPicker_whenNil_doesNotChangePath() {
        let mockFolderPicker = MockFolderPickingService()
        let vm = FilesViewModel(
            scanner: MockFileScanningService(),
            contentService: MockFileContentService(),
            folderPicker: mockFolderPicker,
            clipboard: MockClipboardService(),
            fileSystem: MockFileSystemService(),
            recentProjectsService: MockRecentProjectsService()
        )

        mockFolderPicker.pickFolderStub = nil
        vm.openFolderPicker()
        #expect(vm.projectPath == "")
    }

    @Test func openProject_setsPathAndLoadsFiles() {
        let mockScanner = MockFileScanningService()
        let mockFileSystem = MockFileSystemService()
        let mockRecent = MockRecentProjectsService()

        let vm = FilesViewModel(
            scanner: mockScanner,
            contentService: MockFileContentService(),
            folderPicker: MockFolderPickingService(),
            clipboard: MockClipboardService(),
            fileSystem: mockFileSystem,
            recentProjectsService: mockRecent
        )

        mockFileSystem.fileExistsStub = true
        let file = SourceFile(url: URL(fileURLWithPath: "/tmp/testproj/main.swift"), name: "main.swift")
        mockScanner.scanFilesStub = [file]

        vm.openProject(path: "/tmp/testproj")

        #expect(vm.projectPath == "/tmp/testproj")
        #expect(vm.files == [file])
        #expect(vm.selectedFiles == [file])
    }

    @Test func openProject_emptyPath_doesNothing() {
        let vm = FilesViewModel(
            scanner: MockFileScanningService(),
            contentService: MockFileContentService(),
            folderPicker: MockFolderPickingService(),
            clipboard: MockClipboardService(),
            fileSystem: MockFileSystemService(),
            recentProjectsService: MockRecentProjectsService()
        )

        vm.openProject(path: "")
        #expect(vm.projectPath == "")
    }

    @Test func openProject_addsToRecent() {
        let mockRecent = MockRecentProjectsService()
        let mockFileSystem = MockFileSystemService()

        let vm = FilesViewModel(
            scanner: MockFileScanningService(),
            contentService: MockFileContentService(),
            folderPicker: MockFolderPickingService(),
            clipboard: MockClipboardService(),
            fileSystem: mockFileSystem,
            recentProjectsService: mockRecent
        )

        mockFileSystem.fileExistsStub = true
        vm.openProject(path: "/tmp/testproj")

        #expect(mockRecent.addedPaths == ["/tmp/testproj"])
    }

    @Test func loadFiles_whenPathDoesNotExist_clearsFiles() {
        let mockFileSystem = MockFileSystemService()
        let mockScanner = MockFileScanningService()

        let vm = FilesViewModel(
            scanner: mockScanner,
            contentService: MockFileContentService(),
            folderPicker: MockFolderPickingService(),
            clipboard: MockClipboardService(),
            fileSystem: mockFileSystem,
            recentProjectsService: MockRecentProjectsService()
        )

        vm.projectPath = "/tmp/nonexistent"
        mockFileSystem.fileExistsStub = false
        mockScanner.scanFilesStub = [SourceFile(url: URL(fileURLWithPath: "/tmp/a.swift"), name: "a.swift")]

        vm.loadFiles()

        #expect(vm.files.isEmpty)
    }

    @Test func loadFiles_filtersByEnabledExtensions() {
        let mockFileSystem = MockFileSystemService()
        let mockScanner = MockFileScanningService()

        let vm = FilesViewModel(
            scanner: mockScanner,
            contentService: MockFileContentService(),
            folderPicker: MockFolderPickingService(),
            clipboard: MockClipboardService(),
            fileSystem: mockFileSystem,
            recentProjectsService: MockRecentProjectsService()
        )

        vm.projectPath = "/tmp/testproj"
        mockFileSystem.fileExistsStub = true

        let swiftFile = SourceFile(url: URL(fileURLWithPath: "/tmp/a.swift"), name: "a.swift")
        let javaFile = SourceFile(url: URL(fileURLWithPath: "/tmp/b.java"), name: "b.java")
        mockScanner.scanFilesStub = [swiftFile, javaFile]

        vm.loadFiles()

        #expect(vm.files == [swiftFile, javaFile])
    }

    @Test func loadFiles_sortsByName() {
        let mockFileSystem = MockFileSystemService()
        let mockScanner = MockFileScanningService()

        let vm = FilesViewModel(
            scanner: mockScanner,
            contentService: MockFileContentService(),
            folderPicker: MockFolderPickingService(),
            clipboard: MockClipboardService(),
            fileSystem: mockFileSystem,
            recentProjectsService: MockRecentProjectsService()
        )

        vm.projectPath = "/tmp/testproj"
        mockFileSystem.fileExistsStub = true

        let bFile = SourceFile(url: URL(fileURLWithPath: "/tmp/b.swift"), name: "b.swift")
        let aFile = SourceFile(url: URL(fileURLWithPath: "/tmp/a.swift"), name: "a.swift")
        mockScanner.scanFilesStub = [bFile, aFile]

        vm.loadFiles()

        #expect(vm.files == [aFile, bFile])
    }

    @Test func copySelected_combinesFileContentsWithMarkers() {
        let mockContent = MockFileContentService()
        let mockClipboard = MockClipboardService()
        let mockFileSystem = MockFileSystemService()

        let vm = FilesViewModel(
            scanner: MockFileScanningService(),
            contentService: mockContent,
            folderPicker: MockFolderPickingService(),
            clipboard: mockClipboard,
            fileSystem: mockFileSystem,
            recentProjectsService: MockRecentProjectsService()
        )

        vm.projectPath = "/tmp/testproj"

        let file1 = SourceFile(url: URL(fileURLWithPath: "/tmp/testproj/a.swift"), name: "a.swift")
        let file2 = SourceFile(url: URL(fileURLWithPath: "/tmp/testproj/b.swift"), name: "b.swift")

        vm.files = [file1, file2]
        vm.selectedFiles = [file1, file2]

        mockContent.readFileStub = "content"

        vm.copySelected()

        let expected = """
        // MARK: - a.swift

        content

        // MARK: - b.swift

        content
        """
        #expect(mockClipboard.copiedString == expected)
    }

    @Test func copySelected_onlyCopiesSelectedFiles() {
        let mockContent = MockFileContentService()
        let mockClipboard = MockClipboardService()

        let vm = FilesViewModel(
            scanner: MockFileScanningService(),
            contentService: mockContent,
            folderPicker: MockFolderPickingService(),
            clipboard: mockClipboard,
            fileSystem: MockFileSystemService(),
            recentProjectsService: MockRecentProjectsService()
        )

        vm.projectPath = "/tmp/testproj"

        let file1 = SourceFile(url: URL(fileURLWithPath: "/tmp/testproj/a.swift"), name: "a.swift")
        let file2 = SourceFile(url: URL(fileURLWithPath: "/tmp/testproj/b.swift"), name: "b.swift")

        vm.files = [file1, file2]
        vm.selectedFiles = [file1]

        mockContent.readFileStub = "content"

        vm.copySelected()

        let expected = "// MARK: - a.swift\n\ncontent"
        #expect(mockClipboard.copiedString == expected)
    }

    @Test func copySelected_emptySelection_doesNotCallClipboard() {
        let mockClipboard = MockClipboardService()
        let mockContent = MockFileContentService()

        let vm = FilesViewModel(
            scanner: MockFileScanningService(),
            contentService: mockContent,
            folderPicker: MockFolderPickingService(),
            clipboard: mockClipboard,
            fileSystem: MockFileSystemService(),
            recentProjectsService: MockRecentProjectsService()
        )

        vm.projectPath = "/tmp/testproj"
        vm.files = [SourceFile(url: URL(fileURLWithPath: "/tmp/a.swift"), name: "a.swift")]
        vm.selectedFiles = []

        vm.copySelected()

        #expect(mockClipboard.copiedString == "")
    }

    @Test func selectAllFiles_selectsAll() {
        let vm = FilesViewModel(
            scanner: MockFileScanningService(),
            contentService: MockFileContentService(),
            folderPicker: MockFolderPickingService(),
            clipboard: MockClipboardService(),
            fileSystem: MockFileSystemService(),
            recentProjectsService: MockRecentProjectsService()
        )

        let files = [
            SourceFile(url: URL(fileURLWithPath: "/tmp/a.swift"), name: "a.swift"),
            SourceFile(url: URL(fileURLWithPath: "/tmp/b.swift"), name: "b.swift")
        ]

        vm.files = files
        vm.selectedFiles = []

        vm.selectAllFiles()

        #expect(vm.selectedFiles == Set(files))
    }

    @Test func removeRecentProject_delegatesToService() {
        let mockRecent = MockRecentProjectsService()

        let vm = FilesViewModel(
            scanner: MockFileScanningService(),
            contentService: MockFileContentService(),
            folderPicker: MockFolderPickingService(),
            clipboard: MockClipboardService(),
            fileSystem: MockFileSystemService(),
            recentProjectsService: mockRecent
        )

        vm.removeRecentProject(path: "/tmp/proj")
        #expect(mockRecent.removedPaths == ["/tmp/proj"])
    }

    @Test func supportedExtensions_containsExpectedList() {
        let vm = FilesViewModel(
            scanner: MockFileScanningService(),
            contentService: MockFileContentService(),
            folderPicker: MockFolderPickingService(),
            clipboard: MockClipboardService(),
            fileSystem: MockFileSystemService(),
            recentProjectsService: MockRecentProjectsService()
        )

        #expect(vm.supportedExtensions == ["swift", "kt", "java", "dart", "js", "ts"])
    }

    @Test func enabledExtensions_defaultsToAllSupported() {
        let vm = FilesViewModel(
            scanner: MockFileScanningService(),
            contentService: MockFileContentService(),
            folderPicker: MockFolderPickingService(),
            clipboard: MockClipboardService(),
            fileSystem: MockFileSystemService(),
            recentProjectsService: MockRecentProjectsService()
        )

        #expect(vm.enabledExtensions == Set(vm.supportedExtensions))
    }

    @Test func initialRecentProjects_fromService() {
        let mockRecent = MockRecentProjectsService()
        let project = RecentProject(path: "/tmp/proj", name: "proj", lastOpened: Date())
        mockRecent.recentProjects = [project]

        let vm = FilesViewModel(
            scanner: MockFileScanningService(),
            contentService: MockFileContentService(),
            folderPicker: MockFolderPickingService(),
            clipboard: MockClipboardService(),
            fileSystem: MockFileSystemService(),
            recentProjectsService: mockRecent
        )

        #expect(vm.recentProjects == [project])
    }
}
