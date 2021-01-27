// Copyright (C) 2020 Parrot Drones SAS
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

// MARK: - Internal Enums
enum HUDCameraStreamingMode {
    case fullscreen
    case preview
}

// MARK: - Protocols
protocol HUDCameraStreamingViewControllerDelegate: class {
    /// Called when the stream content zone changes.
    func didUpdate(contentZone: CGRect?)
}

/// View controller that manages the different states and layers of the streaming.
final class HUDCameraStreamingViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var snowView: SnowView!
    @IBOutlet private weak var streamView: StreamView!

    // MARK: - Internal Properties
    weak var delegate: HUDCameraStreamingViewControllerDelegate?
    /// Current mode of the streaming view (most layers are removed for preview mode.
    var mode: HUDCameraStreamingMode = .fullscreen

    // MARK: - Private Properties
    private var contentZone: CGRect = .zero
    // Views.
    private var borderView: UIView?
    private var proposalAndTrackingView: ProposalAndTrackingView?
    // ViewModels.
    private var cameraStreamingViewModel: HUDCameraStreamingViewModel?
    private var missionLauncherViewModel: MissionLauncherViewModel?
    private var trackingViewModel: TrackingViewModel? {
        didSet {
            guard self.trackingViewModel == nil else { return }
            self.clearTrackingAndProposalsView()
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let streamMiniatureBorderWidth: CGFloat = 2.0
        static let streamMiniatureBorderColor: UIColor = .white
    }

    // MARK: - Setup
    static func instantiate() -> HUDCameraStreamingViewController {
        return StoryboardScene.HUDCameraStreaming.initialScene.instantiate()
    }

    // MARK: - Deinit
    deinit {
        deinitStream()
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        if !Platform.isSimulator {
            self.setupViewModels()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.snowView.isHidden = false
        self.enableMonitoring(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateContentZone(to: streamView.contentZone)
        streamView.contentZoneListener = { [weak self] contentZone in
            self?.updateContentZone(to: contentZone)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.enableMonitoring(false)
        self.streamView.contentZoneListener = nil
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Internal Funcs
extension HUDCameraStreamingViewController {

    /// Add a border to the stream view.
    func addBorder() {
        borderView?.removeFromSuperview()
        let borderView = UIView(frame: view.frame)
        borderView.setBorder(borderColor: Constants.streamMiniatureBorderColor,
                             borderWidth: Constants.streamMiniatureBorderWidth)
        view.addSubview(borderView)
        self.borderView = borderView
    }

    /// Removes the border of the stream view.
    func removeBorder() {
        borderView?.removeFromSuperview()
        borderView = nil
    }

    /// Stops the stream (⚠️ only works after viewDidAppear).
    func stopStream() {
        self.enableMonitoring(false)
    }

    /// Restarts previously stopped stream.
    func restartStream() {
        self.enableMonitoring(true)
    }
}

// MARK: - Private Funcs
private extension HUDCameraStreamingViewController {

    /// Sets up view models associated with the view.
    func setupViewModels() {
        self.cameraStreamingViewModel = HUDCameraStreamingViewModel(stateDidUpdate: onStateUpdate,
                                                                    cameraLiveDidUpdate: onCameraLiveUpdate)

        self.missionLauncherViewModel = MissionLauncherViewModel(stateDidUpdate: { [weak self] state in
            if state.mode?.isTrackingMode == true {
                guard self?.trackingViewModel == nil else { return }
                self?.setupTrackingViewModel()
            } else {
                self?.clearTracking()
            }
        })
    }

    /// Sets up tracking view model.
    func setupTrackingViewModel() {
        self.trackingViewModel = TrackingViewModel()
        self.trackingViewModel?.enableMonitoring(true)
        self.proposalAndTrackingView = ProposalAndTrackingView(frame: CGRect.zero,
                                                               delegate: self)
        self.view.addSubview(self.proposalAndTrackingView)
        self.trackingViewModel?.state.valueChanged = { [weak self] state in
            if let currentTilt = state.tilt {
                self?.proposalAndTrackingView?.updateTilt(currentTilt)
            }

            if let trackingInfo = state.trackingInfo {
                self?.proposalAndTrackingView?.trackInfoDidChange(trackingInfo)
            }
        }
    }

    /// Enable or disable monitoring for all view models.
    ///
    /// - Parameters:
    ///    - enabled: boolean that enable or disable monitoring.
    func enableMonitoring(_ enabled: Bool) {
        self.cameraStreamingViewModel?.enableMonitoring(enabled)
        self.trackingViewModel?.enableMonitoring(enabled)
    }

    /// Called when streaming state is updated.
    ///
    /// - Parameters:
    ///    - state: state from HUDCameraStreamingViewModel.
    func onStateUpdate(_ state: HUDCameraStreamingState) {
        snowView.isHidden = state.streamEnabled

        if !state.streamEnabled {
            self.clearTracking()
        } else if self.missionLauncherViewModel?.state.value.mode?.isTrackingMode == true,
            self.trackingViewModel == nil {
            self.setupTrackingViewModel()
            self.proposalAndTrackingView?.updateFrame(self.contentZone)
        }
        updateOverexposure()
    }

    /// Called when camera live is updated.
    ///
    /// - Parameters:
    ///    - cameraLive: camera live from drone.
    func onCameraLiveUpdate(_ cameraLive: CameraLive?) {
        streamView.setStream(stream: cameraLive)
    }

    /// Updates the visibility of overexposure areas.
    func updateOverexposure() {
        guard let overexposureSetting = cameraStreamingViewModel?.state.value.overexposureSetting else {
            return
        }
        streamView.zebrasEnabled = overexposureSetting.boolValue
    }

    /// Updates the content zone of the stream.
    ///
    /// - Parameters:
    ///    - zone: new size to update.
    func updateContentZone(to zone: CGRect) {
        guard let scale = view.window?.screen.nativeScale else {
            return
        }

        let frame = zone.reduce(by: scale)

        self.delegate?.didUpdate(contentZone: frame)
        self.proposalAndTrackingView?.updateFrame(frame)
        self.contentZone = frame
    }

    /// Removes all traces from tracking functionnality.
    func clearTracking() {
        self.trackingViewModel?.enableMonitoring(false)
        self.trackingViewModel = nil
    }

    /// Removes tracking and proposals view.
    func clearTrackingAndProposalsView() {
        self.proposalAndTrackingView?.clearTrackingAndProposals(clearDrawView: true)
        self.proposalAndTrackingView?.removeFromSuperview()
        self.proposalAndTrackingView = nil
    }

    /// Deinit stream.
    func deinitStream() {
        streamView.setStream(stream: nil)
    }
}

// MARK: - ProposalAndTracking Delegate
extension HUDCameraStreamingViewController: ProposalAndTrackingDelegate {
    func didDrawSelection(_ frame: CGRect) {
        guard let strongProposalAndTrackingView = self.proposalAndTrackingView else {
            return
        }

        let frameSelected = CGRect(x: CGFloat(frame.minX / strongProposalAndTrackingView.frame.width),
                                   y: CGFloat(frame.minY / strongProposalAndTrackingView.frame.height),
                                   width: CGFloat(frame.width / strongProposalAndTrackingView.frame.width),
                                   height: CGFloat(frame.height / strongProposalAndTrackingView.frame.height))

        self.trackingViewModel?.sendSelectionToDrone(frame: frameSelected)
    }

    func didSelect(proposalId: UInt) {
        self.trackingViewModel?.sendProposalToDrone(proposalId: proposalId)
    }

    func didDeselectTarget() {
        self.trackingViewModel?.removeAllTargets()
    }
}