//
//  WildcardSymbol.swift
//  DXFeedFramework
//
//  Created by Aleksey Kosylo on 01.06.23.
//

import Foundation
/// Represents [wildcard] subscription to all events of the specific event type.
///
/// The ``all`` constant can be added to any ``DXFeedSubcription`` instance with ``DXFeedSubcription/addSymbol`` method
/// to the effect of subscribing to all possible event symbols. The corresponding subscription will start
/// receiving all published events of the corresponding types.
///
/// [Javadoc](https://docs.dxfeed.com/dxfeed/api/com/dxfeed/api/osub/WildcardSymbol.html)
public class WildcardSymbol: Symbol {
    /// Symbol prefix that is reserved for wildcard subscriptions.
    /// Any subscription starting with "*" is ignored with the exception of  ``WildcardSymbol`` subscription.
    static let reservedPrefix = "*"
    private let symbol: String

    /// Represents [wildcard] subscription to all events of the specific event type.
    ///
    ///
    /// **Note**
    ///
    /// Wildcard subscription can create extremely high network and CPU load for certain kinds of
    /// high-frequency events like quotes. It requires a special arrangement on the side of upstream data provider and
    /// is disabled by default in upstream feed configuration.
    /// Make that sure you have adequate resources and understand the impact before using it.
    /// It can be used for low-frequency events only (like Forex quotes), because each instance
    /// of ``DXFeedSubcription`` processes events in a single thread
    /// and there is no provision to load-balance wildcard
    /// subscription amongst multiple threads.
    public static let all = WildcardSymbol(symbol: reservedPrefix)

    /// Initializes a new instance of the ``WildcardSymbol`` class.
    /// - Parameters:
    ///   - symbol: The wildcard symbol
    private init(symbol: String) {
        self.symbol = symbol
    }

    /// Custom symbol has to return string representation.
    public var stringValue: String {
        return symbol
    }
}
