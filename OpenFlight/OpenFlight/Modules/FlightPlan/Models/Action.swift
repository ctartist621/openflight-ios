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
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "FlightPlanAction")
}

// MARK: - Public Enums
enum ActionType: String, Codable {
    case takeOff = "TakeOff"
    case landing = "Landing"
    case tilt = "Tilt"
    case delay = "Delay"
    // TODO: remove Image Start/Stop Capture commands and use CameraTrigger{Distance,Interval}Command if only Time/GPS lapse is needed.
    case imageStartCapture = "ImageStartCapture"
    case imageStopCapture = "ImageStopCapture"
    case videoStartCapture = "VideoStartCapture"
    case videoStopCapture = "VideoStopCapture"
    case panorama = "Panorama"
    case stillCapture = "StillCapture"
}

/// A FlightPlan action such as "start photo capture" or "stop video capture".
public struct Action: Codable, Equatable {

    // MARK: - Public Properties
    var type: ActionType
    var angle: Double?
    var speed: Double?
    var delay: Double?
    var period: Double?
    var nbOfPictures: Int?
    var captureMode: MavlinkStandard.SetStillCaptureModeCommand.PhotoMode?

    var recordingResolution: CameraRecordingResolution? {
        get {
            switch resolution {
            case Constants.resolutionDci4k:
                return .resDci4k
            case Constants.resolutionUhd4k:
                return .resUhd4k
            case Constants.resolution27k:
                return .res2_7k
            case Constants.resolution1080p:
                return .res1080p
            case Constants.resolution1080pSd:
                return .res1080pSd
            case Constants.resolution720p:
                return .res720p
            case Constants.resolution720pSd:
                return .res720pSd
            case  Constants.resolution480p:
                return .res480p
            default:
                return nil
            }
        }
        set {
            switch newValue {
            case .resDci4k:
                resolution = Constants.resolutionDci4k
            case .resUhd4k:
                resolution = Constants.resolutionUhd4k
            case .res2_7k:
                resolution = Constants.resolution27k
            case .res1080p:
                resolution = Constants.resolution1080p
            case .res1080pSd:
                resolution = Constants.resolution1080pSd
            case .res720p:
                resolution = Constants.resolution720p
            case .res720pSd:
                resolution = Constants.resolution720pSd
            case .res480p:
                resolution = Constants.resolution480p
            default:
                break
            }
        }
    }

    var photoFormat: PhotoFormatMode? {
        get {
            switch resolution {
            case Constants.resolutionFullFrameJpeg:
                return .fullFrameJpeg
            case Constants.resolutionRectilinearJpeg:
                return .rectilinearJpeg
            case Constants.resolutionFullFrameDngJpeg:
                return .fullFrameDngJpeg
            default:
                return nil
            }
        }
        set {
            switch newValue {
            case .fullFrameJpeg:
                resolution = Constants.resolutionFullFrameJpeg
            case .rectilinearJpeg:
                resolution = Constants.resolutionRectilinearJpeg
            case .fullFrameDngJpeg:
                resolution = Constants.resolutionFullFrameDngJpeg
            default:
                break
            }
        }
    }

    /// MAVLink command depending on action type.
    var mavlinkCommand: MavlinkStandard.MavlinkCommand {
        switch type {
        case .takeOff:
            return MavlinkStandard.TakeOffCommand()
        case .landing:
            return MavlinkStandard.LandCommand()
        case .tilt:
            // TODO: handle yaw.
            return MavlinkStandard.MountControlCommand(tiltAngle: angle ?? 0.0, yaw: 0.0)
        case .delay:
            return MavlinkStandard.DelayCommand(delay: delay ?? 0.0)
        case .imageStartCapture:
            // TODO: set sequenceNumber to 1 if it is a single capture.
            return MavlinkStandard.StartPhotoCaptureCommand(interval: period ?? 0.0,
                                                            count: nbOfPictures ?? 0,
                                                            sequenceNumber: 0)
        case .imageStopCapture:
            return MavlinkStandard.StopPhotoCaptureCommand()
        case .videoStartCapture:
            return MavlinkStandard.StartVideoCaptureCommand()
        case .videoStopCapture:
            return MavlinkStandard.StopVideoCaptureCommand()
        case .panorama:
            return MavlinkStandard.CreatePanoramaCommand(horizontalAngle: angle ?? 0.0,
                                                         horizontalSpeed: speed ?? 0.0,
                                                         verticalAngle: 0.0,
                                                         verticalSpeed: 0.0)
        case .stillCapture:
            // TODO: handle photo mode.
            return MavlinkStandard.SetStillCaptureModeCommand(mode: captureMode ?? .rectilinear)
        }
    }

