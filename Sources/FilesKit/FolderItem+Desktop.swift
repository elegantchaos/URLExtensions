// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/06/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Files

#if canImport(AppKit)

import AppKit

extension Item {
    public func reveal() {
        NSWorkspace.shared.open(url)
    }
    
    public var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}

#else

extension Item {
    public func reveal() {
        // TODO...
    }
}

#endif
