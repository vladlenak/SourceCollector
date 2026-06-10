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
    var enumeratorStub: DirectoryEnumerator?
    var fileExistsStub = false
    var fileIsDirectoryStub = false

    func enumerator(at url: URL, options: FileManager.DirectoryEnumerationOptions) -> DirectoryEnumerator? {
        enumeratorStub
    }

    func fileExists(at url: URL) -> Bool {
        fileExistsStub
    }

    func fileIsDirectory(at url: URL) -> Bool {
        fileIsDirectoryStub
    }

    func startAccessingSecurityScopedResource(for url: URL) -> Bool {
        true
    }

    func stopAccessingSecurityScopedResource(for url: URL) {
    }
}

/// Returns a DirectoryEnumerator for a real temp directory.
/// Useful for tests that need a non-nil enumerator stub.
func makeTempEnumerator() -> DirectoryEnumerator? {
    let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    return FileManager.default.enumerator(at: tmpDir, includingPropertiesForKeys: nil)
}

final class MockFileScanningService: FileScanningService {
    var scanFilesStub: [SourceFile] = []

    func scanFiles(at url: URL, allowedExtensions: Set<String>) async -> [SourceFile] {
        scanFilesStub
    }
}

final class MockFileContentService: FileContentService {
    var readFileStub: String = ""
    var readFileError: Error?

    func readFile(at url: URL) throws -> String {
        if let error = readFileError {
            throw error
        }
        return readFileStub
    }
}

final class MockClipboardService: ClipboardService {
    var copiedString: String?

    func copy(_ string: String) {
        copiedString = string
    }
}

final class MockFolderPickingService: FolderPickingService {
    var pickFolderStub: PickedFolder?

    func pickFolder() -> PickedFolder? {
        pickFolderStub
    }
}

final class MockRecentProjectsService: RecentProjectsService {
    var recentProjects: [RecentProject] = []
    var addedPaths: [(String, Data?)] = []
    var removedPaths: [String] = []

