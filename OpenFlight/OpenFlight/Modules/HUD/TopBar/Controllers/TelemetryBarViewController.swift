//    Copyright (C) 2020 Parrot Drones SAS
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
import Combine

// MARK: - Navigation protocol
protocol TelemetryBarViewControllerNavigation: AnyObject {
    /// Called when behaviour settings should be opened.
    func openBehaviourSettings()
    /// Called when geofence settings should be opened.
    func openGeofenceSettings()
    /// Called when quick settings should be opened.
    func openQuickSettings()
}

/// View controller for telemetry part of top bar.
final class TelemetryBarViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var speedItemView: TelemetryItemView!
    @IBOutlet private weak var altitudeItemView: TelemetryItemView!
    @IBOutlet private weak var aglItemView: TelemetryItemView!
    @IBOutlet private weak var distanceItemView: TelemetryItemView!
    @IBOutlet private weak var obstacleAvoidanceItemView: TelemetryItemView!

    // MARK: - Internal Properties
    weak var navigationDelegate: TelemetryBarViewControllerNavigation?

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var telemetryViewModel: TelemetryViewModel?
    private var defaultSpeedLabel: String {
        return String(format: "- %@", UnitHelper.stringSpeedUnit().uppercased())
    }
    private var defaultDistanceLabel: String {
        return String(format: "- %@", UnitHelper.stringDistanceUnit().uppercased())
    }
    // TODO: wrong injection
    private var obstacleAvoidanceViewModel = ObstacleAvoidanceViewModel(connectedDroneHolder: Services.hub.connectedDroneHolder)

    // MARK: - Override Funcs
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupViewModels()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        telemetryViewModel = nil
    }
}

// MARK: - Actions
private extension TelemetryBarViewController {
    /// Called when user taps the speed telemetry item.
    @IBAction func speedItemTouchedUpInside(_ sender: Any) {
        navigationDelegate?.openBehaviourSettings()
    }

    /// Called when user taps the altitude item.
    @IBAction func altitudeItemTouchedUpInside(_ sender: Any) {
        navigationDelegate?.openGeofenceSettings()
    }

    /// Called when user taps the distance item.
    @IBAction func distanceItemTouchedUpInside(_ sender: Any) {
        navigationDelegate?.openGeofenceSettings()
    }

    /// Called when user taps the obstacle avoidance item.
    @IBAction func obstacleAvoidanceItemTouchedUpInside(_ sender: Any) {
        navigationDelegate?.openQuickSettings()
    }
}

// MARK: - Private Funcs
private extension TelemetryBarViewController {
    /// Sets up models for every subitem.
    func setupViewModels() {
        speedItemView?.model = TelemetryItemModel(image: Asset.Telemetry.icSpeed.image,
                                                  label: defaultSpeedLabel,
                                                  backgroundColor: .clear,
                                                  borderColor: .clear)
        altitudeItemView?.model = TelemetryItemModel(image: Asset.Telemetry.icAltitude.image,
                                                     label: defaultDistanceLabel,
                                                     backgroundColor: .clear,
                                                     borderColor: .clear)
        aglItemView?.model = TelemetryItemModel(image: Asset.Telemetry.icAltitude.image,
                                                     label: defaultDistanceLabel,
                                                     backgroundColor: .clear,
                                                     borderColor: .clear)
        distanceItemView?.model = TelemetryItemModel(image: Asset.Telemetry.icDistance.image,
                                                     label: defaultDistanceLabel,
                                                     backgroundColor: .clear,
                                                     borderColor: .clear)

        obstacleAvoidanceViewModel.$state.sink { [unowned self] state in
            updateView(state: state)
        }
        .store(in: &cancellables)

        telemetryViewModel = TelemetryViewModel(userLocationManager: UserLocationManager(),
                                                speedDidChange: { [weak self] speed in
                                                    self?.onSpeedChanged(speed)
                                                },
                                                altitudeDidChange: { [weak self] altitude in
                                                    self?.onAltitudeChanged(altitude)
                                                },
                                                groundRelativeAltitudeDidChange: { [weak self] groundRelativeAltitude in
                                                    self?.onGroundRelativeAltitudeChanged(groundRelativeAltitude)
                                                },
                                                distanceDidChange: { [weak self] distance in
                                                    self?.onDistanceChanged(distance)
                                                })
    }

    /// Updates the obstacle avoidance item view with state.
    ///
    /// - Parameters:
    ///    - state: current state
    func updateView(state: ObstacleAvoidanceViewModel.State) {
        let image: UIImage
        switch state {
        case .disconnected:
            image = Asset.ObstacleAvoidance.icOADisconnected.image
        case .unwanted(.inactive):
            image = Asset.ObstacleAvoidance.icOAUnwanted.image
        case .unwanted(.active):
            image = Asset.ObstacleAvoidance.icOAActive.image
        case .unwanted(.degraded):
            image = Asset.ObstacleAvoidance.icOADegraded.image
        case .wanted(.inactive):
            image = Asset.ObstacleAvoidance.icOAInactive.image
        case .wanted(.active):
            image = Asset.ObstacleAvoidance.icOAActive.image
        case .wanted(.degraded):
            image = Asset.ObstacleAvoidance.icOADegraded.image
        }
        obstacleAvoidanceItemView.model = TelemetryItemModel(image: image,
                                                             label: "",
                                                             backgroundColor: .clear,
                                                             borderColor: .clear)
    }

    /// Called when current speed changes.
    func onSpeedChanged(_ speed: TelemetryValueModel) {
        if let speedValue = speed.currentValue {
            speedItemView.model?.label = UnitHelper.stringSpeedWithDouble(speedValue, minimumFractionDigits: 1).uppercased()
        } else {
            speedItemView.model?.label = defaultSpeedLabel
        }

        speedItemView.model?.backgroundColor = speed.alertLevel.color
    }

    /// Called when current altitude changes.
    func onAltitudeChanged(_ altitude: TelemetryValueModel) {
        if let altitudeValue = altitude.currentValue {
            altitudeItemView?.model?.label = UnitHelper.stringDistanceWithDouble(altitudeValue).uppercased()
        } else {
            altitudeItemView?.model?.label = defaultDistanceLabel
        }

        altitudeItemView.model?.backgroundColor = altitude.alertLevel.color
    }
    
    /// Called when current altitude changes.
    func onGroundRelativeAltitudeChanged(_ groundRelativeAltitude: TelemetryValueModel) {
        if let groundRelativeAltitudeValue = groundRelativeAltitude.currentValue {
            aglItemView?.model?.label = UnitHelper.stringDistanceWithDouble(groundRelativeAltitudeValue).uppercased()
        } else {
            aglItemView?.model?.label = defaultDistanceLabel
        }

        aglItemView.model?.backgroundColor = groundRelativeAltitude.alertLevel.color
    }

    /// Called when current distance changes.
    func onDistanceChanged(_ distance: TelemetryValueModel) {
        if let distanceValue = distance.currentValue {
            distanceItemView?.model?.label = UnitHelper.stringDistanceWithDouble(distanceValue).uppercased()
        } else {
            distanceItemView?.model?.label = defaultDistanceLabel
        }

        distanceItemView?.model?.backgroundColor = distance.alertLevel.color
    }
}
