//
//  Copyright (C) 2023 Devexperts LLC. All rights reserved.
//  This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
//  If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

import Foundation

public class OrderBase: MarketEvent, IIndexedEvent, CustomStringConvertible {
    public var eventSource: IndexedEventSource {
        get {
            var sourceId = index >> 48
            if !OrderSource.isSpecialSourceId(sourceId: Int(sourceId)) {
                sourceId = index >> 32
            }
            if let value = try? OrderSource.valueOf(identifier: Int(sourceId)) {
                return value
            }
            fatalError("Incorrect value for eventsource \(self)")
        }
        set {
            let shift = OrderSource.isSpecialSourceId(sourceId: newValue.identifier) ? 48 : 32
            let mask = OrderSource.isSpecialSourceId(sourceId: Int(index >> 48)) ? ~(Long(-1) << 48) : ~(Long(-1) << 32)
            index = (Long(newValue.identifier << shift)) | (index & mask)
        }
    }

    public var eventFlags: Int32 = 0

    public private(set) var index: Long = 0

    /*
     * Flags property has several significant bits that are packed into an integer in the following way:
     *   31..15   14..11    10..4    3    2    1    0
     *), \--------+--------+--------+----+----+----+----+
     * |        | Action |Exchange|  Side   |  Scope  |
     *), \--------+--------+--------+----+----+----+----+
     */

    // ACTION values are taken from OrderAction enum.
    private static let actionMask = 0x0f
    private static let actionShift = 11

    // EXCHANGE values are ASCII chars in [0, 127].
    private static let exchangeMask = 0x7f
    private static let exchangeShift = 4

    // SIDE values are taken from Side enum.
    private static let sideMask = 3
    private static let sideShift = 2

    // SCOPE values are taken from Scope enum.
    private static let scopeMask = 3
    private static let scopeShift = 0
    /*
     * Index field contains source identifier, optional exchange code and low-end index (virtual id or MMID).
     * Index field has 2 formats depending on whether source is "special" (see OrderSource.IsSpecialSourceId()).
     * Note: both formats are IMPLEMENTATION DETAILS, they are subject to change without notice.
     *   63..48   47..32   31..16   15..0
     *), \--------+--------+--------+--------+
     * | Source |Exchange|      Index      |  <- "special" order sources (non-printable id with exchange)
     *), \--------+--------+--------+--------+
     *   63..48   47..32   31..16   15..0
     *), \--------+--------+--------+--------+
     * |     Source      |      Index      |  <- generic order sources (alphanumeric id without exchange)
     *), \--------+--------+--------+--------+
     * Note: when modifying formats track usages of getIndex/setIndex, getSource/setSource and isSpecialSourceId
     * methods in order to find and modify all code dependent on current formats.
     */

    /*
     * EventFlags property has several significant bits that are packed into an integer in the following way:
     *    31..7    6    5    4    3    2    1    0
     *), \---------+----+----+----+----+----+----+----+
     * |         | SM |    | SS | SE | SB | RE | TX |
     *), \---------+----+----+----+----+----+----+----+
     */

    /// Gets or sets time and sequence of this order packaged into single long value
    ///
    /// This method is intended for efficient order time priority comparison.
    /// **Do not set their property directly.**
    /// 
    /// Sets ``time`` and/or ``setSequence(_:)``.
    public internal(set) var timeSequence: Long = 0
    /// Gets or sets microseconds and nanoseconds time part of this order.
    public var timeNanoPart: Int32 = 0
    /// Gets or sets time of the last ``action``
    public var actionTime: Int64 = 0
    /// Gets or sets order ID if available.
    /// Some actions ``OrderAction/trade``, ``OrderAction/bust``
    /// have no order ID since they are not related to any order in Order book.
    public var orderId: Int64 = 0
    /// Gets or sets order ID if available.
    /// Returns auxiliary order ID if available:.
    /// ``OrderAction/new`` ID of the order replaced by this new order.
    /// ``OrderAction/delete`` - ID of the order that replaces this deleted order.
    /// ``OrderAction/partial`` - ID of the aggressor order.
    /// ``OrderAction/execute`` - ID of the aggressor order.
    public var auxOrderId: Int64 = 0
    /// Gets or sets price of this order event.
    public var price: Double = .nan
    /// Gets or sets size of this order event as floating number with fractions.
    public var size: Double = .nan
    /// Gets or sets executed size of this order.
    public var executedSize: Double = .nan
    /// Gets or sets number of individual orders in this aggregate order.
    public var count: Int64 = 0
    /// Gets or sets implementation-specific flags.
    /// **Do not use this property directly.**
    var flags: Int32 = 0
    /// Gets or sets trade (order execution) ID for events containing trade-related action.
    /// Returns 0 if trade ID not available.
    public var tradeId: Int64 = 0
    /// Gets or sets trade price for events containing trade-related action.
    public var tradePrice: Double = .nan
    /// Gets or sets trade size for events containing trade-related action.
    public var tradeSize: Double = .nan