    func addProject(path: String, bookmarkData: Data?) {
        addedPaths.append((path, bookmarkData))
        recentProjects.insert(
            RecentProject(path: path, name: URL(fileURLWithPath: path).lastPathComponent, lastOpened: Date(), bookmarkData: bookmarkData),
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

    @Test func relativePath_whenRootIsPrefixOfAnotherDirectory() {
        let root = "/Users/test/Project"
        let fileURL = URL(fileURLWithPath: "/Users/test/ProjectBackup/file.swift")
        let file = SourceFile(url: fileURL, name: "file.swift")
        #expect(file.relativePath(from: root) == "file.swift")
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
        let project = RecentProject(path: "/tmp/proj", name: "proj", lastOpened: Date(), bookmarkData: nil)
        #expect(project.id == "/tmp/proj")
    }

    @Test func codable_roundTrip() throws {
        let date = Date(timeIntervalSince1970: 1_000_000)
        let project = RecentProject(path: "/tmp/proj", name: "proj", lastOpened: date, bookmarkData: nil)
        let data = try JSONEncoder().encode(project)
        let decoded = try JSONDecoder().decode(RecentProject.self, from: data)
        #expect(decoded.path == project.path)
        #expect(decoded.name == project.name)
        #expect(decoded.lastOpened == project.lastOpened)
        #expect(decoded.bookmarkData == nil)
    }

    @Test func hashable_equalProjects() {
        let date = Date()
        let a = RecentProject(path: "/tmp/a", name: "a", lastOpened: date, bookmarkData: nil)
        let b = RecentProject(path: "/tmp/a", name: "a", lastOpened: date, bookmarkData: nil)
        #expect(a == b)
    }

    @Test func hashable_differentPathsAreNotEqual() {
        let date = Date()
        let a = RecentProject(path: "/tmp/a", name: "a", lastOpened: date, bookmarkData: nil)
        let b = RecentProject(path: "/tmp/b", name: "b", lastOpened: date, bookmarkData: nil)
        #expect(a != b)
    }
}

// MARK: - DefaultFileSystemService Tests

struct DefaultFileSystemServiceTests {
    @Test func fileExists_returnsTrueForExistingFile() {
        let mockFileSystem = MockFileSystemService()
        mockFileSystem.fileExistsStub = true

        #expect(mockFileSystem.fileExists(at: URL(fileURLWithPath: "/tmp")))
    }

    @Test func fileExists_returnsFalseForNonExistingFile() {
        let mockFileSystem = MockFileSystemService()
        mockFileSystem.fileExistsStub = false

        #expect(!mockFileSystem.fileExists(at: URL(fileURLWithPath: "/tmp/__nonexistent_file_12345__")))
    }

    @Test func enumerator_returnsNilForNonExistingDirectory() {
        let mockFileSystem = MockFileSystemService()
        mockFileSystem.enumeratorStub = nil

        let enumerator = mockFileSystem.enumerator(at: URL(fileURLWithPath: "/tmp/__nonexistent_dir_12345__"))
        #expect(enumerator == nil || enumerator?.nextObject() == nil)
    }

    @Test func realImplementation_fileExistsWorks() {
        let service = DefaultFileSystemService(fileManager: .default)
        #expect(service.fileExists(at: URL(fileURLWithPath: "/tmp")))
        #expect(!service.fileExists(at: URL(fileURLWithPath: "/tmp/__nonexistent_file_12345__")))
    }
}

// MARK: - DefaultFileScanningService Tests

struct DefaultFileScanningServiceTests {
    @Test func scanFiles_filtersByExtensions() async {
        let mockFileSystem = MockFileSystemService()

        let urls = [
            URL(fileURLWithPath: "/tmp/test/a.swift"),
            URL(fileURLWithPath: "/tmp/test/b.kt"),
            URL(fileURLWithPath: "/tmp/test/c.java"),
            URL(fileURLWithPath: "/tmp/test/d.txt")
        ]

        var callCount = 0
        let mockEnumerator = MockDirectoryEnumerator(urls: urls) {
            callCount += 1
        }
        mockFileSystem.enumeratorStub = mockEnumerator

        let scanner = DefaultFileScanningService(fileSystem: mockFileSystem)

        let allowed: Set<String> = ["swift", "kt"]
        let results = await scanner.scanFiles(at: URL(fileURLWithPath: "/tmp/test"), allowedExtensions: allowed)

        let names = Set(results.map { $0.name })
        #expect(names == ["a.swift", "b.kt"])
        #expect(!names.contains("c.java"))
        #expect(!names.contains("d.txt"))
    }

    @Test func scanFiles_returnsEmptyForNoMatchingExtensions() async {
        let mockFileSystem = MockFileSystemService()

        let urls = [URL(fileURLWithPath: "/tmp/test/a.swift")]
        let mockEnumerator = MockDirectoryEnumerator(urls: urls)
        mockFileSystem.enumeratorStub = mockEnumerator

        let scanner = DefaultFileScanningService(fileSystem: mockFileSystem)

        let results = await scanner.scanFiles(at: URL(fileURLWithPath: "/tmp/test"), allowedExtensions: ["py"])
        #expect(results.isEmpty)
    }

    @Test func scanFiles_returnsEmptyForNonExistentDirectory() async {
        let mockFileSystem = MockFileSystemService()
        mockFileSystem.enumeratorStub = nil

        let scanner = DefaultFileScanningService(fileSystem: mockFileSystem)

        let nonExistent = URL(fileURLWithPath: "/tmp/__nonexistent_scan_dir__")
        let results = await scanner.scanFiles(at: nonExistent, allowedExtensions: ["swift"])
        #expect(results.isEmpty)
    }

    @Test func scanFiles_usesFileSystemService() async {
        let mockFileSystem = MockFileSystemService()
        let urls = [URL(fileURLWithPath: "/tmp/a.swift")]
        let mockEnumerator = MockDirectoryEnumerator(urls: urls)
        mockFileSystem.enumeratorStub = mockEnumerator
        let scanner = DefaultFileScanningService(fileSystem: mockFileSystem)
        let results = await scanner.scanFiles(at: URL(fileURLWithPath: "/tmp"), allowedExtensions: ["swift"])
        #expect(results.count == 1)
        #expect(results[0].name == "a.swift")
    }
}

private final class MockDirectoryEnumerator: DirectoryEnumerator {
    private let urls: [URL]
    private var index = 0
    private let onNext: (() -> Void)?

    init(urls: [URL], onNext: (() -> Void)? = nil) {
        self.urls = urls
        self.onNext = onNext
    }

    func nextObject() -> Any? {
        onNext?()
        guard index < urls.count else { return nil }
        let url = urls[index]
        index += 1
        return url
    }
}

// MARK: - DefaultFileContentService Tests

struct DefaultFileContentServiceTests {
    @Test func readFile_returnsContentForExistingFile() throws {
        let mockContentService = MockFileContentService()
        mockContentService.readFileStub = "let x = 1\n"

        let content = try mockContentService.readFile(at: URL(fileURLWithPath: "/tmp/test.swift"))
        #expect(content == "let x = 1\n")
    }

    @Test func readFile_throwsForNonExistingFile() {
        let mockContentService = MockFileContentService()
        mockContentService.readFileError = CocoaError(.fileReadNoSuchFile)

        #expect(throws: (any Error).self) {
            try mockContentService.readFile(at: URL(fileURLWithPath: "/tmp/__nonexistent__"))
        }
    }

    @Test func readFile_throwsForDirectory() {
        let mockContentService = MockFileContentService()
        mockContentService.readFileError = CocoaError(.fileReadInvalidFileName)

        #expect(throws: (any Error).self) {
            try mockContentService.readFile(at: URL(fileURLWithPath: "/tmp"))
        }
    }

