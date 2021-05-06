// Copyright (C) 2020 Parrot Drones SAS
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

import SwiftyUserDefaults

// MARK: - Protocol
protocol HUDCoordinatorCriticalAlertDelegate: class {
    /// Called when user dimisses the alert.
    func onCriticalAlertDismissed()
}

/// Coordinator for HUD part.
open class HUDCoordinator: Coordinator, HistoryMediasAction {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public var parentCoordinator: Coordinator?

    // MARK: - Internal Properties
    weak var hudCriticalAlertDelegate: HUDCoordinatorCriticalAlertDelegate?

    // MARK: - Private Properties
    private var flightPlanExecutionObserver: Any?

    // MARK: - Init
    required public init() {
        listenFlightPlanExecution()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.remove(observer: flightPlanExecutionObserver)
        flightPlanExecutionObserver = nil
    }

    // MARK: - Public Funcs
    open func start() {
        let viewController = HUDViewController.instantiate(coordinator: self)
        self.navigationController?.viewControllers = [viewController]
    }

    open func displayAuthentification() {
        // To override.
    }

    open func handleHistoryCellAction(with fpExecution: FlightPlanExecution,
                                      actionType: HistoryMediasActionType) {
        // To override.
    }
}

// MARK: - HUDNavigation
extension HUDCoordinator {
    // MARK: - Internal Funcs
    /// Starts dashboard coordinator.
    func startDashboard() {
        let dashboardCoordinator = DashboardCoordinator()
        self.presentCoordinatorWithAnimation(childCoordinator: dashboardCoordinator, animationDirection: .fromLeft)
    }

    /// Starts settings coordinator.
    ///
    /// - Parameters:
    ///     - type: settings type
    func startSettings(_ type: SettingsType?) {
        let settingsCoordinator = SettingsCoordinator()
        settingsCoordinator.startSettingType = type
        self.presentCoordinatorWithAnimation(childCoordinator: settingsCoordinator, animationDirection: .fromRight)
    }

    /// Starts pairing coordinator.
    func startPairing() {
        let pairingCoordinator = PairingCoordinator()
        pairingCoordinator.parentCoordinator = self
        pairingCoordinator.start()
        self.present(childCoordinator: pairingCoordinator)
    }

    /// Starts drone infos coordinator.
    func startDroneInfos() {
        let droneCoordinator = DroneCoordinator()
        droneCoordinator.parentCoordinator = self
        droneCoordinator.start()
        self.present(childCoordinator: droneCoordinator)
    }

    /// Starts remote infos coordinator.
    func startRemoteInfos() {
        let remoteCoordinator = RemoteCoordinator()
        remoteCoordinator.parentCoordinator = self
        remoteCoordinator.start()
        self.present(childCoordinator: remoteCoordinator)
    }

    /// Starts drone calibration.
    func startDroneCalibration() {
        let droneCoordinator = DroneCalibrationCoordinator()
        droneCoordinator.parentCoordinator = self
        droneCoordinator.startWithMagnetometerCalibration()
        self.present(childCoordinator: droneCoordinator)
    }

    /// Displays cellular pairing available screen.
    func displayCellularPairingAvailable() {
        presentModal(viewController: CellularConfigurationViewController.instantiate(coordinator: self))
    }

    /// Displays remote shutdown alert screen.
    func displayRemoteAlertShutdown() {
        presentModal(viewController: RemoteShutdownAlertViewController.instantiate(coordinator: self))
    }

    /// Displays a critical alert on the screen.
    ///
    /// - Parameters:
    ///     - alert: the alert to display
    func displayCriticalAlert(alert: HUDCriticalAlertType?) {
        let criticalAlertVC = HUDCriticalAlertViewController.instantiate(with: alert)
        criticalAlertVC.delegate = self
        presentModal(viewController: criticalAlertVC)
    }

    /// Displays a flight report on the HUD.
    ///
    /// - Parameters:
    ///     - flightState: flight state
    func displayFlightReport(flightState: FlightDataState) {
        presentModal(viewController: FlightReportViewController.instantiate(flightState: flightState))
    }

