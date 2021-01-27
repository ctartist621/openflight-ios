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
import GroundSdk

/// View Controller used to format SD card.

final class GalleryFormatSDCardViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var backgroundButton: UIButton!
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var primaryLabel: UILabel!
    @IBOutlet private weak var secondaryLabel: UILabel!
    @IBOutlet private weak var choicesStackView: UIStackView!
    @IBOutlet private weak var quickFormatChoiceView: GalleryFormatSDCardChoiceView!
    @IBOutlet private weak var fullFormatChoiceView: GalleryFormatSDCardChoiceView!
    @IBOutlet private weak var formattingView: UIView!
    @IBOutlet private weak var formattingImageView: UIImageView!
    @IBOutlet private weak var circleProgressView: CircleProgressView!
    @IBOutlet private weak var firstStepView: GalleryFormatSDCardStepView!
    @IBOutlet private weak var secondStepView: GalleryFormatSDCardStepView!
    @IBOutlet private weak var thirdStepView: GalleryFormatSDCardStepView!

    // MARK: - Private Properties
    private weak var coordinator: GalleryCoordinator?
    private var viewModel: GalleryFormatSDCardViewModel?

    // MARK: - Private Enums
    private enum Constants {
        static let toastDuration: Double = 3.0
    }

    // MARK: - Setup
    /// Instantiate view controller.
    ///
    /// - Parameters:
    ///     - coordinator: gallery coordinator
    ///     - viewModel: gallery view model
    /// - Returns: a GalleryFormatSDCardViewController.
    static func instantiate(coordinator: GalleryCoordinator, viewModel: GalleryMediaViewModel) -> GalleryFormatSDCardViewController {
        let viewController = StoryboardScene.GalleryFormatSDCard.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = GalleryFormatSDCardViewModel(galleryViewModel: viewModel)

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupChoicesModels()
        setupViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: Style.mediumAnimationDuration) {
            self.view.backgroundColor = ColorName.greyDark60.color
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension GalleryFormatSDCardViewController {
    /// Function called when a choice view is clicked.
    @IBAction func choiceViewTouchedUpInside(_ view: GalleryFormatSDCardChoiceView) {
        startFormatting(view == quickFormatChoiceView ? .quick : .full)
    }

    /// Function called when the back button is clicked.
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        dismissView()
    }

    /// Function called when the background button is clicked.
    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        dismissView()
    }
}

// MARK: - Private Funcs
private extension GalleryFormatSDCardViewController {
    /// Sets up all the UI for the view controller.
    func setupUI() {
        self.primaryLabel.makeUp(with: .huge)
        self.primaryLabel.text = L10n.galleryFormatSdCard
        self.secondaryLabel.makeUp(with: .large, and: ColorName.orangePeel)
        self.secondaryLabel.text = L10n.galleryFormatDataErased
        self.mainView.addBlurEffect()
        self.mainView.applyCornerRadius(Style.largeCornerRadius, maskedCorners: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        self.circleProgressView.strokeColor = ColorName.greenSpring.color
    }

    /// Sets up models associated with the choices view.
    func setupChoicesModels() {
        self.quickFormatChoiceView.model = GalleryFormatSDCardChoiceModel(image: Asset.Common.Icons.icSdCardFormatQuick.image,
                                                                          text: L10n.galleryFormatQuick,
                                                                          textColor: ColorName.white,
                                                                          subText: L10n.galleryFormatRecommended,
                                                                          subTextColor: ColorName.greenSpring)
        self.fullFormatChoiceView.model = GalleryFormatSDCardChoiceModel(image: Asset.Common.Icons.icSdCardFormatFull.image,
                                                                         text: L10n.galleryFormatFull,
                                                                         textColor: ColorName.white,
                                                                         subText: L10n.galleryFormatWritingProblems,
                                                                         subTextColor: ColorName.white50)
        self.firstStepView.model = GalleryFormatSDCardStepModel(image: Asset.Gallery.Format.icErasing.image,
                                                                text: L10n.galleryFormatErasingPartition,
                                                                textColor: ColorName.white50)
        self.secondStepView.model = GalleryFormatSDCardStepModel(image: Asset.Gallery.Format.icReset.image,
                                                                 text: L10n.galleryFormatResetting,
                                                                 textColor: ColorName.white50)
        self.thirdStepView.model = GalleryFormatSDCardStepModel(image: Asset.Gallery.Format.icCreate.image,
                                                                text: L10n.galleryFormatCreatingPartition,
                                                                textColor: ColorName.white50)
    }

    /// Sets up main view model.
    func setupViewModel() {
        viewModel?.startListeningToFormattingProgress({ step, progress, formattingState in
            switch step {
            case .partitioning:
                self.firstStepView.model = GalleryFormatSDCardStepModel(image: Asset.Gallery.Format.icErasingHighlighted.image,
                                                                        text: L10n.galleryFormatErasingPartition,
                                                                        textColor: ColorName.greenSpring)
            case .clearingData:
                self.secondStepView.model = GalleryFormatSDCardStepModel(image: Asset.Gallery.Format.icResetHighlighted.image,
                                                                         text: L10n.galleryFormatResetting,
                                                                         textColor: ColorName.greenSpring)
            case .creatingFs:
                self.thirdStepView.model = GalleryFormatSDCardStepModel(image: Asset.Gallery.Format.icCreateHighlighted.image,
                                                                        text: L10n.galleryFormatCreatingPartition,
                                                                        textColor: ColorName.greenSpring)
            }
            self.circleProgressView.setProgress(progress)
            if formattingState == .done {
                self.dismissView(showToast: true)
            }
        })
    }

    /// Called when the formatting needs to start.
    ///
    /// - Parameters:
    ///    - type: formatting type
    func startFormatting(_ type: FormattingType) {
        guard let viewModel = viewModel,
            viewModel.canFormat else {
                return
        }

        choicesStackView.isHidden = true
        formattingView.isHidden = false
        viewModel.selectedFormattingType = type
        formattingImageView.image = type == .quick ? Asset.Common.Icons.icSdCardFormatQuick.image : Asset.Common.Icons.icSdCardFormatFull.image
        self.primaryLabel.text = L10n.galleryFormatFormatting
        self.secondaryLabel.text = nil
        viewModel.format()
    }

    /// Called when the view needs to be dismissed.
    ///
    /// - Parameters:
    ///     - showToast: boolean to determine if we need to show the formatting toast message
    ///     - duration: display duration
    func dismissView(showToast: Bool = false, duration: Double = Style.longAnimationDuration) {
        viewModel?.stopListeningToFormattingProgress()
        self.view.backgroundColor = .clear
        self.coordinator?.dismissFormatSDCardScreen(showToast: showToast, duration: duration)
    }
}