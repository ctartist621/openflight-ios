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

// MARK: - Protocols
protocol DroneListDelegate: class {
    /// Will be called when user touch refresh button.
    func refresh()
}

/// Cell used to refresh drones table view.

final class PairingConnectDroneRefreshView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var refreshView: UIView!
    @IBOutlet private weak var refreshButton: UIButton!

    // MARK: - Internal Properties
    weak var navDelegate: DroneListDelegate?

    // MARK: - Private Enums
    private enum Constants {
        static let borderWidth: CGFloat = 1.0
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
}

// MARK: - Actions
private extension PairingConnectDroneRefreshView {
    @IBAction func refreshButtonTouchedUpInside(_ sender: Any) {
        navDelegate?.refresh()
    }
}

// MARK: - Private Funcs
private extension PairingConnectDroneRefreshView {
    /// Init the view.
    func initView() {
        loadNibContent()
        refreshButton.cornerRadiusedWith(backgroundColor: UIColor.clear,
                                         borderColor: UIColor(named: .white),
                                         radius: Style.largeCornerRadius,
                                         borderWidth: Constants.borderWidth)
        refreshButton.setTitle(L10n.pairingRefreshDroneList, for: .normal)
    }
}