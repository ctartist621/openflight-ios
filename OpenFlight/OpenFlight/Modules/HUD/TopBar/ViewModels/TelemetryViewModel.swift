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

import GroundSdk
import Combine

// MARK: - Public Structs
/// Struct representing a telemetry value and its associated alert level.
struct TelemetryValueModel: Equatable {
    var currentValue: Double?
    var alertLevel: AlertLevel = .none
}

// MARK: - TelemetryState
/// State for `TelemetryViewModel`.
final class TelemetryState: ViewModelState {
    // MARK: - Internal Properties
    /// Observable for current speed.
    fileprivate(set) var speed = Observable(TelemetryValueModel())
    /// Observable for takeoff relative altitude.
    fileprivate(set) var takeoffRelativeAltitude = Observable(TelemetryValueModel())
    /// Observable for ground relative altitude (AGL).
    fileprivate(set) var groundRelativeAltitude = Observable(TelemetryValueModel())
    /// Observable for absolute altitude.
    fileprivate(set) var absoluteAltitude = Observable(TelemetryValueModel())
    /// Observable for current distance.
    fileprivate(set) var distance = Observable(TelemetryValueModel())
}

// MARK: - TelemetryViewModel
/// ViewModel for Telemetry, notifies on speed, altitude and distance changes.
final class TelemetryViewModel: DroneWatcherViewModel<TelemetryState> {
    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var geofenceRef: Ref<Geofence>?
    private var gpsRef: Ref<Gps>?
    private var speedometerRef: Ref<Speedometer>?
    private var altimeterRef: Ref<Altimeter>?
    private var userLocationManager: LocationManager

    /// Returns current distance to user location,
    /// `nil` if drone's gps and/or user location is unavailable.
    private var distanceToUserLocation: Double? {
        guard let drone = drone,
            let userLocation = groundSdk.getFacility(Facilities.userLocation),
            userLocation.isGpsActive,
            let droneGps = drone.getInstrument(Instruments.gps),
            droneGps.fixed,
            let droneLocation = droneGps.lastKnownLocation,
            let distance = userLocation.location?.distance(from: droneLocation)
            else {
                return nil
        }
        return distance.rounded(toPlaces: Constants.distanceDigitPrecision)
    }

    // MARK: - Private Enums
    private enum Constants {
        static let speedDigitPrecision: Int = 1
        static let altitudeDigitPrecision: Int = 0
        static let distanceDigitPrecision: Int = 0
    }

    // MARK: - Init
    private override init() {
        fatalError("Forbidden init")
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///    - userLocationManager: provider for user location update callbacks
    ///    - speedDidChange: called when speed changes
    ///    - altitudeDidChange: called when altitude changes
    ///    - distanceDidChange: called when distance changes
    init(userLocationManager: LocationManager,
         speedDidChange: ((TelemetryValueModel) -> Void)? = nil,
         takeoffRelativeAltitudeDidChange: ((TelemetryValueModel) -> Void)? = nil,
         groundRelativeAltitudeDidChange: ((TelemetryValueModel) -> Void)? = nil,
         absoluteAltitudeDidChange: ((TelemetryValueModel) -> Void)? = nil,
         distanceDidChange: ((TelemetryValueModel) -> Void)? = nil) {
        self.userLocationManager = userLocationManager
        super.init()
        state.value.speed.valueChanged = speedDidChange
        state.value.takeoffRelativeAltitude.valueChanged = takeoffRelativeAltitudeDidChange
        state.value.groundRelativeAltitude.valueChanged = groundRelativeAltitudeDidChange
        state.value.absoluteAltitude.valueChanged = absoluteAltitudeDidChange
        state.value.distance.valueChanged = distanceDidChange
        listenUserLocation()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenSpeedometer(drone: drone)
        listenAltimeter(drone: drone)
        listenGps(drone: drone)
        listenGeofence(drone: drone)
    }
}

// MARK: - Private Funcs
private extension TelemetryViewModel {
    /// Starts watcher for speedometer.
    func listenSpeedometer(drone: Drone) {
        speedometerRef = drone.getInstrument(Instruments.speedometer) { [unowned self] _ in
            computeSpeed()
        }
    }

    /// Starts watcher for altimeter.
    func listenAltimeter(drone: Drone) {
        altimeterRef = drone.getInstrument(Instruments.altimeter) { [unowned self] _ in
            computeSpeed()
            computetakeoffRelativeAltitude()
            computeAbsoluteAltitude()
        }
    }

    /// Starts watcher for gps.
    func listenGps(drone: Drone) {
        gpsRef = drone.getInstrument(Instruments.gps) { [unowned self] _ in
            computeDistance()
        }
    }

