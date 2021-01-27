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

import SwiftyUserDefaults
import GroundSdk

/// State for HUDCameraStreamingViewModel.

final class HUDCameraStreamingState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Current stream server enabled state.
    fileprivate(set) var streamEnabled: Bool = false
    /// Current secondary screen setting.
    fileprivate(set) var secondaryScreenSetting: SecondaryScreenType = .map
    /// Current overexposure setting.
    fileprivate(set) var overexposureSetting: SettingsOverexposure = .current

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - streamEnabled: stream server enable state
    ///    - secondaryScreenSetting: setting for secondary screen
    ///    - overexposureSetting: setting for overexposure
    init(streamEnabled: Bool,
         secondaryScreenSetting: SecondaryScreenType,
         overexposureSetting: SettingsOverexposure) {
        self.streamEnabled = streamEnabled
        self.secondaryScreenSetting = secondaryScreenSetting
        self.overexposureSetting = overexposureSetting
    }

    // MARK: - Internal Funcs
    func isEqual(to other: HUDCameraStreamingState) -> Bool {
        // State should always get updated to avoid issues
        // with updates while stream view is not visible.
        return false
    }

    /// Returns a copy of the object.
    func copy() -> HUDCameraStreamingState {
        let copy = HUDCameraStreamingState(streamEnabled: self.streamEnabled,
                                           secondaryScreenSetting: self.secondaryScreenSetting,
                                           overexposureSetting: self.overexposureSetting)
        return copy
    }
}

/// ViewModel for HUDCameraStreaming, notifies on stream server, camera live and secondary screen setting changes.

final class HUDCameraStreamingViewModel: DroneWatcherViewModel<HUDCameraStreamingState> {
    // MARK: - Private Properties
    private var overexposureSettingObserver: DefaultsDisposable?
    private var streamServerRef: Ref<StreamServer>?
    private var cameraLiveRef: Ref<CameraLive>?
    private var cameraRef: Ref<MainCamera2>?
    private var playStreamRetryTimer: Timer?
    private var cameraLiveUpdateCallback: ((CameraLive?) -> Void)?
    private var isMonitoring: Bool = false

    // MARK: - Private Enums
    private enum Constants {
        static let playStreamRetryDelay = 1.0
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - stateDidUpdate: Camera streaming state callback
    ///     - cameraLiveDidUpdate: Camera live callback
    init(stateDidUpdate: ((HUDCameraStreamingState) -> Void)? = nil,
         cameraLiveDidUpdate: ((CameraLive?) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        self.cameraLiveUpdateCallback = cameraLiveDidUpdate
        listenDefaults()
    }

    // MARK: - Deinit
    deinit {
        cameraRef = nil
        cameraLiveRef = nil
        streamServerRef = nil
        playStreamRetryTimer?.invalidate()
        playStreamRetryTimer = nil
        overexposureSettingObserver?.dispose()
        overexposureSettingObserver = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        /// If monitoring is already enabled, reset it for drone change.
        if isMonitoring {
            enableMonitoring(false)
            enableMonitoring(true)
        }
    }
    // MARK: - Internal Funcs
    /// Enables or disables the live monitoring of the stream.
    ///
    /// - Parameters:
    ///    - enabled: whether live should be enabled
    func enableMonitoring(_ enabled: Bool) {
        isMonitoring = enabled
        if enabled {
            if let drone = drone {
                listenStreamServer(drone: drone)
                listenCamera(drone: drone)
            }
        } else {
            cameraRef = nil
            streamServerRef = nil
            cameraLiveRef = nil
            cameraLiveUpdateCallback?(nil)
        }
    }
}

// MARK: - Private Funcs
private extension HUDCameraStreamingViewModel {
    /// Starts watcher for stream server state.
    func listenStreamServer(drone: Drone) {
        streamServerRef = drone.getPeripheral(Peripherals.streamServer) { [weak self] streamServer in
            guard let strongSelf = self,
                let streamServer = streamServer,
                streamServer.enabled
                else {
                    self?.updateStreamEnabled(false)
                    return
            }
            strongSelf.updateStreamEnabled(streamServer.enabled)
            // Start watcher for camera live.
            strongSelf.cameraLiveRef = drone.getPeripheral(Peripherals.streamServer)?.live { [weak self] cameraLive in
                guard let cameraLive = cameraLive else {
                    return
                }
                self?.cameraLiveUpdateCallback?(cameraLive)
                self?.playStreamIfNeeded(drone: drone)
            }
            strongSelf.playStreamIfNeeded(drone: drone)
        }
    }

    /// Updates stream enabled state.
    func updateStreamEnabled(_ enabled: Bool) {
        let copy = state.value.copy()
        copy.streamEnabled = enabled
        state.set(copy)
    }

    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] _ in
            self?.playStreamIfNeeded(drone: drone)
        }
    }

    /// Starts watchers for defaults.
    func listenDefaults() {
        // Start overexposure setting observer.
        overexposureSettingObserver = Defaults.observe(\.overexposureSetting, options: [.new]) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                let copy = self?.state.value.copy()
                copy?.overexposureSetting = SettingsOverexposure.current
                self?.state.set(copy)
            }
        }
    }

    /// Plays the stream if all conditions are met.
    func playStreamIfNeeded(drone: Drone) {
        guard state.value.streamEnabled,
            let camera = drone.currentCamera,
            camera.isActive,
            let stream = cameraLiveRef?.value,
            stream.playState != .playing
            else {
                return
        }
        // Play live stream.
        _ = stream.play()
        // Retry later to recover from potential playing error (for instance when connection quality is low).
        playStreamRetryTimer?.invalidate()
        playStreamRetryTimer = Timer.scheduledTimer(withTimeInterval: Constants.playStreamRetryDelay, repeats: false) { [weak self] _ in
            if let drone = self?.drone {
                self?.playStreamIfNeeded(drone: drone)
            }
        }
    }
}