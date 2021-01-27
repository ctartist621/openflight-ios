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
/// Settings mode header view delegate.
protocol SettingsPresetViewDelegate: class {
    /// Notifies delegate when the selected mode did change.
    func settingsPresetViewSelectionDidChange(selectedMode: SettingsBehavioursMode)
}

/// Tab like view which manage settings behaviours mode.
final class SettingsPresetsView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var presetTitle: UILabel! {
        didSet {
            presetTitle.makeUp(with: .tiny, and: .white)
            presetTitle.text = L10n.settingsBehaviourMode.uppercased()
        }
    }
    @IBOutlet private weak var presetStackView: UIStackView!

    // MARK: - Private Properties
    private var items: [SettingsBehavioursMode] = []
    private weak var delegate: SettingsPresetViewDelegate?

    // MARK: - Private Enums
    private enum Constants {
        static let buttonWidth: CGFloat = 96.0
        static let imageEdgeInsets: CGFloat = 8.0
        static let activeColor: UIColor = ColorName.white10.color
        static let normalColor: UIColor = .clear
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitPresetsView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInitPresetsView()
    }

    // MARK: - Internal Funcs
    /// Setup view.
    ///
    /// - Parameters:
    ///     - items: content as SettingsBehavioursMode
    ///     - selectedMode: selected item
    ///     - delegate: Settings preset view delegate
    func setup(items: [SettingsBehavioursMode],
               selectedMode: SettingsBehavioursMode,
               delegate: SettingsPresetViewDelegate) {
        self.items = items
        self.delegate = delegate
        // Reset stack view.
        presetStackView.safelyRemoveArrangedSubviews()
        // Fill stack view.
        var index: Int = 0
        for item in items {
            let button = UIButton(frame: CGRect(x: 0.0,
                                                y: 0.0,
                                                width: Constants.buttonWidth,
                                                height: presetStackView.frame.height))
            button.widthAnchor.constraint(equalToConstant: Constants.buttonWidth).isActive = true
            button.setTitle(item.title, for: .normal)
            button.setImage(item.image, for: .normal)
            button.imageEdgeInsets.right = Constants.imageEdgeInsets
            button.customCornered(corners: [.topLeft, .topRight],
                                  radius: Style.smallCornerRadius)
            button.tag = index
            index += 1
            button.addTarget(self, action: #selector(modeTouchedUpInside(sender:)), for: .touchUpInside)
            button.makeup(with: .regular, color: .white)
            button.backgroundColor = item == selectedMode ? Constants.activeColor : Constants.normalColor
            presetStackView.addArrangedSubview(button)
        }
    }
}
// MARK: - Actions
private extension SettingsPresetsView {
    /// Called when user touch one of the preset stackview button.
    @objc func modeTouchedUpInside(sender: UIButton) {
        // Reset buttons background color.
        for view in presetStackView.arrangedSubviews {
            view.backgroundColor = Constants.normalColor
        }
        // Set selected button background color.
        sender.backgroundColor = Constants.activeColor
        // Notify delegate.
        let index = sender.tag
        if index < items.count, index >= 0 {
            delegate?.settingsPresetViewSelectionDidChange(selectedMode: items[index])
        }
    }
}

// MARK: - Private Funcs
private extension SettingsPresetsView {
    /// Init content.
    func commonInitPresetsView() {
        self.loadNibContent()
        self.backgroundColor = .black
    }
}