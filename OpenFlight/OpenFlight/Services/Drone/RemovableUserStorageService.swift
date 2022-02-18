//    Copyright (C) 2021 Parrot Drones SAS
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
import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "RemovableUserStorageService")
}

/// Drone camera photo capture service.
public protocol RemovableUserStorageService: AnyObject {
    /// Publisher for user storage file system state.
    var userStorageFileSystemStatePublisher: AnyPublisher<UserStorageFileSystemState, Never> { get }
    /// Current user storage file system state.
    var userStorageFileSystemState: UserStorageFileSystemState { get }
    /// Publisher for user storage physical state.
    var userStoragePhysicalStatePublisher: AnyPublisher<UserStoragePhysicalState, Never> { get }
    /// Current user storage physical state.
    var userStoragePhysicalState: UserStoragePhysicalState { get }
}

/// Implementation of `RemovableUserStorageService`.
public class RemovableUserStorageServiceImpl {

    // MARK: Private properties

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// Reference to camera peripheral.
    private var removableUserStorageRef: Ref<RemovableUserStorage>?
    /// User Storage file system state.
    private var userStorageFileSystemStateSubject = CurrentValueSubject<UserStorageFileSystemState, Never>(.ready)
    /// User Storage physical state.
    private var userStoragePhysicalStateSubject = CurrentValueSubject<UserStoragePhysicalState, Never>(.available)

    // MARK: init

    /// Constructor.
    ///
    /// - Parameters:
    ///   - currentDroneHolder: drone holder
    public init(currentDroneHolder: CurrentDroneHolder) {
        // listen to drone changes
        listen(dronePublisher: currentDroneHolder.dronePublisher)
    }
}

// MARK: Private functions
private extension RemovableUserStorageServiceImpl {

    /// Listens to the current drone.
    ///
    /// - Parameter dronePublisher: the drone publisher
    func listen(dronePublisher: AnyPublisher<Drone, Never>) {
        dronePublisher.sink { [unowned self] in
            listenToRemovableUserStorage(drone: $0)
        }
        .store(in: &cancellables)
    }

    /// Starts watcher for camera.
    ///
    /// - Parameters:
    ///     - drone: the drone.
    func listenToRemovableUserStorage(drone: Drone) {
        removableUserStorageRef = drone.getPeripheral(Peripherals.removableUserStorage) { [unowned self] in
            guard let removableUserStorage = $0 else { return }
            userStoragePhysicalStateSubject.value = removableUserStorage.physicalState
            userStorageFileSystemStateSubject.value = removableUserStorage.fileSystemState
        }
    }
}

// MARK: RemovableUserStorageService protocol conformance
extension RemovableUserStorageServiceImpl: RemovableUserStorageService {

    public var userStorageFileSystemStatePublisher: AnyPublisher<UserStorageFileSystemState, Never> { userStorageFileSystemStateSubject.eraseToAnyPublisher() }

    public var userStorageFileSystemState: UserStorageFileSystemState { userStorageFileSystemStateSubject.value }

    public var userStoragePhysicalStatePublisher: AnyPublisher<UserStoragePhysicalState, Never> { userStoragePhysicalStateSubject.eraseToAnyPublisher() }

    public var userStoragePhysicalState: UserStoragePhysicalState { userStoragePhysicalStateSubject.value }

}