    // MARK: - Private Properties
    private var resolution: Double?

    // MARK: - Private Enums
    enum CodingKeys: String, CodingKey {
        case type
        case angle
        case speed
        case delay
        case period
        case resolution
        case nbOfPictures
    }

    private enum Constants {
        static let resolutionDci4k: Double = 4096 * 2160
        static let resolutionUhd4k: Double = 3840 * 2160
        static let resolution27k: Double = 2704 * 1524
        static let resolution1080p: Double = 1920 * 1080
        static let resolution1080pSd: Double = 1440 * 1080
        static let resolution720p: Double = 1280 * 720
        static let resolution720pSd: Double = 1280 * 720
        static let resolution480p: Double = 856 * 480
        static let resolutionFullFrameJpeg: Double = 13.6
        static let resolutionRectilinearJpeg: Double = 12.58291244506836
        static let resolutionFullFrameDngJpeg = 14.0
    }

    // MARK: - Init
    /// Constructor.
    ///
    /// - Parameters:
    ///    - type: action type
    ///    - angle: camera tilt angle
    ///    - speed: angular speed
    ///    - delay: delay duration
    ///    - period: photo capture interval
    ///    - nbOfPictures: number of photo to capture
    ///    - captureMode: photo capture mode
    init(type: ActionType,
         angle: Double? = nil,
         speed: Double? = nil,
         delay: Double? = nil,
         period: Double? = nil,
         nbOfPictures: Int? = nil,
         captureMode: MavlinkStandard.SetStillCaptureModeCommand.PhotoMode? = nil) {
        self.type = type
        self.angle = angle
        self.delay = delay
        self.period = period
        self.nbOfPictures = nbOfPictures
        self.captureMode = captureMode
    }

    /// Init with Mavlink command.
    ///
    /// - Parameters:
    ///    - mavLinkCommand: Mavlink command
    public init?(mavLinkCommand: MavlinkStandard.MavlinkCommand) {
        switch mavLinkCommand {
        case is MavlinkStandard.TakeOffCommand:
            self.init(type: .takeOff)
        case is MavlinkStandard.LandCommand:
            self.init(type: .landing)
        case let command as MavlinkStandard.MountControlCommand:
            self.init(type: .tilt,
                      angle: command.tiltAngle)
        case let command as MavlinkStandard.DelayCommand:
            self.init(type: .delay,
                      delay: command.delay)
        case let command as MavlinkStandard.StartPhotoCaptureCommand:
            self.init(type: .imageStartCapture,
                      period: command.interval,
                      nbOfPictures: command.count)
        case is MavlinkStandard.StopPhotoCaptureCommand:
            self.init(type: .imageStopCapture)
        case is MavlinkStandard.StartVideoCaptureCommand:
            self.init(type: .videoStartCapture)
        case is MavlinkStandard.StopVideoCaptureCommand:
            self.init(type: .videoStopCapture)
        case let command as MavlinkStandard.CreatePanoramaCommand:
            self.init(type: .panorama,
                      angle: command.horizontalAngle,
                      speed: command.horizontalSpeed)
        case let command as MavlinkStandard.SetStillCaptureModeCommand:
            self.init(type: .stillCapture,
                      captureMode: command.mode)
        case let command as MavlinkStandard.ReturnToLaunchCommand:
            ULog.w(.tag, "No action for: \(command)")
            return nil
        default:
            // FIXME: Remove this print when all MavLink commands management will be approved.
            ULog.e(.tag, "Unknown mavlink command : \(mavLinkCommand)")
            return nil
        }
    }

    // MARK: - Public Funcs
    /// Instantiate a new action to modify camera tilt.
    ///
    /// - Parameters:
    ///    - angle: angle of camera tilt
    ///    - speed: angular speed to reach new camera tilt
    ///
    /// - Returns: An action of type `tilt`
    static func tiltAction(angle: Double, speed: Double) -> Action {
        Action(type: .tilt, angle: angle, speed: speed)
    }

    /// Instantiate a new action to delay FlightPlan.
    ///
    /// - Parameters:
    ///    - delay: delay to wait
    ///
    /// - Returns: An action of type `delay`
    static func delayAction(delay: Double) -> Action {
        Action(type: .delay, delay: delay)
    }

    public static func == (lhs: Action, rhs: Action) -> Bool {
        rhs.type == lhs.type
        && rhs.angle == lhs.angle
        && rhs.speed == lhs.speed
        && rhs.delay == lhs.delay
        && rhs.period == lhs.period
        && rhs.nbOfPictures == lhs.nbOfPictures
        && rhs.captureMode == lhs.captureMode
        && rhs.resolution == lhs.resolution
    }
}
