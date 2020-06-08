// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/06/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct FolderManager {
    public struct Ref {
        let manager: FolderManager
        let url: URL
        
        init(url: URL, manager: FolderManager = FolderManager.shared) {
            self.url = url
            self.manager = manager
        }
        

    }

    let manager: FileManager
    
    public static var shared = FolderManager(manager: FileManager.default)

    public var desktop: Folder {
        let url = manager.desktopDirectory()
        return Folder(ref: Ref(url: url, manager: self))
    }

    public func ref(for url: URL) -> Ref {
        Ref(url: url, manager: self)
    }
    
    public func file(for url: URL) -> File {
        File(ref: ref(for: url))
    }

    public func folder(for url: URL) -> Folder {
        Folder(ref: ref(for: url))
    }
}