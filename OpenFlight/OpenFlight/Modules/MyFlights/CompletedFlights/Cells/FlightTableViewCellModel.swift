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
import Combine
import CoreLocation
import MapKit

open class FlightTableViewCellModel {

    private let service: FlightService

    @Published private(set) public var name: String?
    @Published private(set) var thumbnail: UIImage?
    @Published private(set) var isSelected: Bool = false

    open private(set) var flight: FlightModel
    private(set) var flightsViewModel: FlightsViewModel?

    private var cancellables = Set<AnyCancellable>()

    init(service: FlightService,
         flight: FlightModel,
         flightsViewModel: FlightsViewModel?) {
        self.service = service
        self.flight = flight
        self.flightsViewModel = flightsViewModel
        if let title = flight.title, !title.isEmpty {
            name = title
        } else {
            name = L10n.dashboardMyFlightUnknownLocation
        }
        self.thumbnail = flight.thumbnail?.thumbnailImage
        flightsViewModel?.$selectedFlight
            .sink { [weak self] in
                self?.isSelected = $0?.uuid == flight.uuid
            }
            .store(in: &cancellables)
    }
}
