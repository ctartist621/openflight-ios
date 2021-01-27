//
//  Copyright (C) 2020 Parrot Drones SAS.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions
//    are met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in
//      the documentation and/or other materials provided with the
//      distribution.
//    * Neither the name of the Parrot Company nor the names
//      of its contributors may be used to endorse or promote products
//      derived from this software without specific prior written
//      permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//    PARROT COMPANY BE LIABLE FOR ANY DIRECT, INDIRECT,
//    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
//    OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
//    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
//    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//    SUCH DAMAGE.

import UIKit
import CoreData

/// Flight list ViewController.

final class FlightsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyFlightsTitleLabel: UILabel!
    @IBOutlet private weak var emptyFlightsDecriptionLabel: UILabel!
    @IBOutlet private weak var emptyLabelStack: UIStackView!

    // MARK: - Private Properties
    private weak var coordinator: DashboardCoordinator?
    private var flightItems: [FlightDataViewModel] = []

    // MARK: - Setup
    static func instantiate(coordinator: DashboardCoordinator?) -> FlightsViewController {
        let viewController = StoryboardScene.FlightsViewController.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup tableView.
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 200.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(cellType: FlightTableViewCell.self)
        emptyFlightsTitleLabel.text = L10n.dashboardMyFlightsEmptyListTitle
        emptyFlightsDecriptionLabel.text = L10n.dashboardMyFlightsEmptyListDesc
        loadAllFlights()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.tableView.reloadData()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    /// Update display when orientation changed.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Reload data source.
        tableView.reloadData()
        DispatchQueue.main.async {
            // Compute cell height correctly.
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Public Funcs
    /// Load all flights saved in local database.
    public func loadAllFlights() {
        CoreDataManager.shared.loadAllFlightDataState(completion: { [weak self] flights in
            guard let strongSelf = self else { return }

            strongSelf.flightItems = flights.map({ state -> FlightDataViewModel in
                return FlightDataViewModel(state: state)
            })
            strongSelf.emptyLabelStack.isHidden = !strongSelf.flightItems.isEmpty
            strongSelf.tableView.reloadData()
        })
    }
}

// MARK: - UITableView DataSource
extension FlightsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flightItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as FlightTableViewCell
        var showDate: Bool = true
        let item = flightItems[indexPath.row]
        if indexPath.row > 0,
            let startDate = item.state.value.date,
            let previousItemDate = flightItems[indexPath.row - 1].state.value.date {
            showDate = !previousItemDate.isInSameMonth(date: startDate)
        }
        cell.configureCell(viewModel: flightItems[indexPath.row], showDate: showDate)
        cell.layoutIfNeeded()
        return cell
    }
}

// MARK: - UITableView Delegate
extension FlightsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        coordinator?.startFlightDetails(viewModel: flightItems[indexPath.row])
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = flightItems.remove(at: indexPath.row)
            item.removeFlight()
            tableView.reloadData()
        }
    }
}
