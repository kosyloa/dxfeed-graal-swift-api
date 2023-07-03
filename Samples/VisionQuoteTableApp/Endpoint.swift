//
//  Endpoint.swift
//  VisionQuoteTableApp
//
//  Created by Aleksey Kosylo on 29.06.23.
//

import Foundation
import DXFeedFramework

class Endpoint: Hashable, ObservableObject {
    @Published var state = DXEndpointState.notConnected
    private var endpoint: DXEndpoint?
    private var subscription: DXFeedSubcription?
    private var profileSubscription: DXFeedSubcription?
    private weak var dataSource: DataSource?

    static func == (lhs: Endpoint, rhs: Endpoint) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine("\(self)")
    }

    func subscribe(address: String, symbols: [String]) {
        if endpoint != nil {
            try? endpoint?.disconnect()
            subscription = nil
            profileSubscription = nil
        }
        try? SystemProperty.setProperty(DXEndpoint.Property.heartBeatTimeout.rawValue, "10s")

        let builder = try? DXEndpoint.builder().withRole(.feed)
        _ = try? builder?.withProperty(DXEndpoint.Property.aggregationPeriod.rawValue, "1")
        endpoint = try? builder?.build()
        endpoint?.add(self)
        try? endpoint?.connect(address)

        subscription = try? endpoint?.getFeed()?.createSubscription(.quote)
        profileSubscription = try? endpoint?.getFeed()?.createSubscription(.profile)
        subscription?.add(self)
        profileSubscription?.add(self)
        try? subscription?.addSymbols(symbols)
        try? profileSubscription?.addSymbols(symbols)
    }

    func addDataSource(_ dataSource: DataSource) {
        self.dataSource = dataSource
    }
}

extension Endpoint: DXEventListener {
    func receiveEvents(_ events: [MarketEvent]) {

        events.forEach { event in
            switch event.type {
            case .quote:
                dataSource?.update(event.quote)
            case .profile:
                dataSource?.update(event.profile)
            default:
                print(event)
            }
        }
    }
}

extension Endpoint: DXEndpointObserver {
    func endpointDidChangeState(oldDXEndpointState, newDXEndpointState) {
        DispatchQueue.main.async {
            self.state = new
        }
    }
}