    init(eventSymbol: String) {
        super.init()
        self.eventSymbol = eventSymbol
    }

    public var description: String {
"""
DXFG_ORDER_BASE_T \
eventSymbol: \(eventSymbol) \
eventTime: \(eventTime) \
eventFlags: \(eventFlags), \
index: \(index), \
timeSequence: \(timeSequence), \
timeNanoPart: \(timeNanoPart), \
actionTime: \(actionTime), \
orderId: \(orderId), \
auxOrderId: \(auxOrderId), \
price: \(price), \
size: \(size), \
executedSize: \(executedSize), \
count: \(count), \
flags: \(flags), \
tradeId: \(tradeId), \
tradePrice: \(tradePrice), \
tradeSize: \(tradeSize)
"""
    }

    /// Returns string representation of this candle event.
    public override func toString() -> String {
        return "OrderBase{\(baseFieldsToString())}"
    }
}

extension OrderBase {
    /// Gets or sets unique per-symbol index of this event.
    /// - Throws: ``ArgumentException/exception(_:)``
    public func setIndex(_ value: Long) throws {
        if index < 0 {
            throw ArgumentException.exception("Negative index: \(index)")
        }
        self.index = value
    }

    /// Gets a value indicating whether this order has some size
    public func hsaSize() -> Bool {
        return size != 0 && !size.isNaN
    }
    /// Gets exchange code of this order.
    public func getExchangeCode() -> Character {
        return Character(BitUtil.getBits(flags: Int(flags),
                                         mask: OrderBase.exchangeMask,
                                         shift: OrderBase.exchangeShift))
    }

    /// Gets exchange code of this order.
    public func getExchangeCode() -> Int {
        return BitUtil.getBits(flags: Int(flags),
                               mask: OrderBase.exchangeMask,
                               shift: OrderBase.exchangeShift)
    }
    /// Sets exchange code of this order.
    ///
    ///  - Throws: ``ArgumentException/exception(_:)``
    public func setExchangeCode(_ code: Character) throws {
        try StringUtil.checkChar(char: code, mask: OrderBase.exchangeMask, name: "exchangeCode")
        if let value = code.unicodeScalars.first?.value {
            flags = Int32(BitUtil.setBits(flags: Int(flags),
                                          mask: OrderBase.exchangeMask,
                                          shift: OrderBase.exchangeShift,
                                          bits: Int(value)))
        }
    }

    /// Gets or sets side of this order.
    public var orderSide: Side {
        get {
            Side.valueOf(Int(BitUtil.getBits(flags: Int(flags), mask: OrderBase.sideMask, shift: OrderBase.sideShift)))
        }
        set {
            flags = Int32(BitUtil.setBits(flags: Int(flags),
                                          mask: OrderBase.sideMask,
                                          shift: OrderBase.sideShift,
                                          bits: newValue.rawValue))
        }
    }