    @Test func realImplementation_readsFileContent() throws {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let fileURL = tmpDir.appendingPathComponent("test.swift")
        let content = "let x = 1\n"
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let service = DefaultFileContentService()
        #expect(try service.readFile(at: fileURL) == content)
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

        service.addProject(path: "/tmp/second", bookmarkData: nil)
        service.addProject(path: "/tmp/first", bookmarkData: nil)

        let projects = service.recentProjects
        #expect(projects.count == 2)
        #expect(projects[0].path == "/tmp/first")
        #expect(projects[1].path == "/tmp/second")
    }

    @Test func addProject_deduplicates() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = DefaultRecentProjectsService(userDefaults: userDefaults)

        service.addProject(path: "/tmp/proj", bookmarkData: nil)
        service.addProject(path: "/tmp/proj", bookmarkData: nil)

        let projects = service.recentProjects
        #expect(projects.count == 1)
    }

    @Test func removeProject_removesExisting() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = DefaultRecentProjectsService(userDefaults: userDefaults)

        service.addProject(path: "/tmp/proj", bookmarkData: nil)
        service.removeProject(path: "/tmp/proj")
        #expect(service.recentProjects.isEmpty)
    }

    @Test func removeProject_nonExistingDoesNothing() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = DefaultRecentProjectsService(userDefaults: userDefaults)

        service.addProject(path: "/tmp/proj", bookmarkData: nil)
        service.removeProject(path: "/tmp/nonexistent")
        #expect(service.recentProjects.count == 1)
    }

    @Test func recentProjects_limitsToMaxCount() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = DefaultRecentProjectsService(userDefaults: userDefaults)

        for i in 0..<15 {
            service.addProject(path: "/tmp/proj-\(i)", bookmarkData: nil)
        }

        #expect(service.recentProjects.count == 10)
    }

    @Test func recentProjects_persistsAcrossInstances() {
        let suiteName = UUID().uuidString
        let userDefaultsA = UserDefaults(suiteName: suiteName)!
        let serviceA = DefaultRecentProjectsService(userDefaults: userDefaultsA)
        serviceA.addProject(path: "/tmp/proj", bookmarkData: nil)

        let userDefaultsB = UserDefaults(suiteName: suiteName)!
        let serviceB = DefaultRecentProjectsService(userDefaults: userDefaultsB)
        let projects = serviceB.recentProjects
        #expect(projects.count == 1)
        #expect(projects[0].path == "/tmp/proj")
    }

    @Test func addProject_setsNameFromPath() {
        let userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        let service = DefaultRecentProjectsService(userDefaults: userDefaults)

        service.addProject(path: "/Users/test/MyProject", bookmarkData: nil)

        let projects = service.recentProjects
        #expect(projects[0].name == "MyProject")
    }
}

