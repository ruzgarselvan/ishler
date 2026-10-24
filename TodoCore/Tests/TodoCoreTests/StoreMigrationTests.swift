import Testing
import Foundation
@testable import TodoCore

@Suite struct StoreMigrationTests {
    func tempDir() -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func copiesStoreWithSidecarFilesOnlyWhenTargetMissing() throws {
        let old = tempDir(), new = tempDir()
        let source = old.appending(path: "todo.store")
        for suffix in ["", "-wal", "-shm"] { try Data("old\(suffix)".utf8).write(to: URL(filePath: source.path + suffix)) }
        let target = new.appending(path: "ishler.store")

        #expect(migrateStore(from: source, to: target))
        #expect(try String(contentsOf: target, encoding: .utf8) == "old")
        #expect(try String(contentsOf: URL(filePath: target.path + "-wal"), encoding: .utf8) == "old-wal")

        try Data("new".utf8).write(to: target)
        #expect(!migrateStore(from: source, to: target))
        #expect(try String(contentsOf: target, encoding: .utf8) == "new")
    }

    @Test func noSourceMeansNothingToMigrate() {
        #expect(!migrateStore(from: tempDir().appending(path: "missing.store"), to: tempDir().appending(path: "x.store")))
    }
}
