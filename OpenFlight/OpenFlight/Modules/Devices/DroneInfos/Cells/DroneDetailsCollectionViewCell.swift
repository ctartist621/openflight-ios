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

// MARK: - Internal Structs
/// Model for `DroneDetailsCollectionViewCell`.
struct DroneDetailsCollectionViewCellModel {
    var title: String
    var value: String?
    var valueImage: UIImage?

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - title: cell's title
    ///    - value: cell's value
    ///    - valueImage: image for cell's value
    init(title: String,
         value: String?,
         valueImage: UIImage? = nil) {
        self.title = title
        self.value = value
        self.valueImage = valueImage
    }
}

/// Displays a simple information in drone's information modal.

final class DroneDetailsCollectionViewCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!
    @IBOutlet private weak var valueImageView: UIImageView!

    // MARK: - Internal Properties
    var model: DroneDetailsCollectionViewCellModel? {
        didSet {
            fill()
        }
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.makeUp(with: .large)
        valueLabel.makeUp(with: .regular, and: .white50)
    }
}

// MARK: - Private Funcs
private extension DroneDetailsCollectionViewCell {
    /// Fills up the view with current model.
    func fill() {
        titleLabel.text = model?.title
        valueLabel.text = model?.value
        valueImageView.image = model?.valueImage
        valueImageView.isHidden = model?.valueImage == nil
    }
}