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

/// State for `DynamicRangeBarViewModel`.

final class DynamicRangeBarState: ImagingBarState {

    // MARK: - Override Funcs
    override func copy() -> DynamicRangeBarState {
        return DynamicRangeBarState(mode: self.mode,
                                    supportedModes: self.supportedModes,
                                    showUnsupportedModes: self.showUnsupportedModes,
                                    isSelected: self.isSelected)
    }
}

/// View model for imaging settings bar dynamic range item.

final class DynamicRangeBarViewModel: BarButtonViewModel<DynamicRangeBarState> {
    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenCamera(drone: drone)
    }

    override func update(mode: BarItemMode) {
        guard let camera = drone?.getPeripheral(Peripherals.mainCamera2),
            !camera.config.updating,
            let dynamicRange = mode as? DynamicRange
            else {
                return
        }

        let currentEditor = camera.currentEditor

        switch dynamicRange {
        case .plog:
            currentEditor[Camera2Params.imageStyle]?.value = .plog
            currentEditor.disableHdr(camera: camera)
        case .hdrOff:
            currentEditor[Camera2Params.imageStyle]?.value = .standard
            currentEditor.disableHdr(camera: camera)
        case .hdrOn:
            currentEditor[Camera2Params.imageStyle]?.value = .standard
            currentEditor.enableHdr(camera: camera)
        }

        currentEditor.saveSettings()
        updateCurrentMode(with: camera)
    }
}

// MARK: - Private Funcs
private extension DynamicRangeBarViewModel {
    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] camera in
            guard let camera = camera else { return }
            self?.updateCurrentMode(with: camera)
            self?.updateAvailableModes(with: camera)
        }
        guard let camera = drone.getPeripheral(Peripherals.mainCamera2) else { return }
        updateCurrentMode(with: camera)
        updateAvailableModes(with: camera)
    }

    /// Updates current dynamic range mode.
    ///
    /// - Parameters:
    ///     - camera: current camera
    func updateCurrentMode(with camera: MainCamera2) {
        let copy = state.value.copy()

        if camera.config[Camera2Params.imageStyle]?.value == .plog {
            copy.mode = DynamicRange.plog
        } else if camera.isHdrOn {
            copy.mode = DynamicRange.hdrOn
        } else {
            copy.mode = DynamicRange.hdrOff
        }

        state.set(copy)
    }

    /// Updates dynamic range available modes.
    ///
    /// - Parameters:
    ///     - camera: current camera
    func updateAvailableModes(with camera: MainCamera2) {
        let copy = state.value.copy()
        copy.supportedModes = camera.hdrAvailable ? DynamicRange.allCases : [DynamicRange.plog, DynamicRange.hdrOff]
        copy.showUnsupportedModes = true
        state.set(copy)
    }
}