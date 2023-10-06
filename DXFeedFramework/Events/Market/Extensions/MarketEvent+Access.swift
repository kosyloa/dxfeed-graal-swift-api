//
//  MarketEvent+Access.swift
//  DXFeedFramework
//
//  Created by Aleksey Kosylo on 15.06.23.
//

import Foundation

/// Use this extension instead of
/// checking type and cast in client side code
///
/// switch (event.type) {
///  case: .quote:
///   let quote = tsEvent.quote
extension MarketEvent {
    /// Use only for event.type is ``EventCode/quote``
    public var quote: Quote {
        return (self as? Quote)!
    }
    /// Use only for event.type is ``EventCode/timeAndSale``
    public var timeAndSale: TimeAndSale {
        return (self as? TimeAndSale)!
    }
    /// Use only for event.type is ``EventCode/trade``
    public var trade: Trade {
        return (self as? Trade)!
    }
    /// Use only for event.type is ``EventCode/profile``
    public var profile: Profile {
        return (self as? Profile)!
    }
    /// Use only for event.type is ``EventCode/candle``
    public var candle: Candle {
        return (self as? Candle)!
    }
    /// Use only for event.type is ``EventCode/summary``
    public var summary: Summary {
        return (self as? Summary)!
    }
    /// Use only for event.type is ``EventCode/greeks``
    public var greeks: Greeks {
        return (self as? Greeks)!
    }
    /// Use only for event.type is ``EventCode/underlying``
    public var underlying: Underlying {
        return (self as? Underlying)!
    }
}
