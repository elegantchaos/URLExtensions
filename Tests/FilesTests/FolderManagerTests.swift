// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/06/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest
import XCTestExtensions

@testable import Files

final class FolderManagerTests: XCTestCase {
      func testFolder() {
          let fm = FileManager.default.locations
          let h = fm.home
          
          XCTAssertEqual(h.url, URL(fileURLExpandingPath: "~/"))
          XCTAssertTrue(h.exists)
          XCTAssertFalse(h.isFile)
          XCTAssertFalse(h.isHidden)
          
          let url = temporaryFile()
          let folder = fm.folder(for: url)
          try! folder.create()
          XCTAssertTrue(FileManager.default.fileExists(atURL: url))
          
          let url2 = url.deletingLastPathComponent().appendingPathComponent("Test2")
          let renamed = try! folder.rename(as: "Test2")
          XCTAssertFalse(FileManager.default.fileExists(atURL: url))
          XCTAssertFalse(folder.exists)
          
          XCTAssertTrue(FileManager.default.fileExists(atURL: url2))
          XCTAssertTrue(renamed.exists)
          try! renamed.delete()
          
          XCTAssertFalse(FileManager.default.fileExists(atURL: url2))
          
      }
    
   func testQuietFolder() {
      let fm = FileManager.default.quiet
        let h = fm.home
        
        XCTAssertEqual(h.url, URL(fileURLExpandingPath: "~/"))
        XCTAssertTrue(h.exists)
        XCTAssertFalse(h.isFile)
        XCTAssertFalse(h.isHidden)
        
        let url = temporaryFile()
        let folder = fm.folder(for: url)
        folder.create()
        XCTAssertTrue(FileManager.default.fileExists(atURL: url))
        
        let url2 = url.deletingLastPathComponent().appendingPathComponent("Test2")
        let renamed = folder.rename(as: "Test2")
        XCTAssertFalse(FileManager.default.fileExists(atURL: url))
        XCTAssertFalse(folder.exists)
        
        XCTAssertTrue(FileManager.default.fileExists(atURL: url2))
        XCTAssertTrue(renamed.exists)
        renamed.delete()
        
        XCTAssertFalse(FileManager.default.fileExists(atURL: url2))
        
    }
    
     func testFile() {
           let fm = FileManager.default.locations

           let url = temporaryFile(named: "test", extension: "txt")
           try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
           try! "test".write(to: url, atomically: true, encoding: .utf8)
           let file = fm.file(for: url)
           XCTAssertTrue(file.exists)
           XCTAssertTrue(file.isFile)
           XCTAssertFalse(file.isHidden)

           let url2 = url.deletingLastPathComponent().appendingPathComponent("Test2")
           let renamed = try! file.rename(as: "Test2")
           XCTAssertFalse(FileManager.default.fileExists(atURL: url))
           XCTAssertFalse(file.exists)

           XCTAssertTrue(FileManager.default.fileExists(atURL: url2))
           XCTAssertTrue(renamed.exists)
           try! renamed.delete()

           XCTAssertFalse(FileManager.default.fileExists(atURL: url2))
       }

     func testQuietFile() {
           let fm = FileManager.default.quiet

           let url = temporaryFile(named: "test", extension: "txt")
           try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
           try! "test".write(to: url, atomically: true, encoding: .utf8)
           let file = fm.file(for: url)
           XCTAssertTrue(file.exists)
           XCTAssertTrue(file.isFile)
           XCTAssertFalse(file.isHidden)

           let url2 = url.deletingLastPathComponent().appendingPathComponent("Test2")
           let renamed = file.rename(as: "Test2")
           XCTAssertFalse(FileManager.default.fileExists(atURL: url))
           XCTAssertFalse(file.exists)

           XCTAssertTrue(FileManager.default.fileExists(atURL: url2))
           XCTAssertTrue(renamed.exists)
           renamed.delete()

           XCTAssertFalse(FileManager.default.fileExists(atURL: url2))
       }

    func testHidden() {
        let url = temporaryFile(named: ".test")
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        try! "test".write(to: url, atomically: true, encoding: .utf8)
        let file = FileManager.default.locations.file(for: url)
        XCTAssertTrue(file.isHidden)
    }
    
    func testFailure() {
        XCTAssertThrowsError(try FileManager.default.locations.temporary.file("non-existent").rename(as: "test"))
    }
    
    func testQuietFailure() {
        var receivedError: NSError? = nil
        let fm = QuietLocationManager(errorHandler: { error in receivedError = error as NSError })
        _ = fm.temporary.file("non-existent").rename(as: "test")
        XCTAssertEqual(receivedError?.code, 4)
        XCTAssertEqual(receivedError?.domain, "NSCocoaErrorDomain")
    }
    
    func makeTestStructure() -> URL {
        let f1 = temporaryFile(named: "root")
        try? FileManager.default.createDirectory(at: f1, withIntermediateDirectories: true, attributes: nil)
        let f2 = f1.appendingPathComponent("folder2")
        let f3 = f1.appendingPathComponent("folder3")
        try? FileManager.default.createDirectory(at: f2, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.createDirectory(at: f3, withIntermediateDirectories: true, attributes: nil)
        return f1
    }

    func testForEach() {
        let root = makeTestStructure()
        let folder = FileManager.default.locations.folder(for: root)
        var names = ["folder2", "folder3"]
        try! folder.forEach() { item in
            XCTAssertTrue(item is Folder)
            let index = names.firstIndex(of: item.name.name)
            XCTAssertNotNil(index)
            names.remove(at: index!)
        }
        XCTAssertEqual(names.count, 0)
    }

    func testQuietForEach() {
        let root = makeTestStructure()
        let folder = FileManager.default.quiet.folder(for: root)
        var names = ["folder2", "folder3"]
        try! folder.forEach() { item in
            XCTAssertTrue(item is QuietFolder)
            let index = names.firstIndex(of: item.name.name)
            XCTAssertNotNil(index)
            names.remove(at: index!)
        }
        XCTAssertEqual(names.count, 0)
    }

    func testTypePropogation() {
        let temp = FileManager.default.locations.temporary
        XCTAssertTrue(temp is Folder)
        XCTAssertTrue(temp.file("test") is File)
        XCTAssertTrue(temp.folder("test") is Folder)
        XCTAssertTrue(temp.up is Folder)

        let quiet = FileManager.default.quiet.temporary
        XCTAssertTrue(quiet is QuietFolder)
        XCTAssertTrue(quiet.file("test") is QuietFile)
        XCTAssertTrue(quiet.folder("test") is QuietFolder)
        XCTAssertTrue(quiet.up is QuietFolder)
    }
}