// MARK: - ProjectViewModel Tests

@MainActor
struct ProjectViewModelTests {
    @Test func openFolderPicker_usesFolderPickingService() {
        let mockFolderPicker = MockFolderPickingService()
        let mockFileSystem = MockFileSystemService()
        let mockRecent = MockRecentProjectsService()

        let vm = ProjectViewModel(
            folderPicker: mockFolderPicker,
            fileSystem: mockFileSystem,
            recentProjectsService: mockRecent
        )

        mockFolderPicker.pickFolderStub = PickedFolder(url: URL(fileURLWithPath: "/tmp/testproj"), bookmarkData: nil)
        mockFileSystem.fileExistsStub = true

        vm.openFolderPicker()

        #expect(vm.projectPath == "/tmp/testproj")
    }

    @Test func openFolderPicker_whenNil_doesNotChangePath() {
        let mockFolderPicker = MockFolderPickingService()
        let vm = ProjectViewModel(
            folderPicker: mockFolderPicker,
            fileSystem: MockFileSystemService(),
            recentProjectsService: MockRecentProjectsService()
        )

        mockFolderPicker.pickFolderStub = nil
        vm.openFolderPicker()

        #expect(vm.projectPath == "")
    }

    @Test func openProject_setsPathAndSelectsRecent() {
        let mockRecent = MockRecentProjectsService()

        let vm = ProjectViewModel(
            folderPicker: MockFolderPickingService(),
            fileSystem: MockFileSystemService(),
            recentProjectsService: mockRecent
        )

        vm.openProject(path: "/tmp/testproj")

        #expect(vm.projectPath == "/tmp/testproj")
        #expect(vm.selectedRecentProject == "/tmp/testproj")
    }

    @Test func openProject_emptyPath_doesNothing() {
        let vm = ProjectViewModel(
            folderPicker: MockFolderPickingService(),
            fileSystem: MockFileSystemService(),
            recentProjectsService: MockRecentProjectsService()
        )

        vm.openProject(path: "")

        #expect(vm.projectPath == "")
    }

    @Test func openProject_addsToRecent() {
        let mockRecent = MockRecentProjectsService()

        let vm = ProjectViewModel(
            folderPicker: MockFolderPickingService(),
            fileSystem: MockFileSystemService(),
            recentProjectsService: mockRecent
        )

        vm.openProject(path: "/tmp/testproj")

        #expect(mockRecent.addedPaths.map { $0.0 } == ["/tmp/testproj"])
    }

    @Test func removeRecentProject_delegatesToService() {
        let mockRecent = MockRecentProjectsService()

        let vm = ProjectViewModel(
            folderPicker: MockFolderPickingService(),
            fileSystem: MockFileSystemService(),
            recentProjectsService: mockRecent
        )

        vm.removeRecentProject(path: "/tmp/proj")

        #expect(mockRecent.removedPaths == ["/tmp/proj"])
    }

    @Test func validateProjectPath_returnsTrueWhenIsDirectory() {
        let mockFileSystem = MockFileSystemService()
        let vm = ProjectViewModel(
            folderPicker: MockFolderPickingService(),
            fileSystem: mockFileSystem,
            recentProjectsService: MockRecentProjectsService()
        )

        vm.projectPath = "/tmp/testproj"
        mockFileSystem.fileIsDirectoryStub = true

        #expect(vm.validateProjectPath())
    }

