//
//  IndexedEventSource.swift
//  DXFeedFramework
//
//  Created by Aleksey Kosylo on 17.08.23.
//

import Foundation
/// Source identifier for <see cref="IIndexedEvent"/>.
///
/// [For more details see](https://docs.dxfeed.com/dxfeed/api/com/dxfeed/event/IndexedEventSource.html)
public class IndexedEventSource {
    /// Gets a source identifier. Source identifier is non-negative.
    public let identifier: Int
    /// Gets a name of identifier.
    public let name: String

    /// The default source with zero identifier for all events that do not support multiple sources.
    static let defaultSource =  IndexedEventSource(identifier: 0, name: "DEFAULT")

    /// Initializes a new instance of the <see cref="IndexedEventSource"/> class.
    ///
    /// - Parameters:
    ///     - identifier: The identifier
    ///     - name: The name of identifier
    public init(identifier: Int, name: String) {
        self.name = name
        self.identifier = identifier
    }
    /// Returns a string representation of the object.
    ///
    /// - Returns: A string representation of the object.
    public func toString() -> String {
        return name
    }
}

extension IndexedEventSource: Equatable {
    public static func == (lhs: IndexedEventSource, rhs: IndexedEventSource) -> Bool {
        return lhs === rhs || lhs.identifier == rhs.identifier
    }
}
