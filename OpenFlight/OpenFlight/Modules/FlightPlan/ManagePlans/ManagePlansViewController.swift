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

// MARK: - Protocols
/// Protocol for `ManagePlansViewController` navigation.
protocol ManagePlansNavigation: class {
    /// Close manage plans view.
    func closeManagePlans()
}

/// Manages flight plan managing view.
final class ManagePlansViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var closeButton: UIView!
    @IBOutlet private weak var currentProjectView: UIView!
    @IBOutlet private weak var openRecentView: UIView!
    @IBOutlet private weak var managePlansButton: FlightPlanManageBarView! {
        didSet {
            managePlansButton.isUserInteractionEnabled = false
        }
    }
    @IBOutlet private weak var projectName: UILabel! {
        didSet {
            projectName.makeUp()
            projectName.text = L10n.flightPlanProjectName
        }
    }
    @IBOutlet private weak var textfieldView: UIView! {
        didSet {
            textfieldView.backgroundColor = ColorName.white10.color
            textfieldView.cornerRadiusedWith(backgroundColor: ColorName.white10.color,
                                             borderColor: .clear,
                                             radius: Style.largeCornerRadius,
                                             borderWidth: Style.largeBorderWidth)
        }
    }
    @IBOutlet private weak var textfield: UITextField! {
        didSet {
            textfield.makeUp()
            textfield.backgroundColor = .clear
        }
    }
    @IBOutlet private weak var editImage: UIImageView! {
        didSet {
            editImage.tintColor = ColorName.greySilver.color
        }
    }
    @IBOutlet private weak var duplicateButton: UIButton! {
        didSet {
            duplicateButton.makeup(with: .regular, color: .white)
            duplicateButton.makeup(with: .regular, color: .white50, and: .disabled)
            duplicateButton.applyCornerRadius(Style.largeCornerRadius)
            duplicateButton.backgroundColor = ColorName.white20.color
            duplicateButton.setTitle(L10n.flightPlanDuplicate, for: .normal)
        }
    }
    @IBOutlet private weak var deleteButton: UIButton! {
        didSet {
            deleteButton.makeup(with: .regular, color: .white)
            deleteButton.applyCornerRadius(Style.largeCornerRadius)
            deleteButton.backgroundColor = ColorName.redTorch50.color
            deleteButton.tintColor = ColorName.white.color
            deleteButton.setTitle(nil, for: .normal)
            deleteButton.setImage(Asset.Common.Icons.iconTrashWhite.image, for: .normal)
        }
    }
    @IBOutlet private weak var newButton: UIButton! {
        didSet {
            newButton.makeup(with: .regular, color: .greenSpring)
            newButton.applyCornerRadius(Style.largeCornerRadius)
            newButton.backgroundColor = ColorName.greenSpring20.color
            newButton.setTitle(L10n.flightPlanNew, for: .normal)
        }
    }

    // MARK: - Private Properties
    private weak var coordinator: ManagePlansNavigation?
    private var flightPlanListener: FlightPlanListener?
    private var flightPlanViewModel: FlightPlanViewModel?
    private var flightPlansListViewController: FlightPlansListViewController?
    private var missionProviderViewModel: MissionProviderViewModel = MissionProviderViewModel()

    // MARK: - Private Enums
    private enum Constants {
        static let textFieldMaximumLength: Int = 50
    }

    /// Enum which stores messages to log.
    private enum EventLoggerConstants {
        static let screenMessage: String = "FlightPlan/ManageDialog"
    }

    // MARK: - Setup
    static func instantiate(coordinator: ManagePlansNavigation?) -> ManagePlansViewController {
        let viewController = StoryboardScene.ManagePlans.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Deinit
    deinit {
        FlightPlanManager.shared.unregister(flightPlanListener)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        closeButton.addBlurEffect()
        currentProjectView.addBlurEffect()
        openRecentView.addBlurEffect()

        // Allow dismiss view controller by tapping in the all top area.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeButtonTouchedUpInside))
        topView.addGestureRecognizer(tapGesture)
        topView.isUserInteractionEnabled = true

        textfield.delegate = self
        managePlansButton.setSelectedDisplay()
        flightPlanListener = FlightPlanManager.shared.register(didChange: { [weak self] flightPlan in
            self?.update(flightPlanViewModel: flightPlan)
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        logScreen(logMessage: EventLoggerConstants.screenMessage)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let destination = segue.destination as? FlightPlansListViewController {
            flightPlansListViewController = destination
            flightPlansListViewController?.displayMode = .compact
            flightPlansListViewController?.delegate = self
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension ManagePlansViewController {
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        coordinator?.closeManagePlans()
    }

    @IBAction func duplicateTouchUpInside(_ sender: Any) {
        FlightPlanManager.shared.duplicateCurrent()
    }

    @IBAction func deleteTouchUpInside(_ sender: Any) {
        // Delete current FP, then load latest opened one.
        FlightPlanManager.shared.deleteCurrent()
        FlightPlanManager.shared.loadLastOpenedFlightPlan(state: missionProviderViewModel.state.value)
    }

    @IBAction func newTouchUpInside(_ sender: Any) {
        // Create new FP then close current VC to directly start editing.
        guard let flightPlanProvider = missionProviderViewModel.state.value.mode?.flightPlanProvider else { return }

        FlightPlanManager.shared.new(flightPlanProvider: flightPlanProvider)
        coordinator?.closeManagePlans()
    }
}

// MARK: - FlightPlansListViewControllerDelegate
extension ManagePlansViewController: FlightPlansListViewControllerDelegate {
    func didSelect(flightPlan: FlightPlanViewModel) {
        FlightPlanManager.shared.currentFlightPlanViewModel = flightPlan
        coordinator?.closeManagePlans()
    }
}

// MARK: - Private Funcs
private extension ManagePlansViewController {
    func update(flightPlanViewModel: FlightPlanViewModel?) {
        self.flightPlanViewModel = flightPlanViewModel
        managePlansButton.flightPlanName = flightPlanViewModel?.state.value.title
        textfield.text = flightPlanViewModel?.state.value.title

        duplicateButton.isEnabled = flightPlanViewModel != nil
        deleteButton.isEnabled = flightPlanViewModel != nil
        textfield.isEnabled = flightPlanViewModel != nil

        flightPlansListViewController?.updateDataSource()
    }
}

// MARK: - UITextField Delegate
extension ManagePlansViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let name = textField.text, !name.isEmpty {
            flightPlanViewModel?.rename(name)
        }
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        if substringToReplace.count > string.count {
            // Always allow removing characters.
            return true
        } else {
            let count = textFieldText.count - substringToReplace.count + string.count
            return count <= Constants.textFieldMaximumLength
        }
    }
}