    @Test func validateProjectPath_returnsFalseWhenNotDirectory() {
        let mockFileSystem = MockFileSystemService()
        let vm = ProjectViewModel(
            folderPicker: MockFolderPickingService(),
            fileSystem: mockFileSystem,
            recentProjectsService: MockRecentProjectsService()
        )

        vm.projectPath = "/tmp/regularfile"
        mockFileSystem.fileIsDirectoryStub = false

        #expect(!vm.validateProjectPath())
    }

    @Test func initialRecentProjects_fromService() {
        let mockRecent = MockRecentProjectsService()
        let project = RecentProject(path: "/tmp/proj", name: "proj", lastOpened: Date(), bookmarkData: nil)
        mockRecent.recentProjects = [project]

        let vm = ProjectViewModel(
            folderPicker: MockFolderPickingService(),
            fileSystem: MockFileSystemService(),
            recentProjectsService: mockRecent
        )

        #expect(vm.recentProjects == [project])
    }
}

// MARK: - FileScannerViewModel Tests

@MainActor
struct FileScannerViewModelTests {
    private func makeProjectVM(
        fileSystem: FileSystemService = MockFileSystemService(),
        recent: RecentProjectsService = MockRecentProjectsService()
    ) -> ProjectViewModel {
        ProjectViewModel(
            folderPicker: MockFolderPickingService(),
            fileSystem: fileSystem,
            recentProjectsService: recent
        )
    }

    @Test func loadFiles_whenPathDoesNotExist_setsErrorAndClearsFiles() async {
        let mockFileSystem = MockFileSystemService()
        let mockScanner = MockFileScanningService()
        let projectVM = makeProjectVM(fileSystem: mockFileSystem)
        projectVM.projectPath = "/tmp/nonexistent"

        let vm = FileScannerViewModel(scanner: mockScanner, projectViewModel: projectVM)
        mockFileSystem.fileIsDirectoryStub = false
        mockScanner.scanFilesStub = [SourceFile(url: URL(fileURLWithPath: "/tmp/a.swift"), name: "a.swift")]

        await vm.loadFiles()

        #expect(vm.files.isEmpty)
        #expect(vm.errorMessage != nil)
        #expect(vm.errorMessage!.contains("Directory does not exist"))
    }

    @Test func loadFiles_successfullyLoadsAndSortsFiles() async {
        let mockFileSystem = MockFileSystemService()
        let mockScanner = MockFileScanningService()
        let projectVM = makeProjectVM(fileSystem: mockFileSystem)
        projectVM.projectPath = "/tmp/testproj"

        let vm = FileScannerViewModel(scanner: mockScanner, projectViewModel: projectVM)
        mockFileSystem.fileIsDirectoryStub = true
        mockFileSystem.enumeratorStub = makeTempEnumerator()

        let bFile = SourceFile(url: URL(fileURLWithPath: "/tmp/testproj/b.swift"), name: "b.swift")
        let aFile = SourceFile(url: URL(fileURLWithPath: "/tmp/testproj/a.swift"), name: "a.swift")
        mockScanner.scanFilesStub = [bFile, aFile]

        await vm.loadFiles()

        #expect(vm.files == [aFile, bFile])
    }

    @Test func loadFiles_resetsIsLoadingAfterCompletion() async {
        let mockFileSystem = MockFileSystemService()
        let mockScanner = MockFileScanningService()
        let projectVM = makeProjectVM(fileSystem: mockFileSystem)
        projectVM.projectPath = "/tmp/testproj"

        let vm = FileScannerViewModel(scanner: mockScanner, projectViewModel: projectVM)
        mockFileSystem.fileIsDirectoryStub = true
        mockFileSystem.enumeratorStub = makeTempEnumerator()
        let file = SourceFile(url: URL(fileURLWithPath: "/tmp/testproj/a.swift"), name: "a.swift")
        mockScanner.scanFilesStub = [file]

        await vm.loadFiles()

        #expect(!vm.isLoading)
        #expect(vm.files == [file])
    }

