//    Copyright (C) 2022 Parrot Drones SAS
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

import Foundation

import Combine
import ArcGIS
import GroundSdk

/// ViewModel for `TouchAndFlyGraphicsOverlayViewModel`
public class TouchAndFlyGraphicsOverlayViewModel {

    public enum GraphicType: Equatable {
        case none
        case waypoint(location: Location3D)
        case poi(location: Location3D)
    }
    // MARK: - Private Properties
    private let touchAndFlyUIService: TouchAndFlyUiService = Services.hub.touchAndFlyUi
    /// Current drone location
    private var graphicType = CurrentValueSubject<GraphicType, Never>(.none)

    // MARK: - Public Properties
    public let locationsTracker: LocationsTracker = Services.hub.locationsTracker
    public var droneLocationPublisher: AnyPublisher<OrientedLocation, Never> { locationsTracker.droneLocationPublisher }
    public var graphicTypePublisher: AnyPublisher<GraphicType, Never> { graphicType.eraseToAnyPublisher() }

    init() {
        touchAndFlyUIService.start()
    }

    // MARK: - Public Funcs
    /// Displays a waypoint at target location.
    ///
    /// - Parameters:
    ///    - location: waypoint's location
    ///    - droneLocation: drone's location
    func displayWayPoint(at location: Location3D) {
        graphicType.value = .waypoint(location: location)
    }

    /// Displays a point of interest at target location.
    ///
    /// - Parameters:
    ///    - location: point of interest's location
    func displayPoiPoint(at location: Location3D) {
        graphicType.value = .poi(location: location)
    }

    /// Removes Touch and Fly graphics from map.
    func clearTouchAndFly() {
        graphicType.value = .none
    }
}
