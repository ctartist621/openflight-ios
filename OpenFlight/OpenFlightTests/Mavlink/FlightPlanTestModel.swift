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
@testable import OpenFlight
import CoreLocation

struct FlightPlanTestModel: Codable {
    var uuid: String
    var type: String
    var dataSetting: FlightPlanDataSetting?

    func flightPlanModel() -> FlightPlanModel {
        var fpm = FlightPlanModel(apcId: "", type: type, uuid: uuid,
                                  version: "", customTitle: "", thumbnailUuid: nil,
                                  projectUuid: "", dataStringType: "",
                                  dataString: nil, pgyProjectId: nil,
                                  state: .unknown, lastMissionItemExecuted: nil,
                                  mediaCount: nil, uploadedMediaCount: nil,
                                  lastUpdate: Date(), synchroStatus: nil,
                                  fileSynchroStatus: 0, fileSynchroDate: nil,
                                  latestSynchroStatusDate: nil, cloudId: nil,
                                  parrotCloudUploadUrl: nil, isLocalDeleted: false,
                                  latestCloudModificationDate: nil,
                                  uploadAttemptCount: nil, lastUploadAttempt: nil,
                                  thumbnail: nil, flightPlanFlights: nil,
                                  latestLocalModificationDate: nil,
                                  synchroError: nil)
        var dataSetting = self.dataSetting
        dataSetting?.mavlinkDataFile = nil
        fpm.dataSetting = dataSetting
        return fpm
    }

}