    /// Starts watcher for geofence.
    func listenGeofence(drone: Drone) {
        geofenceRef = drone.getPeripheral(Peripherals.geofence) { [unowned self] _ in
            computetakeoffRelativeAltitude()
            computeDistance()
        }
    }

    /// Starts watcher for user location.
    func listenUserLocation() {
        userLocationManager.onLocationUpdate = { [unowned self] in
            computeDistance()
        }
    }

    /// Computes current speed and updates TelemetryState accordingly.
    func computeSpeed() {
        guard let drone = drone, drone.state.connectionState == .connected,
              let horizontalSpeed = drone.getInstrument(Instruments.speedometer)?.groundSpeed,
              let verticalSpeed = drone.getInstrument(Instruments.altimeter)?.verticalSpeed,
              !horizontalSpeed.isNaN, !verticalSpeed.isNaN else {
            state.value.speed.set(TelemetryValueModel(currentValue: nil, alertLevel: .none))
            return
        }
        let speed = sqrt(pow(horizontalSpeed, 2) + pow(verticalSpeed, 2)).rounded(toPlaces: Constants.speedDigitPrecision)
        state.value.speed.set(TelemetryValueModel(currentValue: speed, alertLevel: .none))
    }

    /// Computes current altitude and updates TelemetryState accordingly.
    func computetakeoffRelativeAltitude() {
        guard let drone = drone, drone.state.connectionState == .connected,
              let altitude = drone.getInstrument(Instruments.altimeter)?.takeoffRelativeAltitude,
              !altitude.isNaN
        else {
            state.value.takeoffRelativeAltitude.set(TelemetryValueModel(currentValue: nil, alertLevel: .none))
            return
        }
        let alertLevel: AlertLevel = drone.isAltitudeGeofenceReached == true ? .warning : .none
        state.value.takeoffRelativeAltitude.set(TelemetryValueModel(currentValue: altitude.rounded(toPlaces: Constants.altitudeDigitPrecision), alertLevel: alertLevel))
    }
    
    /// Computes current AGL and updates TelemetryState accordingly.
    func computeGroundRelativeAltitude() {
        guard let drone = drone, drone.state.connectionState == .connected,
              let groundRelativeAltitude = drone.getInstrument(Instruments.altimeter)?.groundRelativeAltitude,
              !groundRelativeAltitude.isNaN
        else {
            state.value.groundRelativeAltitude.set(TelemetryValueModel(currentValue: nil, alertLevel: .none))
            return
        }
        
        // Max FAA altitude is 400ft AGL
        let maxGroundRelativeAltitude: Double
        if UnitHelper.stringDistanceUnit() == "m" {
            maxGroundRelativeAltitude = 121
        } else {
            maxGroundRelativeAltitude = 400
        }
            
        let alertLevel: AlertLevel = (groundRelativeAltitude > maxGroundRelativeAltitude) == true ? .warning : .none
        state.value.groundRelativeAltitude.set(TelemetryValueModel(currentValue: groundRelativeAltitude.rounded(toPlaces: Constants.altitudeDigitPrecision), alertLevel: alertLevel))
    }
    
    /// Computes current Absolute Altitude and updates TelemetryState accordingly.
    func computeAbsoluteAltitude() {
        guard let drone = drone, drone.state.connectionState == .connected,
              let absoluteAltitude = drone.getInstrument(Instruments.altimeter)?.absoluteAltitude,
              !absoluteAltitude.isNaN
        else {
            state.value.absoluteAltitude.set(TelemetryValueModel(currentValue: nil, alertLevel: .none))
            return
        }
        // Max practical ceiling above sea level 5,000 m
        let maxAbsoluteAltitude: Double
        if UnitHelper.stringDistanceUnit() == "m" {
            maxAbsoluteAltitude = 5000
        } else {
            maxAbsoluteAltitude = 16404
        }

        let alertLevel: AlertLevel = (absoluteAltitude > maxAbsoluteAltitude) == true ? .warning : .none
        state.value.absoluteAltitude.set(TelemetryValueModel(currentValue: absoluteAltitude.rounded(toPlaces: Constants.altitudeDigitPrecision), alertLevel: alertLevel))
    }

    /// Computes current distance and updates TelemetryState accordingly.
    func computeDistance() {
        guard let drone = drone, drone.state.connectionState == .connected else {
            state.value.distance.set(TelemetryValueModel(currentValue: nil, alertLevel: .none))
            return
        }
        state.value.distance.set(TelemetryValueModel(currentValue: distanceToUserLocation,
                                                     alertLevel: drone.alertLevelForGeofenceDistanceState))
    }
}
