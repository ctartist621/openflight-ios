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

import GroundSdk

/// View model for auto landing alerts.

final class HUDAlertBannerAutoLandingViewModel: DroneWatcherViewModel<HUDAlertBannerSubState> {
    // MARK: - Private Properties
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var returnHomeRef: Ref<ReturnHomePilotingItf>?
    private var alarmsRef: Ref<Alarms>?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenFlyingIndicators(drone: drone)
        listenReturnHome(drone: drone)
        listenAlarms(drone: drone)
    }
}

// MARK: - Private Funcs
private extension HUDAlertBannerAutoLandingViewModel {
    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] _ in
            self?.updateState()
        }
    }

    /// Starts watcher for return home.
    func listenReturnHome(drone: Drone) {
        returnHomeRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] _ in
            self?.updateState()
        }
    }

    /// Starts watcher for alarms.
    func listenAlarms(drone: Drone) {
        alarmsRef = drone.getInstrument(Instruments.alarms) { [weak self] _ in
            self?.updateState()
        }
    }

    /// Updates current state.
    func updateState() {
        guard let drone = drone else {
            return
        }
        self.state.set(HUDAlertBannerSubState(alerts: drone.autoLandingAlerts))
    }
}
