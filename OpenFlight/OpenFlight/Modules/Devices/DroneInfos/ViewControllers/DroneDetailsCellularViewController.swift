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

/// Shows information about drone cellular access.
final class DroneDetailsCellularViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!
    @IBOutlet private weak var connectionSubtitleLabel: UILabel!
    @IBOutlet private weak var reinitializeButton: UIButton!
    @IBOutlet private weak var connectionStateLabel: UILabel!
    @IBOutlet private weak var connectionStateDescriptionLabel: UILabel!
    @IBOutlet private weak var accessSubtitleLabel: UILabel!
    @IBOutlet private weak var usersCountLabel: UILabel!
    @IBOutlet private weak var usersCountDescriptionLabel: UILabel!
    @IBOutlet private weak var forgotErrorLabel: UILabel!

    // MARK: - Private Properties
    private weak var coordinator: DroneCoordinator?
    private let viewModel = DroneDetailsCellularViewModel()

    // MARK: - Setup
    static func instantiate(coordinator: DroneCoordinator) -> DroneDetailsCellularViewController {
        let viewController = StoryboardScene.DroneDetailsCellular.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initViewModel()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension DroneDetailsCellularViewController {
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        closeView()
    }

    @IBAction func backgroundViewTouchedUpInside(_ sender: Any) {
        closeView()
    }

    @IBAction func actionButtonTouchedUpInside(_ sender: Any) {
        switch viewModel.state.value.cellularStatus {
        case .simLocked:
            logEvent(with: LogEvent.LogKeyDroneDetailsCellular.enterPinCode)
            self.view.backgroundColor = .clear
            coordinator?.dismiss {
                self.coordinator?.displayCellularPinCode()
            }
        case .userNotPaired:
            logEvent(with: LogEvent.LogKeyDroneDetailsCellular.pairDevice)
            coordinator?.pairUser()
        default:
            break
        }
    }

    @IBAction func reinitializeButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyDroneDetailsCellular.reinitialize)
        viewModel.forgetDrone()
    }
}

// MARK: - Private Funcs
private extension DroneDetailsCellularViewController {
    /// Inits the view.
    func initView() {
        mainView.applyCornerRadius(Style.largeCornerRadius,
                                   maskedCorners: [.layerMinXMinYCorner,
                                                   .layerMaxXMinYCorner])
        // Labels.
        titleLabel.text = L10n.droneDetailsCellularAccess
        titleLabel.makeUp(with: .huge)
        forgotErrorLabel.makeUp(and: ColorName.redTorch)
        connectionSubtitleLabel.text = L10n.commonConnectionState
        accessSubtitleLabel.text = L10n.cellularInfoAccess
        connectionSubtitleLabel.makeUp(and: .white50)
        accessSubtitleLabel.makeUp(and: .white50)
        connectionStateLabel.makeUp(with: .huge)
        usersCountLabel.makeUp(with: .huge)
        connectionStateDescriptionLabel.makeUp()
        usersCountDescriptionLabel.makeUp()
        usersCountDescriptionLabel.text = L10n.drone4gUserAccessSingular(0)

        // Buttons.
        actionButton.makeup()
        reinitializeButton.setTitle(L10n.drone4gReinitializeConnections, for: .normal)
        actionButton.titleLabel?.textAlignment = .center
        actionButton.cornerRadiusedWith(backgroundColor: .clear,
                                        borderColor: .white ,
                                        radius: Style.largeCornerRadius,
                                        borderWidth: Style.mediumBorderWidth)
    }

    /// Inits the view model.
    func initViewModel() {
        viewModel.state.valueChanged = { [weak self] _ in
            self?.updateView()
        }
        viewModel.updatesPairedUsersCount()
        updateView()
    }

    /// Closes the view.
    func closeView() {
        self.view.backgroundColor = .clear
        coordinator?.dismiss()
    }

    /// Updates view with datas from drone.
    func updateView() {
        let state = viewModel.state.value

        if state.unpairState.shouldShowError {
            forgotErrorLabel.isHidden = false
            forgotErrorLabel.text = state.unpairState.title
        } else {
            forgotErrorLabel.isHidden = true
        }

        actionButton.isHidden = !state.cellularStatus.shouldShowActionButton
        reinitializeButton.isEnabled = state.cellularStatus == .cellularConnected
        connectionStateLabel.text = state.cellularStatus.cellularDetailsTitle
        connectionStateLabel.textColor = state.cellularStatus.detailsTextColor.color

        if state.cellularStatus.isStatusError {
            connectionStateDescriptionLabel.text = state.cellularStatus.cellularDetailsDescription
            usersCountDescriptionLabel.text = Style.dash
            reinitializeButton.cornerRadiusedWith(backgroundColor: .clear,
                                                  borderColor: ColorName.white20.color ,
                                                  radius: Style.largeCornerRadius,
                                                  borderWidth: Style.mediumBorderWidth)
            reinitializeButton.makeup(color: .white50)
        } else {
            reinitializeButton.makeup()
            reinitializeButton.cornerRadiusedWith(backgroundColor: .clear,
                                                  borderColor: .white ,
                                                  radius: Style.largeCornerRadius,
                                                  borderWidth: Style.mediumBorderWidth)
            connectionStateDescriptionLabel.text = state.operatorName
            // Description text depends of the number of connected user.
            if state.usersCount > 1 {
                usersCountDescriptionLabel.text = L10n.drone4gUserAccessPlural(state.usersCount)
            } else {
                usersCountDescriptionLabel.text = L10n.drone4gUserAccessSingular(state.usersCount)
            }
        }

        usersCountLabel.text = "\(state.usersCount)"
        actionButton.setTitle(state.cellularStatus.actionButtonTitle, for: .normal)
    }

    /// Calls log event.
    ///
    /// - Parameters:
    ///     - itemName: Button name
    func logEvent(with itemName: String) {
        LogEvent.logAppEvent(itemName: itemName,
                             newValue: nil,
                             logType: .button)
    }
}
