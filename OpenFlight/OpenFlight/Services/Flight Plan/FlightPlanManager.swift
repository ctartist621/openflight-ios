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

import Foundation
import Combine
import SdkCore

public protocol FlightPlanManager {

    /// Creates a new Flight Plan with the same title, type, version, flightPlanType, dataSetting.
    ///
    /// - Parameters:
    ///     - flightPlan: flight plan to be based on
    /// - Returns: a new flight plan. The duplicated flight plan is in `.editable` state has
    ///            a new uuid & thumbnail and has the following fields cleared:
    ///            `lastMissionItemExecuted`,
    ///            `recoveryResourceId`,
    ///            `pgyProjectId`,
    ///            `uploadedMediaCount`,
    ///            `mediaCount`,
    ///            `parrotCloudId`,
    ///            `parrotCloudToBeDeleted`,
    ///            `parrotCloudUploadUrl`,
    ///            `synchroDate`
    ///            `synchroStatus`
    ///            `fileSynchroStatus`
    ///            `fileSynchroDate`
    func newFlightPlan(basedOn flightPlan: FlightPlanModel) -> FlightPlanModel

    /// Deletes a flightPlan.
    ///
    /// - Parameters:
    ///     - flightPlan: flight plan to delete
    func delete(flightPlan: FlightPlanModel)

    /// Updates flightplan state and saves it in CoreData
    ///
    /// - Parameters:
    ///     - flightplan: flight plan to update
    ///     - state: update the flightplan with this new state
    func update(flightplan: FlightPlanModel, with state: FlightPlanModel.FlightPlanState) -> FlightPlanModel

    /// Updates flightplan lastMissionItemExecuted
    /// - Parameters:
    ///   - flightPlan: flight plan
    ///   - lastMissionItemExecuted: last item executed
    ///   - recoveryResourceId: first resource identifier of media captured after the latest reached waypoint
    /// - Returns: the updated flight pan
    func update(flightPlan: FlightPlanModel, lastMissionItemExecuted: Int, recoveryResourceId: String?) -> FlightPlanModel

    /// Updates flightplan lastMissionItemExecuted
    /// - Parameters:
    ///   - flightPlan: flight plan
    ///   - lastMissionItemExecuted: last item executed
    ///   - recoveryResourceId: first resource identifier of media captured after the latest reached waypoint
    ///   - databaseUpdateCompletion: the completion block called when data base has been updated
    /// - Returns: the updated flight pan
    ///
    /// - Description: This method can be used, instead of the one without completion, to perform some actions (e.g. clear recoveryinfo)
    ///                only when the database has been correctly updated.
    func update(flightPlan: FlightPlanModel,
                lastMissionItemExecuted: Int,
                recoveryResourceId: String?,
                databaseUpdateCompletion: ((_ status: Bool) -> Void)?) -> FlightPlanModel

    /// Updates flightplan `customTitle` and saves it in CoreData.
    ///
    /// - Parameters:
    ///    - flightplan: flight plan to update.
    ///    - customTitle: the new `customTitle` value.
    func update(flightplan: FlightPlanModel, with customTitle: String) -> FlightPlanModel

    /// Get all Editable flightplans linked to a specific project
    ///
    /// - parameters:
    ///     - projectId: project to consider
    /// - Returns: List of flight plans ordered by lastUpdate
    func editableFlightPlansFor(projectId: String) -> [FlightPlanModel]

    /// Updates a flight plan with **lastUploadAttempt** set to today date and **uploadAttemptCount** incremented
    ///
    /// - Parameter flightplan: flight plan to be updated
    /// - Returns: Flight plan updated
    func updateWithUploadAttempt(flightplan: FlightPlanModel) -> FlightPlanModel

    /// Gets a flight plan given its uuid
    /// - Parameter uuid: uuid of the flight plan
    func flightPlan(uuid: String) -> FlightPlanModel?

    /// Gets a flight plan given its pgyId
    /// - Parameter pgyId: pgyId of a project
    func flightPlanWith(pgyId: Int64) -> FlightPlanModel?

    /// Gets all flight plans according to a specific state
    /// - Parameter state: state to filter
    func flightPlansForState(_ state: FlightPlanModel.FlightPlanState) -> [FlightPlanModel]

    /// Gets all flight plans according to a specific state
    /// - Parameters:
    ///    - state: state to filter
    ///    - completion: Callback closure on completion
    func flightPlansForState(_ state: FlightPlanModel.FlightPlanState, completion: @escaping (([FlightPlanModel]) -> Void))

    /// Get the last flight date of a flight plan if any
    /// - Parameter flightPlan: flight plan
    func lastFlightDate(_ flightPlan: FlightPlanModel) -> Date?

    /// Get the first FlightPlan's Flight date.
    /// - Parameter flightPlanModel: the Flight Plan
    /// - Returns: the `Date` if exists or `nil`
    func firstFlightDate(of flightPlan: FlightPlanModel) -> Date?

