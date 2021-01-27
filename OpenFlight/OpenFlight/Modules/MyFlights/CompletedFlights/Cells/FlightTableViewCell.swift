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

import UIKit
import Reusable

/// Flight TableViewCell.

final class FlightTableViewCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var dateView: UIView!
    @IBOutlet private weak var dateStackView: UIStackView!
    @IBOutlet private weak var monthLabel: UILabel! {
        didSet {
            monthLabel.makeUp(with: .large)
        }
    }
    @IBOutlet private weak var yearLabel: UILabel! {
        didSet {
            yearLabel.makeUp(and: .white50)
        }
    }
    @IBOutlet private weak var bgView: UIView! {
        didSet {
            bgView.backgroundColor = ColorName.white10.color
            bgView.applyCornerRadius(Style.mediumCornerRadius)
        }
    }
    @IBOutlet private weak var mapImage: UIImageView! {
        didSet {
            mapImage.applyCornerRadius()
        }
    }
    @IBOutlet private weak var nameLabel: UILabel! {
        didSet {
            nameLabel.makeUp(with: .large)
        }
    }
    @IBOutlet private weak var dateLabel: UILabel! {
        didSet {
            dateLabel.makeUp(and: .white50)
        }
    }
    @IBOutlet private weak var photoLabel: UILabel! {
        didSet {
            photoLabel.makeUp(with: .tiny)
        }
    }
    @IBOutlet private weak var videoLabel: UILabel! {
        didSet {
            videoLabel.makeUp(with: .tiny)
        }
    }
    @IBOutlet private weak var warningStackView: UIStackView!
    @IBOutlet private weak var warningLabel: UILabel! {
        didSet {
            warningLabel.makeUp(and: .redTorch)
        }
    }

    // MARK: - Internal Funcs
    /// Configure cell.
    ///
    /// - Parameters:
    ///    - viewModel: Flight data view model
    ///    - showDate: Show flight date
    func configureCell(viewModel: FlightDataViewModel, showDate: Bool) {
        initCell()
        // Setup date section display.
        dateView.isHidden = !(UIApplication.isLandscape || showDate)
        dateView.alpha = showDate ? 1.0 : 0.0
        dateStackView.axis =  UIApplication.isLandscape ? .horizontal : .vertical
        // Setup content.
        if showDate {
            let date = viewModel.state.value.date
            monthLabel.text = date?.month.capitalized
            yearLabel.text = date?.year
        }
        dateLabel.text = viewModel.state.value.formattedDate
        nameLabel.text = viewModel.state.value.title

        warningStackView.isHidden = !viewModel.state.value.hasIssues
        if viewModel.state.value.hasIssues {
            // TODO: read gutma and update label accordingly.
            warningLabel.text = "Issue with this flight"
        }

        self.mapImage.image = viewModel.state.value.thumbnail ?? Asset.MyFlights.mapPlaceHolder.image
        viewModel.state.valueChanged = { [weak self] state in
            self?.mapImage.image = state.thumbnail ?? Asset.MyFlights.mapPlaceHolder.image
            self?.nameLabel.text = state.title
        }
        viewModel.requestThumbnail()
        viewModel.requestPlacemark()
    }
}

// MARK: - Private Funcs
private extension FlightTableViewCell {
    func initCell() {
        photoLabel.text = Style.dash
        videoLabel.text = Style.dash
    }
}
