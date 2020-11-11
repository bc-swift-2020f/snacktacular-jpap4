//
//  UIBarButtonItem+hide.swift
//  Snacktacular
//
//  Created by John Pappas on 11/11/20.
//  Copyright © 2020 John Pappas. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    func hide() {
        self.isEnabled = false
        self.tintColor = .clear
    }
}
