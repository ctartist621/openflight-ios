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

/// Settings content sub class dedicated to camera settings.
final class SettingsCameraViewController: SettingsContentViewController {

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        setupViewModel()
    }

    /// Reset to default settings.
    override func resetSettings() {
        LogEvent.log(.simpleButton(LogEvent.LogKeyAdvancedSettings.resetRecordingSettings))

        viewModel?.resetSettings()
    }
}

// MARK: - Private Funcs
private extension SettingsCameraViewController {

    /// Initializes view.
    func initView() {
        view.directionalLayoutMargins = Layout.mainContainerInnerMargins(isRegularSizeClass,
                                                                         screenBorders: [.top, .bottom])
        resetCellLabel = L10n.settingsCameraReset
    }

    /// Sets up view model.
    func setupViewModel() {
        // Setup view model.
        // TODO: wrong injection, viewModel should be prepared one level up (coordinator or upper VM)
        viewModel = SettingsCameraViewModel(activeFlightPlanWatcher: Services.hub.flightPlan.activeFlightPlanWatcher,
                                            currentDroneHolder: Services.hub.currentDroneHolder)
        guard let viewModel = viewModel as? SettingsCameraViewModel else { return }

        viewModel.notifyChangePublisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateDataSource()
            }
            .store(in: &cancellables)
    }
}