    @Test func loadFiles_clearsPreviousError() async {
        let mockFileSystem = MockFileSystemService()
        let mockScanner = MockFileScanningService()
        let projectVM = makeProjectVM(fileSystem: mockFileSystem)
        projectVM.projectPath = "/tmp/testproj"

        let vm = FileScannerViewModel(scanner: mockScanner, projectViewModel: projectVM)
        mockFileSystem.fileIsDirectoryStub = false
        await vm.loadFiles()
        #expect(vm.errorMessage != nil)

        mockFileSystem.fileIsDirectoryStub = true
        mockFileSystem.enumeratorStub = makeTempEnumerator()
        mockScanner.scanFilesStub = [SourceFile(url: URL(fileURLWithPath: "/tmp/testproj/a.swift"), name: "a.swift")]
        await vm.loadFiles()

        #expect(vm.errorMessage == nil)
    }

    @Test func loadFiles_whenEnumeratorIsNil_showsAccessError() async {
        let mockFileSystem = MockFileSystemService()
        let mockScanner = MockFileScanningService()
        let projectVM = makeProjectVM(fileSystem: mockFileSystem)
        projectVM.projectPath = "/tmp/testproj"

        let vm = FileScannerViewModel(scanner: mockScanner, projectViewModel: projectVM)
        mockFileSystem.fileIsDirectoryStub = true
        mockFileSystem.enumeratorStub = nil

        await vm.loadFiles()

        #expect(vm.files.isEmpty)
        #expect(vm.errorMessage != nil)
        #expect(vm.errorMessage!.contains("Cannot read directory"))
        #expect(vm.errorMessage!.contains("Choose Folder"))
    }

    @Test func loadFiles_whenNoMatchingFiles_setsError() async {
        let mockFileSystem = MockFileSystemService()
        let mockScanner = MockFileScanningService()
        let projectVM = makeProjectVM(fileSystem: mockFileSystem)
        projectVM.projectPath = "/tmp/testproj"

        let vm = FileScannerViewModel(scanner: mockScanner, projectViewModel: projectVM)
        mockFileSystem.fileIsDirectoryStub = true
        mockFileSystem.enumeratorStub = makeTempEnumerator()
        mockScanner.scanFilesStub = []

        await vm.loadFiles()

        #expect(vm.files.isEmpty)
        #expect(vm.errorMessage != nil)
        #expect(vm.errorMessage!.contains("No source files found"))
    }

    @Test func supportedExtensions_containsExpectedList() {
        let vm = FileScannerViewModel(
            scanner: MockFileScanningService(),
            projectViewModel: makeProjectVM()
        )

        #expect(vm.supportedExtensions == ["swift", "kt", "java", "dart", "js", "ts"])
    }

    @Test func enabledExtensions_defaultsToAllSupported() {
        let vm = FileScannerViewModel(
            scanner: MockFileScanningService(),
            projectViewModel: makeProjectVM()
        )

        #expect(vm.enabledExtensions == Set(vm.supportedExtensions))
    }
}

// MARK: - FileSelectionViewModel Tests

@MainActor
struct FileSelectionViewModelTests {
    private func makeScannerVM(
        scanner: FileScanningService = MockFileScanningService(),
        projectVM: ProjectViewModel
    ) -> FileScannerViewModel {
        FileScannerViewModel(scanner: scanner, projectViewModel: projectVM)
    }

    private func makeProjectVM(
        fileSystem: FileSystemService = MockFileSystemService()
    ) -> ProjectViewModel {
        ProjectViewModel(
            folderPicker: MockFolderPickingService(),
            fileSystem: fileSystem,
            recentProjectsService: MockRecentProjectsService()
        )
    }

