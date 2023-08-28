//
//  QuoteTableViewController.swift
//  TestApp
//
//  Created by Aleksey Kosylo on 07.06.23.
//

import UIKit
import DXFeedFramework

class QuoteTableViewController: UIViewController {
    private var endpoint: DXEndpoint?
    private var subscription: DXFeedSubcription?
    private var profileSubscription: DXFeedSubcription?

    var dataSource = [String: QuoteModel]()
    var symbols = ["AAPL", "IBM", "MSFT", "EUR/CAD", "ETH/USD:GDAX", "GOOG", "BAC", "CSCO", "ABCE", "INTC", "PFE"]

    @IBOutlet var quoteTableView: UITableView!
    @IBOutlet var connectionStatusLabel: UILabel!
    @IBOutlet var agregationSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .tableBackground
        self.quoteTableView.backgroundColor = .tableBackground

        quoteTableView.separatorStyle = .none
        self.connectionStatusLabel.text = DXEndpointState.notConnected.convetToString()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribe(agregationSwitch.isOn)
    }

    func subscribe(_ unlimited: Bool) {
        if endpoint != nil {
            try? endpoint?.disconnect()
            subscription = nil
            profileSubscription = nil
        }
        try? SystemProperty.setProperty(DXEndpoint.ExtraPropery.heartBeatTimeout.rawValue, "10s")

        let builder = try? DXEndpoint.builder().withRole(.feed)
        if !unlimited {
            _ = try? builder?.withProperty(DXEndpoint.Property.aggregationPeriod.rawValue, "1")
        }
        endpoint = try? builder?.build()
        endpoint?.add(self)
        try? endpoint?.connect("demo.dxfeed.com:7300")

        subscription = try? endpoint?.getFeed()?.createSubscription(.quote)
        profileSubscription = try? endpoint?.getFeed()?.createSubscription(.profile)
        try? subscription?.add(self)
        try? profileSubscription?.add(self)
        symbols.forEach {
            dataSource[$0] = QuoteModel()
        }
        try? subscription?.addSymbols(symbols)
        try? profileSubscription?.addSymbols(symbols)
    }

    @IBAction func changeAggregationPeriod(_ sender: UISwitch) {
        subscribe(agregationSwitch.isOn)
    }
}

extension QuoteTableViewController: DXEndpointObserver {
    func endpointDidChangeState(old: DXEndpointState, new: DXEndpointState) {
        DispatchQueue.main.async {
            self.connectionStatusLabel.text = new.convetToString()
        }
    }
}

extension QuoteTableViewController: DXEventListener {
    func receiveEvents(_ events: [MarketEvent]) {

        events.forEach { event in
            switch event.type {
            case .quote:
                dataSource[event.eventSymbol]?.update(event.quote)
            case .profile:
                dataSource[event.eventSymbol]?.update(event.profile.descriptionStr ?? "")
            default:
                print(event)
            }
        }
        DispatchQueue.main.async {
            self.quoteTableView.reloadData()
        }
    }
}

extension QuoteTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "QuoteCellId", for: indexPath)
                as? QuoteCell else {
            return UITableViewCell()
        }
        let symbol = symbols[indexPath.row]
        let quote = dataSource[symbol]
        cell.update(model: quote, symbol: symbol, description: quote?.descriptionString)
        return cell
    }
}

extension QuoteTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