    /// Returns the formatted start date of the first FlightPlan's Flight.
    ///
    /// - Parameters:
    ///  - flightPlan: the Flight Plan
    /// - Returns: formatted date or dash if formatting failed
    ///
    /// - Description:
    /// Following scenarios are possible:
    ///   • An execution is linked to one Flight.
    ///     (when only one FP is executed between the take-off and the landing).
    ///   • Several executions are linked to the same Flight.
    ///     (when several FPs are executed between the take-off and the landing).
    ///   • An execution is linked to several Flights.
    ///     (when FP is paused then resumed with landing between them).
    /// Note: An execution is an FP which is not in editable mode.
    ///
    /// This method searches for the first FlightPlan's Flight and gets its start date (representing the Drone's take-off date).
    ///  If not found, we fallback into the execution's date which represents the moment when the FP has ben launched.
    func firstFlightFormattedDate(of flightPlan: FlightPlanModel) -> String
}

private extension ULogTag {
    static let tag = ULogTag(name: "FPManager")
}

public class FlightPlanManagerImpl: FlightPlanManager {
    private let persistenceFlightPlan: FlightPlanRepository!
    private let userService: UserService!
    private let filesManager: FlightPlanFilesManager!
    private let pgyProjectRepo: PgyProjectRepository!

    public init(persistenceFlightPlan: FlightPlanRepository,
                userService: UserService,
                filesManager: FlightPlanFilesManager,
                pgyProjectRepo: PgyProjectRepository) {
        self.persistenceFlightPlan = persistenceFlightPlan
        self.userService = userService
        self.filesManager = filesManager
        self.pgyProjectRepo = pgyProjectRepo
    }

    // MARK: - Private Functions

    private func persist(_ flightPlan: FlightPlanModel,
                         toSynchro: Bool,
                         withFileUploadNeeded: Bool) {
        persistenceFlightPlan.saveOrUpdateFlightPlan(flightPlan,
                                                     byUserUpdate: true,
                                                     toSynchro: toSynchro,
                                                     withFileUploadNeeded: withFileUploadNeeded)
    }

    // MARK: - Public Functions

    public func newFlightPlan(basedOn flightPlan: FlightPlanModel) -> FlightPlanModel {
        var newFlightPlan = flightPlan
        if let dataSetting = flightPlan.dataSetting {
            newFlightPlan.dataSetting = dataSetting.copy()
        }
        newFlightPlan.uuid = UUID().uuidString
        newFlightPlan.lastUpdate = Date()
        newFlightPlan.state = .editable
        newFlightPlan.lastMissionItemExecuted = 0
        newFlightPlan.recoveryResourceId = nil
        newFlightPlan.pgyProjectId = 0
        newFlightPlan.uploadedMediaCount = 0
        newFlightPlan.mediaCount = 0
        newFlightPlan.uploadAttemptCount = 0
        newFlightPlan.cloudId = 0
        newFlightPlan.isLocalDeleted = false
        newFlightPlan.parrotCloudUploadUrl = nil
        newFlightPlan.latestCloudModificationDate = nil
        newFlightPlan.latestSynchroStatusDate = nil
        newFlightPlan.synchroStatus = nil
        newFlightPlan.fileSynchroStatus = nil
        newFlightPlan.fileSynchroDate = nil
        newFlightPlan.synchroError = nil
        let thumbnailUUID = UUID().uuidString
        newFlightPlan.thumbnail = ThumbnailModel(apcId: userService.currentUser.apcId,
                                                 uuid: thumbnailUUID,
                                                 flightUuid: nil,
                                                 thumbnailImage: flightPlan.thumbnail?.thumbnailImage)
        newFlightPlan.thumbnailUuid = thumbnailUUID
        newFlightPlan.flightPlanFlights = []
        newFlightPlan.dataSetting?.notPropagatedSettings = [:]
        newFlightPlan.dataSetting?.pgyProjectId = 0

        let fpLog = " flight plan \(flightPlan.uuid) in project \(flightPlan.projectUuid) with thumbnail \(flightPlan.thumbnail?.uuid ?? "-")"
        let newFpLog = " new flight plan \(newFlightPlan.uuid) in project \(newFlightPlan.projectUuid) with thumbnail \(newFlightPlan.thumbnail?.uuid ?? "-")"
        ULog.d(.tag, "newFlightPlan based on \(fpLog) for \(newFpLog)")

        return newFlightPlan
    }

    public func delete(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Deleting flightPlan '\(flightPlan.uuid)'")
        if flightPlan.pgyProjectId > 0 {
            pgyProjectRepo.deletePgyProjects(withProjectIds: [flightPlan.pgyProjectId])
        }
        filesManager.deleteMavlink(of: flightPlan)
        persistenceFlightPlan.deleteOrFlagToDeleteFlightPlans(withUuids: [flightPlan.uuid], completion: nil)
    }

    public func editableFlightPlansFor(projectId: String) -> [FlightPlanModel] {
        let editableFps = persistenceFlightPlan.getFlightPlans(withProjectUuid: projectId, withState: FlightPlanModel.FlightPlanState.editable)
        ULog.d(.tag, "editableFlightPlansFor for projectId \(projectId): \(editableFps)")
        return editableFps
    }

