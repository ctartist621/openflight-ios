//    Copyright (C) 2020 Parrot Drones SAS
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
/// Delegate that notifiy touch state in the custom view.
protocol CustomTouchViewDelegate: AnyObject {
    /// Did touch listener on Custom touch view.
    ///
    /// - Parameters:
    ///     - point: current touch point
    func touchBegan(at point: CGPoint)

    /// Touch moved listener on Custom touch view.
    ///
    /// - Parameters:
    ///     - point: destination touch point
    func touchMoved(to point: CGPoint)

    /// End touch listener on Custom touch view.
    ///
    /// - Parameters:
    ///     - point: end touch point
    func touchEnded(at point: CGPoint)
}

/// Custom Touch view is just a wrapper to intercept the touch event on a UIView.

final class CustomTouchView: UIView {
    // MARK: - Internal Properties
    var longPressRecognizer: UILongPressGestureRecognizer!
    var isTouching: Bool = false
    /// Use to avoid some UIKit bugs that return the wrong center of UIView at runtime.
    var realCenter: CGPoint {
        return CGPoint(x: self.bounds.width / 2.0, y: self.bounds.height / 2.0)
    }
    weak var delegate: CustomTouchViewDelegate?

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitCustomTouchView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitCustomTouchView()
    }
}

// MARK: - Actions
private extension CustomTouchView {
    /// Intercept long press on the view.
    ///
    /// - Parameters:
    ///     - sender: current sender
    @objc func onLongPress(sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: self)
        switch sender.state {
        case .began:
            delegate?.touchBegan(at: point)
            isTouching = true
        case .changed:
            delegate?.touchMoved(to: point)
        case .ended,
             .cancelled,
             .failed:
            delegate?.touchEnded(at: point)
            isTouching = false
        default:
            break
        }
    }
}

// MARK: - Private Funcs
private extension CustomTouchView {
    func commonInitCustomTouchView() {
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        longPressRecognizer.minimumPressDuration = 0
        addGestureRecognizer(longPressRecognizer)
    }
}
