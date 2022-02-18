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

class FlightsViewModel {

    private let service: FlightService
    private let navigationStack: NavigationStackService
    private weak var coordinator: MyFlightsCoordinator?

    var flights: AnyPublisher<[FlightModel], Never> { service.allFlights }
    @Published private(set) var selectedFlight: FlightModel?
    private var cancellable = Set<AnyCancellable>()

    init(service: FlightService,
         coordinator: MyFlightsCoordinator,
         navigationStack: NavigationStackService) {
        self.service = service
        self.coordinator = coordinator
        self.navigationStack = navigationStack

        Services.hub.cloudSynchroWatcher?.isSynchronizingDataPublisher.sink { isSynchronizingData in
            if !isSynchronizingData {
                Task {
                    do {
                        await self.service.handleFlightsUnknownLocationTitle()
                    }
                }
            }
        }.store(in: &cancellable)
    }

    func delete(flight: FlightModel) {
        service.delete(flight: flight)
    }

    func didTapOn(flight: FlightModel) {
        navigationStack.updateLast(with: .myFlights(selectedFlight: flight))
        coordinator?.startFlightDetails(flight: flight)
        selectedFlight = flight
    }

    func askForDeletion(flight: FlightModel) {
        coordinator?.showDeleteFlightPopupConfirmation(didTapDelete: {
            self.service.delete(flight: flight)
        })
     }

    func cellViewModel(flight: FlightModel) -> FlightTableViewCellModel {
        FlightTableViewCellModel(service: service,
                                 flight: flight,
                                 flightsViewModel: self)
    }

    func didSelectFlight(_ flight: FlightModel) {
        selectedFlight = flight
    }
}