    /// Gets or sets time of this order.
    /// Time is measured in milliseconds between the current time and midnight, January 1, 1970 UTC.
    public var time: Long {
        get {
            ((timeSequence >> 32) * 1000) + ((timeSequence >> 22) & 0x3ff)
        }
        set {
            timeSequence = Long(TimeUtil.getSecondsFromTime(newValue) << 32) |
            (Long(TimeUtil.getMillisFromTime(newValue)) << 22) |
            Long(getSequence())
        }
    }

    /// Gets sequence number of this order to distinguish events that have the same ``time``.
    /// This sequence number does not have to be unique and
    /// does not need to be sequential. Sequence can range from 0 to ``MarketEventConst/maxSequence``.
    public func getSequence() -> Int {
        return Int(index) & Int(MarketEventConst.maxSequence)
    }
    /// Sets sequence number of this order to distinguish quotes that have the same ``time``.
    /// This sequence number does not have to be unique and
    /// does not need to be sequential. Sequence can range from 0 to ``MarketEventConst/maxSequence``.
    /// - Throws: ``ArgumentException/exception(_:)``
    public func setSequence(_ sequence: Int) throws {
        if sequence < 0 || sequence > MarketEventConst.maxSequence {
            throw ArgumentException.exception(
                "Sequence(\(sequence) is < 0 or > MaxSequence(\(MarketEventConst.maxSequence)"
            )
        }
        index = Long(index & ~Long(MarketEventConst.maxSequence)) | Long(sequence)
    }

    /// Gets or sets timestamp of the original event in nanoseconds
    /// Time is measured in nanoseconds between the current time and midnight, January 1, 1970 UTC.
    public var timeNanos: Long {
        get {
            TimeNanosUtil.getNanosFromMillisAndNanoPart(time, timeNanoPart)
        }
        set {
            time = TimeNanosUtil.getMillisFromNanos(newValue)
            timeNanoPart = Int32(TimeNanosUtil.getNanoPartFromNanos(newValue))
        }
    }

    /// Gets or sets action of this order.
    /// Returns order action if available, otherwise ``OrderAction/undefined``
    public var action: OrderAction {
        get {
            return OrderActionExt.valueOf(value: BitUtil.getBits(flags: Int(flags),
                                                                 mask: OrderBase.actionMask,
                                                                 shift: OrderBase.actionShift))
        }
        set {
            flags = Int32(BitUtil.setBits(flags: Int(flags),
                                          mask: OrderBase.actionMask,
                                          shift: OrderBase.actionShift,
                                          bits: newValue.rawValue))
        }
    }

    /// Gets or sets scope of this order.
    public var scope: Scope {
        get {
            return ScopeExt.valueOf(value: BitUtil.getBits(flags: Int(flags),
                                                           mask: OrderBase.scopeMask,
                                                           shift: OrderBase.scopeShift))
        }

        set {
            flags = Int32(BitUtil.setBits(flags: Int(flags),
                                          mask: OrderBase.scopeMask,
                                          shift: OrderBase.scopeShift,
                                          bits: newValue.rawValue))
        }
    }

    /// Returns string representation of this candle fields.
    func baseFieldsToString() -> String {

        return
"""
\(eventSymbol), \
eventTime=\((try? DXTimeFormat.defaultTimeFormat?.withMillis?.format(value: eventTime)) ?? ""), \
source=\(eventSource.name), \
eventFlags=\(eventFlags.toHexString()), \
index=\(index.toHexString()), \
time=\((try? DXTimeFormat.defaultTimeFormat?.withMillis?.format(value: time)) ?? ""), \
sequence=\(getSequence()), \
timeNanoPart=\(timeNanoPart), \
action=\(action), \
actionTime=\((try? DXTimeFormat.defaultTimeFormat?.withMillis?.format(value: actionTime)) ?? ""), \
orderId=\(orderId), \
auxOrderId=\(auxOrderId), \
price=\(price), \
size=\(size), \
executedSize=\(executedSize), \
count=\(count), \
exchange=\(StringUtil.encodeChar(char: Int16(getExchangeCode()))), \
side=\(orderSide), \
scope=\(scope), \
tradeId=\(tradeId), \
tradePrice=\(tradePrice), \
tradeSize=\(tradeSize)
"""
    }
}