    /// Displays entry coordinator for current MissionMode.
    ///
    /// - Parameters:
    ///    - state: current mission launcher state
    func presentModeEntryCoordinatorIfNeeded(state: MissionLauncherState) {
        guard let entryCoordinator = state.mode?.entryCoordinatorProvider?() else { return }

        entryCoordinator.parentCoordinator = self
        entryCoordinator.start()
        self.present(childCoordinator: entryCoordinator, overFullScreen: true)
    }

    /// Displays the new flight plan screen provided in the flight plan coordinator if there is one.
    ///
    /// - Parameters:
    ///    - flightPlanProvider: flight plan provider
    ///    - completion: callback that return if the flight plan creation have succeeded
    func presentNewFpCoordinatorIfNeeded(flightPlanProvider: FlightPlanProvider, creationCompletion: @escaping (_ createNewFlightPlan: Bool) -> Void) {
        guard let flightPlanCoordinator = flightPlanProvider.flightPlanCoordinator else { return }

        flightPlanCoordinator.parentCoordinator = self
        flightPlanCoordinator.startNewFlightPlan(flightPlanProvider: flightPlanProvider, creationCompletion: creationCompletion)
        self.present(childCoordinator: flightPlanCoordinator, overFullScreen: true)
    }

    /// Displays cellular pin code modal.
    func displayCellularPinCode() {
        presentModal(viewController: CellularAccessCardPinViewController.instantiate(coordinator: self))
    }

    /// Dismisses the cellular configuration screen.
    func dismissConfigurationScreen() {
        dismiss {
            if Defaults.isUserConnected {
                NotificationCenter.default.post(name: .requestCellularPairingProcess,
                                                object: nil,
                                                userInfo: nil)
            } else {
                self.displayAuthentification()
            }
        }
    }

    /// Displays successful 4G pairing modal.
    func displayPairingSuccess() {
        presentModal(viewController: CellularPairingSuccessViewController.instantiate(coordinator: self))
    }
}

// MARK: - HUDCriticalAlertDelegate
extension HUDCoordinator: HUDCriticalAlertDelegate {
    func dismissAlert() {
        dismiss()
        hudCriticalAlertDelegate?.onCriticalAlertDismissed()
    }

    func performAlertAction(alert: HUDCriticalAlertType?) {
        switch alert {
        case .droneAndRemoteUpdateRequired,
             .droneUpdateRequired:
            dismiss()
            startDroneInfos()
        case .droneCalibrationRequired:
            dismiss()
            startDroneCalibration()
        case .tooMuchAngle:
            dismissAlert()
        default:
            dismiss()
        }
    }
}

// MARK: - Private Funcs
private extension HUDCoordinator {
    /// Listens flight plan execution.
    func listenFlightPlanExecution() {
        flightPlanExecutionObserver = NotificationCenter.default.addObserver(forName: .startFlightPlanAtLaunch,
                                                                             object: nil,
                                                                             queue: nil) { [weak self] notification in
            guard let flightPlanId = notification.userInfo?[CurrentDroneStore.NotificationKeys.flightPlanRunningNotificationKey] as? String,
                  let currentViewModel = CoreDataManager.shared.loadFlightPlan(for: flightPlanId) else {
                return
            }

            self?.showFlightPlan(viewModel: currentViewModel)
        }
    }

    /// Shows active Flight Plan.
    ///
    /// - Parameters:
    ///     - viewModel: Flight Plan view model
    func showFlightPlan(viewModel: FlightPlanViewModel) {
        guard let type = viewModel.state.value.type else { return }

        // Set Flight Plan as last used to be automatically open.
        viewModel.setAsLastUsed()

        // Setup Mission as a Flight Plan mission (may be custom).
        let modeKey = FlightPlanTypeManager.shared.missionModeKey(for: type)
        if let mode = MissionsManager.shared.missionSubModeFor(key: modeKey) {
            Defaults.userMissionProvider = FlightPlanTypeManager.shared.missionKey(for: type)
            let missionModeViewModel = MissionLauncherViewModel()
            if let provider = MissionsManager.shared.allMissions.first(where: { $0.mission.key == modeKey}) {
                missionModeViewModel.update(provider: provider)
            }

            missionModeViewModel.update(mode: mode)
        }
    }
}
