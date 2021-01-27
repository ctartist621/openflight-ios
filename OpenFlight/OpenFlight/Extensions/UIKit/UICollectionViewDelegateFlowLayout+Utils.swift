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

// MARK: - UICollectionViewFlowLayout
/// Utility method for flow layout in collection view.
extension UICollectionViewFlowLayout {
    /// Get width of the cell dynamicaly.
    ///
    /// - Parameters:
    ///     - cellsPerRow: targeted cell number per row
    ///     - width: collection view width
    func getDynamicCellWidth(cellsPerRow: Int, width: CGFloat) -> CGFloat {
        let horizontalMarginAndInsets = self.sectionInset.left
            + self.sectionInset.right
            + self.minimumInteritemSpacing * CGFloat(cellsPerRow - 1)
        return ((width - horizontalMarginAndInsets) / CGFloat(cellsPerRow)).rounded(.down)
    }

    /// Get height of the cell dynamicaly.
    ///
    /// - Parameters:
    ///     - cellsPerRow: targeted cell number per row
    ///     - height: collection view height
    ///     - count: items number
    func getDynamicCellHeight(cellsPerRow: Int, height: CGFloat, count: Int) -> CGFloat {
        let verticalMarginAndInsets = self.sectionInset.top
            + self.sectionInset.bottom
            + self.minimumLineSpacing * CGFloat(count / cellsPerRow - 1)
        return ((height - verticalMarginAndInsets) / CGFloat(count / cellsPerRow)).rounded(.down)
    }
}