    public func flightPlansForState(_ state: FlightPlanModel.FlightPlanState) -> [FlightPlanModel] {
        persistenceFlightPlan.getFlightPlans(byExcludingTypes: ["default"]).filter { $0.state.rawValue == state.rawValue }
    }

    public func flightPlansForState(_ state: FlightPlanModel.FlightPlanState, completion: @escaping (([FlightPlanModel]) -> Void)) {
        persistenceFlightPlan.getFlightPlans(withState: state, byExcludingTypes: ["default"], completion: completion)
    }

    public func updateWithUploadAttempt(flightplan: FlightPlanModel) -> FlightPlanModel {
        var updatedFlightplan = flightplan
        updatedFlightplan.lastUploadAttempt = Date()
        updatedFlightplan.uploadAttemptCount += 1
        persist(updatedFlightplan,
                toSynchro: false,
                withFileUploadNeeded: false)
        ULog.i(.tag, "Update flightPlan '\(updatedFlightplan.uuid)' uploadAttempt to \(updatedFlightplan.uploadAttemptCount)")
        return updatedFlightplan
    }

    public func update(flightplan: FlightPlanModel, with state: FlightPlanModel.FlightPlanState) -> FlightPlanModel {
        var newStateFlightPlan = flightplan
        newStateFlightPlan.state = state
        newStateFlightPlan.lastUpdate = Date()
        persist(newStateFlightPlan,
                toSynchro: true,
                withFileUploadNeeded: false)
        ULog.i(.tag, "Update flightPlan '\(newStateFlightPlan.uuid)' state to '\(state)'")
        return newStateFlightPlan
    }

    public func update(flightplan: FlightPlanModel, with customTitle: String) -> FlightPlanModel {
        var newFlightPlan = flightplan
        newFlightPlan.customTitle = customTitle
        persist(newFlightPlan,
                toSynchro: true,
                withFileUploadNeeded: false)
        ULog.i(.tag, "Update flightPlan '\(newFlightPlan.uuid)' customTitle to '\(customTitle)'")
        return newFlightPlan
    }

    public func update(flightPlan: FlightPlanModel,
                       lastMissionItemExecuted: Int,
                       recoveryResourceId: String?) -> FlightPlanModel {
        update(flightPlan: flightPlan,
               lastMissionItemExecuted: lastMissionItemExecuted,
               recoveryResourceId: recoveryResourceId,
               databaseUpdateCompletion: nil)
    }

    public func update(flightPlan: FlightPlanModel,
                       lastMissionItemExecuted: Int,
                       recoveryResourceId: String?,
                       databaseUpdateCompletion: ((_ status: Bool) -> Void)?) -> FlightPlanModel {
        guard lastMissionItemExecuted >= flightPlan.lastMissionItemExecuted else {
            // update flightplan only if new value of `last mission item executed` is greater or equal to current value
            return flightPlan
        }
        var newFlightPlan = flightPlan
        // The `lastMissionItemExecuted` must be set before checking hasReachedLastWayPoint
        newFlightPlan.lastMissionItemExecuted = Int64(lastMissionItemExecuted)

        // Update flight plan completion state.
        // The `state` field will be updated by the State Machine / Run Manager.
        if let mavlinkCommands = flightPlan.mavlinkCommands {
            newFlightPlan.hasReachedFirstWayPoint = mavlinkCommands.hasReachedFirstWayPoint(index: lastMissionItemExecuted)
            newFlightPlan.hasReachedLastWayPoint = mavlinkCommands.hasReachedLastWayPoint(index: lastMissionItemExecuted)
            newFlightPlan.lastPassedWayPointIndex = mavlinkCommands.lastPassedWayPointIndex(for: lastMissionItemExecuted)
            let percentCompleted = mavlinkCommands.percentCompleted(for: lastMissionItemExecuted, flightPlan: newFlightPlan)
            newFlightPlan.percentCompleted = percentCompleted
        }

        newFlightPlan.recoveryResourceId = recoveryResourceId
        persistenceFlightPlan.saveOrUpdateFlightPlan(newFlightPlan,
                                                     byUserUpdate: true,
                                                     toSynchro: false,
                                                     withFileUploadNeeded: false,
                                                     completion: databaseUpdateCompletion)
        return newFlightPlan
    }

    public func flightPlan(uuid: String) -> FlightPlanModel? {
        persistenceFlightPlan.getFlightPlan(withUuid: uuid)
    }

    public func flightPlanWith(pgyId: Int64) -> FlightPlanModel? {
        persistenceFlightPlan.getFlightPlan(withPgyProjectId: pgyId)
    }

    public func lastFlightDate(_ flightPlan: FlightPlanModel) -> Date? {
        persistenceFlightPlan.getLastFlightDateOfFlightPlan(flightPlan)
    }

    public func firstFlightDate(of flightPlan: FlightPlanModel) -> Date? {
        persistenceFlightPlan.firstFlightDate(of: flightPlan)
    }

    public func firstFlightFormattedDate(of flightPlan: FlightPlanModel) -> String {
        // If not found, return the execution date.
        guard let flightDate = firstFlightDate(of: flightPlan) else {
            return flightPlan.formattedDate()
        }
        // Format the date.
        return flightDate.commonFormattedString
    }
}
