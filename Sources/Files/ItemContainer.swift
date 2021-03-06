// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/06/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public indirect enum Filter {
    case none
    case files
    case folders
    case visible
    case hidden
    case custom((ItemCommon) -> Bool)
    case compound(Filter, Filter)
    
    func passes(_ item: ItemCommon) -> Bool {
        switch self {
        case .none: return true
        case .files: return item.isFile
        case .folders: return !item.isFile
        case .visible: return !item.isHidden
        case .hidden: return item.isHidden
        case .custom(let filter): return filter(item)
        case .compound(let f1, let f2): return f1.passes(item) && f2.passes(item)
        }
    }
}

public enum Order {
    case filesFirst
    case foldersFirst
}


public protocol ItemContainer: Item {
    typealias FileType = Manager.FileType
    typealias FolderType = Manager.FolderType
    func file(_ name: ItemName) -> FileType
    func folder(_ name: ItemName) -> FolderType
    func file(_ name: String) -> FileType
    func folder(_ name: String) -> FolderType
    func item(_ name: ItemName) -> ItemCommon?
    func item(_ name: String) -> ItemCommon?
    func _forEach(inParallelWith parallel: FolderType?, order: Order, filter: Filter, recursive: Bool, do block: (ItemCommon, FolderType?) throws -> Void) throws
}

public extension ItemContainer {
    func file(_ name: ItemName) -> FileType {
        return ref.manager.file(for: ref.url.appending(name))
    }
    
    func file(_ name: String) -> FileType {
        file(ItemName(name))
    }
    
    func folder(_ name: ItemName) -> FolderType {
        return ref.manager.folder(for: ref.url.appending(name))
    }
    
    func folder(_ name: String) -> FolderType {
        folder(ItemName(name))
    }
    
    func folder(_ components: [String]) -> FolderType {
        return ref.manager.folder(for: ref.url.appendingPathComponents(components))
    }
    
    func item(_ name: ItemName) -> ItemCommon? {
        let url = ref.url.appending(name)
        var isDirectory: ObjCBool = false
        guard ref.manager.manager.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return nil }
        return isDirectory.boolValue ? ref.manager.folder(for: url) : ref.manager.file(for: url)
    }
    
    func item(_ name: String) -> ItemCommon? {
        item(ItemName(name))
    }
    
    func _forEach(inParallelWith parallel: FolderType?, order: Order = .filesFirst, filter: Filter = .none, recursive: Bool = true, do block: (ItemCommon, FolderType?) throws -> Void) throws {
        var files: [FileType] = []
        var folders: [FolderType] = []
        let manager = ref.manager
        let contents = try manager.manager.contentsOfDirectory(at: ref.url, includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey], options: [])
        for item in contents {
            let values = try item.resourceValues(forKeys: [.isDirectoryKey])
            if values.isDirectory ?? false {
                let item = ref.manager.folder(for: item)
                folders.append(item)
            } else {
                let item = ref.manager.file(for: item)
                if filter.passes(item) { files.append(item) }
            }
        }
        
        func processFolders() throws {
            if recursive {
                try folders.forEach { folder in
                    let nested: FolderType?
                    if let parallel = parallel {
                        let nestedURL = parallel.ref.url.appendingPathComponent(ref.url.lastPathComponent)
                        try? ref.manager.manager.createDirectory(at: nestedURL, withIntermediateDirectories: true, attributes: nil)
                        nested = ref.manager.folder(for: nestedURL)
                    } else {
                        nested = nil
                    }
                    
                    try folder._forEach(inParallelWith: nested, order: order, filter: filter, recursive: recursive, do: block)
                }
            }
            
            let filtered = folders.filter({ return filter.passes($0) })
            try filtered.forEach({ try block($0, parallel) })
        }


        func processFiles() throws {
            try files.forEach({ try block($0, parallel) })
        }
        
        switch order {
        case .filesFirst:
            try processFiles()
            try processFolders()
            
        case .foldersFirst:
            try processFolders()
            try processFiles()
        }
    }

    func forEach(inParallelWith parallel: FolderType?, order: Order = .filesFirst, filter: Filter = .none, recursive: Bool = true, do block: (Manager.ItemType, FolderType?) throws -> Void) throws {
        try _forEach(inParallelWith: parallel, order: order, filter: filter, recursive: recursive) {
            item, _ in try block(item as! Manager.ItemType, parallel)
        }
    }

    func forEach(order: Order = .filesFirst, filter: Filter = .none, recursive: Bool = true, do block: (Manager.ItemType) throws -> Void) throws {
        try forEach(inParallelWith: nil, order: order, filter: filter, recursive: recursive) {
            item, _ in try block(item)
        }
    }

}