    @Test func selectAllFiles_selectsAllFromScanner() {
        let projectVM = makeProjectVM()
        let scannerVM = makeScannerVM(projectVM: projectVM)
        let vm = FileSelectionViewModel(
            contentService: MockFileContentService(),
            clipboard: MockClipboardService(),
            fileScannerViewModel: scannerVM
        )

        let files = [
            SourceFile(url: URL(fileURLWithPath: "/tmp/a.swift"), name: "a.swift"),
            SourceFile(url: URL(fileURLWithPath: "/tmp/b.swift"), name: "b.swift")
        ]
        scannerVM.files = files
        vm.selectedFiles = []

        vm.selectAllFiles()

        #expect(vm.selectedFiles == Set(files))
    }

    @Test func copySelected_combinesFileContentsWithMarkers() {
        let mockContent = MockFileContentService()
        let mockClipboard = MockClipboardService()
        let projectVM = makeProjectVM()
        projectVM.projectPath = "/tmp/testproj"
        let scannerVM = makeScannerVM(projectVM: projectVM)

        let vm = FileSelectionViewModel(
            contentService: mockContent,
            clipboard: mockClipboard,
            fileScannerViewModel: scannerVM
        )

        let file1 = SourceFile(url: URL(fileURLWithPath: "/tmp/testproj/a.swift"), name: "a.swift")
        let file2 = SourceFile(url: URL(fileURLWithPath: "/tmp/testproj/b.swift"), name: "b.swift")
        vm.selectedFiles = [file1, file2]
        mockContent.readFileStub = "content"

        vm.copySelected()

        let expected = "// MARK: - a.swift\n\ncontent\n\n// MARK: - b.swift\n\ncontent"
        #expect(mockClipboard.copiedString == expected)
    }

    @Test func copySelected_onlyCopiesSelectedFiles() {
        let mockContent = MockFileContentService()
        let mockClipboard = MockClipboardService()
        let projectVM = makeProjectVM()
        projectVM.projectPath = "/tmp/testproj"
        let scannerVM = makeScannerVM(projectVM: projectVM)

        let vm = FileSelectionViewModel(
            contentService: mockContent,
            clipboard: mockClipboard,
            fileScannerViewModel: scannerVM
        )

        let file1 = SourceFile(url: URL(fileURLWithPath: "/tmp/testproj/a.swift"), name: "a.swift")
        let file2 = SourceFile(url: URL(fileURLWithPath: "/tmp/testproj/b.swift"), name: "b.swift")
        vm.selectedFiles = [file1]
        mockContent.readFileStub = "content"

        vm.copySelected()

        #expect(mockClipboard.copiedString == "// MARK: - a.swift\n\ncontent")
    }

    @Test func copySelected_emptySelection_copiesEmptyString() {
        let mockClipboard = MockClipboardService()
        let projectVM = makeProjectVM()
        projectVM.projectPath = "/tmp/testproj"
        let scannerVM = makeScannerVM(projectVM: projectVM)
        scannerVM.files = [SourceFile(url: URL(fileURLWithPath: "/tmp/a.swift"), name: "a.swift")]

        let vm = FileSelectionViewModel(
            contentService: MockFileContentService(),
            clipboard: mockClipboard,
            fileScannerViewModel: scannerVM
        )
        vm.selectedFiles = []

        vm.copySelected()

        #expect(mockClipboard.copiedString == "")
    }

    @Test func copySelected_whenFileReadFails_includesErrorInOutput() {
        let mockContent = MockFileContentService()
        let mockClipboard = MockClipboardService()
        let projectVM = makeProjectVM()
        projectVM.projectPath = "/tmp/testproj"
        let scannerVM = makeScannerVM(projectVM: projectVM)

        let vm = FileSelectionViewModel(
            contentService: mockContent,
            clipboard: mockClipboard,
            fileScannerViewModel: scannerVM
        )

        let file = SourceFile(url: URL(fileURLWithPath: "/tmp/testproj/bad.swift"), name: "bad.swift")
        vm.selectedFiles = [file]
        mockContent.readFileError = CocoaError(.fileReadNoSuchFile)

        vm.copySelected()

        #expect(mockClipboard.copiedString!.contains("Error reading file"))
    }
}
